# frozen_string_literal: true

module Mutations
  module JiraImport
    class ImportUsers < BaseMutation
      include FindsProject

      graphql_name 'JiraImportUsers'

      authorize :admin_project

      field :jira_users,
            [Types::JiraUserType],
            null: true,
            description: 'Users returned from Jira, matched by email and name if possible.'

      argument :project_path, GraphQL::ID_TYPE,
               required: true,
               description: 'The project to import the Jira users into.'
      argument :start_at, GraphQL::INT_TYPE,
               required: false,
               description: 'The index of the record the import should started at, default 0 (50 records returned).'

      def resolve(project_path:, start_at: 0)
        project = authorized_find!(project_path)

        service_response = ::JiraImport::UsersImporter.new(context[:current_user], project, start_at.to_i).execute

        {
          jira_users: service_response.payload,
          errors: service_response.errors
        }
      end
    end
  end
end
