# frozen_string_literal: true

module Ci
  module Minutes
    class TrackLiveConsumptionService
      TTL_RUNNING_BUILDS = 5.minutes

      # We allow remaining minutes to drop below this number to avoid dropping
      # builds immediately when the quota is exceeded
      CONSUMPTION_THRESHOLD = -1000

      def initialize(build)
        @build = build
      end

      def execute
        result = validate_preconditions
        return result if result.error?

        consumption = consumption_since_last_update
        return ServiceResponse.success(message: 'Build consumption is zero') if consumption == 0 # first build update

        accumulate_total_build_consumption(consumption)

        new_balance = cached_quota.track_consumption(consumption)

        if new_balance < CONSUMPTION_THRESHOLD
          build.drop(:ci_quota_exceeded)
          metrics.ci_minutes_exceeded_builds_counter.increment

          ::Gitlab::AppLogger.info(
            message: 'Build dropped due to CI minutes limit exceeded',
            namespace: root_namespace.name,
            project_path: build.project.full_path,
            build_id: build.id,
            user_id: build.user_id,
            username: build.user&.username)

          ServiceResponse.success(message: 'Build dropped due to CI minutes limit exceeded', payload: { current_balance: new_balance })
        else
          ServiceResponse.success(message: 'CI minutes limit not exceeded', payload: { current_balance: new_balance })
        end
      end

      def live_consumption
        ::Gitlab::Redis::SharedState.with do |redis|
          redis.get(consumption_key).to_f
        end
      end

      def time_last_tracked_consumption!(new_time)
        old_time = nil

        ::Gitlab::Redis::SharedState.with do |redis|
          redis.multi do
            key = last_build_update_key

            old_time = redis.get(key)
            redis.set(key, new_time)
            redis.expire(key, TTL_RUNNING_BUILDS)
          end
        end

        if old_time&.value
          DateTime.parse(old_time.value)
        else
          new_time
        end
      end

      private

      attr_reader :build

      def validate_preconditions
        if !feature_enabled?
          ServiceResponse.error(message: 'Feature not enabled')
        elsif !build.running?
          ServiceResponse.error(message: 'Build is not running')
        elsif !free_or_trial_plan?
          ServiceResponse.error(message: 'Project is not on Free or trial plan')
        elsif !build.shared_runners_minutes_limit_enabled?
          ServiceResponse.error(message: 'CI minutes limit not enabled for build')
        else
          ServiceResponse.success
        end
      end

      def feature_enabled?
        Feature.enabled?(:ci_minutes_track_live_consumption, build.project, default_enabled: :yaml)
      end

      def free_or_trial_plan?
        Gitlab.com? && (root_namespace.free_plan? || root_namespace.trial?)
      end

      def consumption_since_last_update
        last_tracking = time_last_tracked_consumption!(Time.current.utc)
        duration = Time.current.utc - last_tracking
        ::Gitlab::Ci::Minutes::BuildConsumption.new(build, duration).amount
      end

      def last_build_update_key
        "ci:minutes:builds:#{build.id}:last_update"
      end

      def accumulate_total_build_consumption(consumption)
        ::Gitlab::Redis::SharedState.with do |redis|
          redis.multi do |multi|
            multi.incrbyfloat(consumption_key, consumption)
            multi.expire(consumption_key, TTL_RUNNING_BUILDS)
          end
        end
      end

      def consumption_key
        "ci:minutes:builds:#{build.id}:consumption"
      end

      def cached_quota
        @cached_quota ||= Gitlab::Ci::Minutes::CachedQuota.new(root_namespace)
      end

      def root_namespace
        @root_namespace ||= build.project.root_namespace
      end

      def metrics
        @metrics ||= ::Gitlab::Ci::Pipeline::Metrics.new
      end
    end
  end
end
