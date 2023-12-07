# frozen_string_literal: true

module EE
  module Types
    module Ci
      module PipelineType
        extend ActiveSupport::Concern

        prepended do
          field :security_report_summary,
            ::Types::SecurityReportSummaryType,
            null: true,
            extras: [:lookahead],
            description: 'Vulnerability and scanned resource counts for each security scanner of the pipeline.',
            resolver: ::Resolvers::SecurityReportSummaryResolver

          field :security_report_findings,
            ::Types::PipelineSecurityReportFindingType.connection_type,
            null: true,
            description: 'Vulnerability findings reported on the pipeline.',
            resolver: ::Resolvers::PipelineSecurityReportFindingsResolver

          field :code_quality_reports,
            ::Types::Ci::CodeQualityDegradationType.connection_type,
            null: true,
            description: 'Code Quality degradations reported on the pipeline.'

          def code_quality_reports
            pipeline.codequality_reports.all_degradations.presence
          end
        end
      end
    end
  end
end
