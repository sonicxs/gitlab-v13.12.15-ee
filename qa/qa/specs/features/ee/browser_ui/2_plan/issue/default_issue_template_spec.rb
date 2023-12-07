# frozen_string_literal: true

module QA
  RSpec.describe 'Plan' do
    describe 'Default issue templates' do
      let(:default_template_project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = "default-issue-template-project"
        end
      end

      let(:template) { 'This is a default issue template' }

      before do
        Flow::Login.sign_in
      end

      it 'uses default template when creating an issue', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1231' do
        default_template_project.visit!

        Page::Project::Menu.perform(&:go_to_general_settings)
        Page::Project::Settings::Main.perform(&:expand_default_description_template_for_issues)
        EE::Page::Project::Settings::IssueTemplateDefault.perform do |issue_settings|
          issue_settings.set_default_issue_template(template)
        end

        Resource::Issue.fabricate_via_api! do |issue|
          issue.project = default_template_project
        end.visit!

        expect(page).to have_content(template)
      end
    end
  end
end
