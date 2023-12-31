# frozen_string_literal: true

require "spec_helper"

RSpec.describe "User creates issue", :js do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, :public) }
  let_it_be(:project) { create(:project_empty_repo, :public, namespace: group) }
  let_it_be(:epic) { create(:epic, group: group, title: 'Sample epic', author: user) }

  let(:issue_title) { '500 error on profile' }

  before_all do
    group.add_developer(user)
  end

  before do
    stub_licensed_features(issue_weights: true)
    stub_licensed_features(epics: true)

    sign_in(user)

    visit(new_project_issue_path(project))
  end

  context "with weight set" do
    it "creates issue" do
      weight = "7"

      fill_in("Title", with: issue_title)
      fill_in("issue_weight", with: weight)

      click_button 'Create issue'

      page.within(".weight") do
        expect(page).to have_content(weight)
      end

      expect(page).to have_content(issue_title)
    end
  end

  context 'with epics' do
    before do
      fill_in("Title", with: issue_title)
      scroll_to(page.find('.epic-dropdown-container', visible: false))
    end

    it 'creates an issue with no epic' do
      click_button 'Select epic'
      find('.gl-new-dropdown-item', text: 'No Epic').click
      click_button 'Create issue'

      wait_for_all_requests

      page.within(".js-epic-block .js-epic-label") do
        expect(page).to have_content('None')
      end

      expect(page).to have_content(issue_title)
    end

    it 'credates an issue with an epic' do
      click_button 'Select epic'
      find('.gl-new-dropdown-item', text: epic.title).click
      click_button 'Create issue'

      wait_for_all_requests

      page.within(".js-epic-block .js-epic-label") do
        expect(page).to have_content(epic.title)
      end

      expect(page).to have_content(issue_title)
    end
  end
end
