# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::Settings::IntegrationsController do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }

  before do
    sign_in(user)
  end

  describe '#index' do
    context 'when user is not owner' do
      it 'renders not_found' do
        get :index, params: { group_id: group }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when user is owner' do
      before do
        group.add_owner(user)
      end

      it 'successfully displays the template' do
        get :index, params: { group_id: group }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to render_template(:index)
      end
    end
  end

  describe '#edit' do
    context 'when user is not owner' do
      it 'renders not_found' do
        get :edit, params: { group_id: group, id: Integration.available_services_names(include_project_specific: false).sample }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when user is owner' do
      before do
        group.add_owner(user)
      end

      Integration.available_services_names(include_project_specific: false).each do |integration_name|
        context "#{integration_name}" do
          it 'successfully displays the template' do
            get :edit, params: { group_id: group, id: integration_name }

            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to render_template(:edit)
          end
        end
      end
    end
  end

  describe '#update' do
    include JiraServiceHelper

    let(:integration) { create(:jira_service, project: nil, group_id: group.id) }

    before do
      group.add_owner(user)
      stub_jira_service_test

      put :update, params: { group_id: group, id: integration.class.to_param, service: { url: url } }
    end

    context 'valid params' do
      let(:url) { 'https://jira.gitlab-example.com' }

      it 'updates the integration' do
        expect(response).to have_gitlab_http_status(:found)
        expect(integration.reload.url).to eq(url)
      end
    end

    context 'invalid params' do
      let(:url) { 'invalid' }

      it 'does not update the integration' do
        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to render_template(:edit)
        expect(integration.reload.url).not_to eq(url)
      end
    end
  end

  describe '#reset' do
    let_it_be(:integration) { create(:jira_service, group: group, project: nil) }
    let_it_be(:inheriting_integration) { create(:jira_service, inherit_from_id: integration.id) }

    subject do
      post :reset, params: { group_id: group, id: integration.class.to_param }
    end

    context 'when user is not owner' do
      it 'renders not_found' do
        subject

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when user is owner' do
      before do
        group.add_owner(user)
      end

      it 'returns 200 OK', :aggregate_failures do
        subject

        expected_json = {}.to_json

        expect(flash[:notice]).to eq('This integration, and inheriting projects were reset.')
        expect(response).to have_gitlab_http_status(:ok)
        expect(response.body).to eq(expected_json)
      end

      it 'deletes the integration and all inheriting integrations' do
        expect { subject }.to change { JiraService.for_group(group.id).count }.by(-1)
          .and change { JiraService.inherit_from_id(integration.id).count }.by(-1)
      end
    end
  end
end
