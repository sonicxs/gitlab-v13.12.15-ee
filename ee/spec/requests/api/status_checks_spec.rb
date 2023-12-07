# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::StatusChecks do
  include AccessMatchersForRequest

  describe 'POST :id/:merge_requests/:merge_request_iid/status_check_responses' do
    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:rule) { create(:external_approval_rule, project: project) }
    let_it_be(:merge_request) { create(:merge_request, source_project: project) }
    let_it_be(:project_maintainer) { create(:user) }

    let(:sha) { merge_request.source_branch_sha }
    let(:user) { project_maintainer }

    subject { post api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/status_check_responses", user), params: { external_approval_rule_id: rule.id, sha: sha } }

    describe 'permissions' do
      it { expect { subject }.to be_allowed_for(:maintainer).of(project) }
      it { expect { subject }.to be_allowed_for(:developer).of(project) }
      it { expect { subject }.to be_denied_for(:reporter).of(project) }
    end

    context 'feature flag is disabled' do
      before do
        stub_feature_flags(ff_compliance_approval_gates: false)
      end

      it 'returns a not found error' do
        subject

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when user has access' do
      before do
        project.add_user(project_maintainer, :maintainer)
      end

      it 'returns a 201' do
        subject

        expect(response).to have_gitlab_http_status(:created)
      end

      it 'returns the status checks as JSON' do
        subject

        expect(json_response.keys).to contain_exactly('id', 'merge_request', 'external_approval_rule')
      end

      it 'creates new StatusCheckResponse with correct attributes' do
        expect { subject }.to change { MergeRequests::StatusCheckResponse.count }.by 1
      end

      context 'when sha is not the source branch HEAD' do
        let(:sha) { 'notarealsha' }

        it 'does not create a new approval' do
          expect { subject }.not_to change { MergeRequests::StatusCheckResponse.count }
        end

        it 'returns a conflict error' do
          subject

          expect(response).to have_gitlab_http_status(:conflict)
        end
      end

      context 'when user is not authenticated' do
        let(:user) { nil }

        it 'returns an unauthorized status' do
          subject

          expect(response).to have_gitlab_http_status(:unauthorized)
        end
      end
    end
  end
end
