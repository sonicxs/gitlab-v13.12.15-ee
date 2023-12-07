# frozen_string_literal: true

module EE
  module BulkImports
    module Stage
      extend ::Gitlab::Utils::Override

      EE_CONFIG = {
        iterations: {
          pipeline: ::BulkImports::Groups::Pipelines::IterationsPipeline,
          stage: 1
        },
        epics: {
          pipeline: ::BulkImports::Groups::Pipelines::EpicsPipeline,
          stage: 2
        },
        epic_award_emojis: {
          pipeline: ::BulkImports::Groups::Pipelines::EpicAwardEmojiPipeline,
          stage: 3
        },
        epic_events: {
          pipeline: ::BulkImports::Groups::Pipelines::EpicEventsPipeline,
          stage: 3
        },
        # Override the CE stage value for the EntityFinisher Pipeline
        finisher: {
          stage: 4
        }
      }.freeze

      private

      override :config
      def config
        @config ||= super.deep_merge(EE_CONFIG)
      end
    end
  end
end
