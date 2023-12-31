# frozen_string_literal: true

module Vulnerabilities
  class Findings
    class Evidence < ApplicationRecord
      self.table_name = 'vulnerability_finding_evidences'

      belongs_to :finding, class_name: 'Vulnerabilities::Finding', inverse_of: :evidence, foreign_key: 'vulnerability_occurrence_id', optional: false

      has_one :request, class_name: 'Vulnerabilities::Findings::Evidences::Request', inverse_of: :evidence, foreign_key: 'vulnerability_finding_evidence_id'
      has_one :response, class_name: 'Vulnerabilities::Findings::Evidences::Response', inverse_of: :evidence, foreign_key: 'vulnerability_finding_evidence_id'

      validates :summary, length: { maximum: 8_000_000 }
    end
  end
end
