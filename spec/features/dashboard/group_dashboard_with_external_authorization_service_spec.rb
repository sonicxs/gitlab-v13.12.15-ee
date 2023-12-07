# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'The group dashboard' do
  include ExternalAuthorizationServiceHelpers

  let(:user) { create(:user) }

  shared_examples 'combined_menu: feature flag examples' do
    before do
      sign_in user
    end

    describe 'The top navigation' do
      it 'has all the expected links' do
        pending_on_combined_menu_flag

        visit dashboard_groups_path

        within('.navbar') do
          expect(page).to have_button('Projects')
          expect(page).to have_button('Groups')
          expect(page).to have_link('Activity')
          expect(page).to have_link('Milestones')
          expect(page).to have_link('Snippets')
        end
      end

      it 'hides some links when an external authorization service is enabled' do
        pending_on_combined_menu_flag

        enable_external_authorization_service_check
        visit dashboard_groups_path

        within('.navbar') do
          expect(page).to have_button('Projects')
          expect(page).to have_button('Groups')
          expect(page).not_to have_link('Activity')
          expect(page).not_to have_link('Milestones')
          expect(page).to have_link('Snippets')
        end
      end
    end
  end

  context 'with combined_menu: feature flag on' do
    let(:needs_rewrite_for_combined_menu_flag_on) { true }

    before do
      stub_feature_flags(combined_menu: true)
    end

    it_behaves_like 'combined_menu: feature flag examples'
  end

  context 'with combined_menu feature flag off' do
    let(:needs_rewrite_for_combined_menu_flag_on) { false }

    before do
      stub_feature_flags(combined_menu: false)
    end

    it_behaves_like 'combined_menu: feature flag examples'
  end

  def pending_on_combined_menu_flag
    pending 'https://gitlab.com/gitlab-org/gitlab/-/merge_requests/56587' if needs_rewrite_for_combined_menu_flag_on
  end
end
