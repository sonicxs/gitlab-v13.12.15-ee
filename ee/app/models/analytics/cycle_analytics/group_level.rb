# frozen_string_literal: true

module Analytics
  module CycleAnalytics
    class GroupLevel
      attr_reader :options, :group

      def initialize(group:, options:)
        @group = group
        @options = options.merge(group: group)
      end

      def summary
        @summary ||=
          Gitlab::Analytics::CycleAnalytics::Summary::Group::StageSummary
          .new(group, options: options)
          .data
      end

      def time_summary
        @time_summary ||=
          Gitlab::Analytics::CycleAnalytics::Summary::Group::StageTimeSummary
          .new(group, options: options)
          .data
      end
    end
  end
end
