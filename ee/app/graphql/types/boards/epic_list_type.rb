# frozen_string_literal: true

module Types
  module Boards
    # rubocop: disable Graphql/AuthorizeTypes
    class EpicListType < BaseObject
      include Gitlab::Utils::StrongMemoize

      graphql_name 'EpicList'
      description 'Represents an epic board list'

      accepts ::Boards::EpicList

      alias_method :list, :object

      field :id, type: ::Types::GlobalIDType[::Boards::EpicList], null: false,
            description: 'Global ID of the board list.'

      field :title, GraphQL::STRING_TYPE, null: false,
            description: 'Title of the list.'

      field :list_type, GraphQL::STRING_TYPE, null: false,
            description: 'Type of the list.'

      field :position, GraphQL::INT_TYPE, null: true,
            description: 'Position of the list within the board.'

      field :label, Types::LabelType, null: true,
            description: 'Label of the list.'

      field :collapsed, GraphQL::BOOLEAN_TYPE, null: true,
            description: 'Indicates if this list is collapsed for this user.'

      field :epics, Types::EpicType.connection_type, null: true,
            resolver: Resolvers::Boards::BoardListEpicsResolver,
            description: 'List epics.'

      field :epics_count, GraphQL::INT_TYPE, null: true,
            description: 'Count of epics in the list.'

      def collapsed
        object.collapsed?(current_user)
      end

      def epics_count
        metadata[:size]
      end

      def metadata
        strong_memoize(:metadata) do
          ::Boards::Epics::ListService
              .new(list.epic_board.resource_parent, current_user, { board_id: list.epic_board_id, id: list.id })
              .metadata
        end
      end
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
