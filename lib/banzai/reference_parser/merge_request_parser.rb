# frozen_string_literal: true

module Banzai
  module ReferenceParser
    class MergeRequestParser < IssuableParser
      include Gitlab::Utils::StrongMemoize

      self.reference_type = :merge_request

      def records_for_nodes(nodes)
        @merge_requests_for_nodes ||= grouped_objects_for_nodes(
          nodes,
          MergeRequest.includes(
            :author,
            :assignees,
            {
              # These associations are primarily used for checking permissions.
              # Eager loading these ensures we don't end up running dozens of
              # queries in this process.
              target_project: [
                { namespace: [:owner, :route] },
                { group: [:owners, :group_members] },
                :invited_groups,
                :project_members,
                :project_feature,
                :route
              ]
            }),
          self.class.data_attribute
        )
      end

      def can_read_reference?(user, merge_request)
        memo = strong_memoize(:can_read_reference) { {} }

        project_id = merge_request.project_id

        return memo[project_id] if memo.key?(project_id)

        memo[project_id] = can?(user, :read_merge_request_iid, merge_request.project)
      end
    end
  end
end
