# frozen_string_literal: true

module EE
  module Ci
    module Runner
      extend ActiveSupport::Concern

      def tick_runner_queue
        ##
        # We only stick a runner to primary database to be able to detect the
        # replication lag in `EE::Ci::RegisterJobService#execute`. The
        # intention here is not to execute `Ci::RegisterJobService#execute` on
        # the primary database.
        #
        ::Gitlab::Database::LoadBalancing::Sticking.stick(:runner, id)

        super
      end

      def heartbeat(values)
        return super unless ::Feature.enabled?(:ci_runner_builds_queue_on_replicas, self, default_enabled: :yaml)

        ##
        # We can safely ignore writes performed by a runner heartbeat. We do
        # not want to upgrade database connection proxy to use the primary
        # database after heartbeat write happens.
        #
        ::Gitlab::Database::LoadBalancing::Session.without_sticky_writes { super }
      end

      def minutes_cost_factor(access_level)
        return 0.0 unless instance_type?

        case access_level
        when ::Gitlab::VisibilityLevel::PUBLIC
          public_projects_minutes_cost_factor
        when ::Gitlab::VisibilityLevel::PRIVATE, ::Gitlab::VisibilityLevel::INTERNAL
          private_projects_minutes_cost_factor
        else
          raise ArgumentError, 'Invalid visibility level'
        end
      end

      def visibility_levels_without_minutes_quota
        ::Gitlab::VisibilityLevel.options.values.reject do |visibility_level|
          minutes_cost_factor(visibility_level) > 0
        end
      end

      class_methods do
        def has_shared_runners_with_non_zero_public_cost?
          ::Ci::Runner.instance_type.where('public_projects_minutes_cost_factor > 0').exists?
        end
      end
    end
  end
end
