# frozen_string_literal: true

module Types
  module Clusters
    class AgentType < BaseObject
      graphql_name 'ClusterAgent'

      authorize :admin_cluster

      connection_type_class(Types::CountableConnectionType)

      field :created_at,
            Types::TimeType,
            null: true,
            description: 'Timestamp the cluster agent was created.'

      field :created_by_user,
            Types::UserType,
            null: true,
            description: 'User object, containing information about the person who created the agent.'

      field :id, GraphQL::ID_TYPE,
            null: false,
            description: 'ID of the cluster agent.'

      field :name,
            GraphQL::STRING_TYPE,
            null: true,
            description: 'Name of the cluster agent.'

      field :project, Types::ProjectType,
            description: 'The project this cluster agent is associated with.',
            null: true,
            authorize: :read_project

      field :tokens, Types::Clusters::AgentTokenType.connection_type,
            description: 'Tokens associated with the cluster agent.',
            null: true,
            resolver: ::Resolvers::Clusters::AgentTokensResolver

      field :updated_at,
            Types::TimeType,
            null: true,
            description: 'Timestamp the cluster agent was updated.'

      field :web_path,
            GraphQL::STRING_TYPE,
            null: true,
            description: 'Web path of the cluster agent.'

      def project
        Gitlab::Graphql::Loaders::BatchModelLoader.new(Project, object.project_id).find
      end

      def web_path
        ::Gitlab::Routing.url_helpers.project_cluster_agent_path(object.project, object.name)
      end
    end
  end
end
