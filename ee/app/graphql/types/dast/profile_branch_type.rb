# frozen_string_literal: true

module Types
  module Dast
    class ProfileBranchType < BaseObject
      graphql_name 'DastProfileBranch'
      description 'Represents a DAST Profile Branch'

      authorize :read_on_demand_scans

      field :name, GraphQL::STRING_TYPE, null: true,
            description: 'The name of the branch.',
            calls_gitaly: true

      field :exists, GraphQL::BOOLEAN_TYPE, null: true,
            description: 'Indicates whether or not the branch exists.',
            calls_gitaly: true
    end
  end
end
