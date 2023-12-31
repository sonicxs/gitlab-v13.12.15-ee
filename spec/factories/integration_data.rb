# frozen_string_literal: true

# These factories should not be called directly unless we are testing a _tracker_data model.
# The factories are used when creating integrations.
FactoryBot.define do
  factory :jira_tracker_data do
    integration factory: :jira_service
  end

  factory :issue_tracker_data do
    integration
  end

  factory :open_project_tracker_data do
    integration factory: :open_project_service
    url { 'http://openproject.example.com'}
    token { 'supersecret' }
    project_identifier_code { 'PRJ-1' }
    closed_status_id { '15' }
  end
end
