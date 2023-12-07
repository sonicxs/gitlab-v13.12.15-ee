# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Group value stream analytics' do
  let_it_be(:group) { create(:group) }
  let_it_be(:user) { create(:user) }

  before do
    stub_licensed_features(cycle_analytics_for_groups: true)

    group.add_owner(user)

    sign_in(user)
  end

  it 'pushes frontend feature flags' do
    visit group_analytics_cycle_analytics_path(group)

    expect(page).to have_pushed_frontend_feature_flags(cycleAnalyticsScatterplotEnabled: true)
  end
end
