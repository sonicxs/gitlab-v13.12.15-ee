# frozen_string_literal: true

module Types
  module Ci
    # rubocop: disable Graphql/AuthorizeTypes
    # This type is only accessible from CiJob
    class BuildNeedType < BaseObject
      graphql_name 'CiBuildNeed'

      field :name, GraphQL::STRING_TYPE, null: true,
            description: 'Name of the job we need to complete.'
    end
  end
end
