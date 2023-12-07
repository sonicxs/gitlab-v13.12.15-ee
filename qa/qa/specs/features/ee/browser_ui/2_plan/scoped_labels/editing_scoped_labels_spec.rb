# frozen_string_literal: true

module QA
  RSpec.describe 'Plan', :reliable do
    describe 'Editing scoped labels on issues' do
      let(:initial_label) { 'animal::fox' }
      let(:new_label_same_scope) { 'animal::dolphin' }
      let(:new_label_different_scope) { 'plant::orchid' }

      let(:initial_label_multi_colon) { 'group::car::ferrari' }
      let(:new_label_same_scope_multi_colon) { 'group::car::porsche' }
      let(:new_label_different_scope_multi_colon) { 'group::truck::mercedes-bens' }

      before do
        Flow::Login.sign_in

        issue = Resource::Issue.fabricate_via_api! do |issue|
          issue.labels = [initial_label, initial_label_multi_colon]
        end

        [
          new_label_same_scope,
          new_label_different_scope,
          new_label_same_scope_multi_colon,
          new_label_different_scope_multi_colon
        ].each do |label|
          Resource::Label.fabricate_via_api! do |l|
            l.project = issue.project
            l.title = label
          end
        end

        issue.visit!
      end

      it 'correctly applies simple and multiple colon scoped pairs labels', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1171' do
        Page::Project::Issue::Show.perform do |show|
          show.select_labels_and_refresh([
            new_label_same_scope,
            new_label_different_scope,
            new_label_same_scope_multi_colon,
            new_label_different_scope_multi_colon
          ])

          aggregate_failures do
            expect(show).to have_label(new_label_same_scope)
            expect(show).to have_label(new_label_different_scope)
            expect(show).to have_label(new_label_same_scope_multi_colon)
            expect(show).to have_label(new_label_different_scope_multi_colon)

            expect(show).not_to have_label(initial_label)
            expect(show).not_to have_label(initial_label_multi_colon)
          end
        end
      end
    end
  end
end
