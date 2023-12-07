# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User sees new onboarding flow', :js do
  before do
    stub_const('Gitlab::QueryLimiting::Transaction::THRESHOLD', 200)
    stub_feature_flags(registration_group_invite: false)
    allow(Gitlab).to receive(:com?).and_return(true)
    gitlab_sign_in(:user)
    visit users_sign_up_welcome_path
  end

  it 'shows the expected pages' do
    expect(page).to have_content('Welcome to GitLab')
    expect(page).to have_content('Your profile Your GitLab group Your first project')
    expect(page).to have_css('li.current', text: 'Your profile')

    choose 'Just me'
    click_on 'Continue'

    expect(page).to have_content('Create your group')
    expect(page).to have_content('Your profile Your GitLab group Your first project')
    expect(page).to have_css('li.current', text: 'Your GitLab group')

    fill_in 'group_name', with: 'test'

    expect(page).to have_field('group_path', with: 'test')

    click_on 'Create group'

    expect(page).to have_content('Create/import your first project')
    expect(page).to have_content('Your profile Your GitLab group Your first project')
    expect(page).to have_css('li.current', text: 'Your first project')

    fill_in 'project_name', with: 'test'

    expect(page).to have_field('project_path', with: 'test')

    click_on 'Create project'

    expect(page).to have_content('Welcome to the guided GitLab tour')

    Sidekiq::Worker.drain_all

    click_on 'Show me the basics'

    expect(page).to have_content('Learn GitLab')
    expect(page).to have_css('.selectable', text: 'Label = ~Novice')
  end
end
