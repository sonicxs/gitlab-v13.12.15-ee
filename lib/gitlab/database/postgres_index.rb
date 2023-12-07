# frozen_string_literal: true

module Gitlab
  module Database
    class PostgresIndex < ActiveRecord::Base
      include Gitlab::Utils::StrongMemoize

      self.table_name = 'postgres_indexes'
      self.primary_key = 'identifier'

      has_one :bloat_estimate, class_name: 'Gitlab::Database::PostgresIndexBloatEstimate', foreign_key: :identifier
      has_many :reindexing_actions, class_name: 'Gitlab::Database::Reindexing::ReindexAction', foreign_key: :index_identifier

      scope :by_identifier, ->(identifier) do
        raise ArgumentError, "Index name is not fully qualified with a schema: #{identifier}" unless identifier =~ /^\w+\.\w+$/

        find(identifier)
      end

      # A 'regular' index is a non-unique index,
      # that does not serve an exclusion constraint and
      # is defined on a table that is not partitioned.
      scope :regular, -> { where(unique: false, partitioned: false, exclusion: false)}

      scope :not_match, ->(regex) { where("name !~ ?", regex)}

      scope :not_recently_reindexed, -> do
        recent_actions = Reindexing::ReindexAction.recent.where('index_identifier = identifier')

        where('NOT EXISTS (?)', recent_actions)
      end

      def bloat_size
        strong_memoize(:bloat_size) { bloat_estimate&.bloat_size || 0 }
      end

      def to_s
        name
      end
    end
  end
end
