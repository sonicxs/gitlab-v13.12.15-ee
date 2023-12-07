# frozen_string_literal: true

module MergeRequests
  class StatusCheckResponse < ApplicationRecord
    self.table_name = 'status_check_responses'

    belongs_to :merge_request
    belongs_to :external_approval_rule, class_name: 'ApprovalRules::ExternalApprovalRule'

    validates :merge_request, presence: true
    validates :external_approval_rule, presence: true
  end
end
