# frozen_string_literal: true
class ProtectedEnvironment < ApplicationRecord
  include ::Gitlab::Utils::StrongMemoize

  belongs_to :project
  has_many :deploy_access_levels, inverse_of: :protected_environment

  accepts_nested_attributes_for :deploy_access_levels, allow_destroy: true

  validates :deploy_access_levels, length: { minimum: 1 }
  validates :name, :project, presence: true

  scope :sorted_by_name, -> { order(:name) }

  scope :with_environment_id, -> do
    select('protected_environments.*, environments.id AS environment_id')
      .joins('LEFT OUTER JOIN environments ON' \
             ' protected_environments.name = environments.name ' \
             ' AND protected_environments.project_id = environments.project_id')
  end

  class << self
    def deploy_access_levels_by_user(user)
      ProtectedEnvironment::DeployAccessLevel
        .where(protected_environment_id: select(:id))
        .where(user: user)
    end

    def deploy_access_levels_by_group(group)
      ProtectedEnvironment::DeployAccessLevel
        .where(protected_environment_id: select(:id))
        .where(group: group)
    end

    def for_environment(environment)
      raise ArgumentError unless environment.is_a?(::Environment)

      key = "protected_environment:for_environment:#{environment.project_id}:#{environment.name}"

      ::Gitlab::SafeRequestStore.fetch(key) do
        where(project: environment.project_id, name: environment.name)
      end
    end
  end

  def accessible_to?(user)
    deploy_access_levels
      .any? { |deploy_access_level| deploy_access_level.check_access(user) }
  end
end
