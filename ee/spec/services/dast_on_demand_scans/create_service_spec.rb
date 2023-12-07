# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DastOnDemandScans::CreateService do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }
  let_it_be(:dast_site_profile) { create(:dast_site_profile, project: project) }
  let_it_be(:dast_scanner_profile) { create(:dast_scanner_profile, project: project) }

  let(:params) { { dast_site_profile: dast_site_profile, dast_scanner_profile: dast_scanner_profile } }

  subject do
    described_class.new(
      container: project,
      current_user: user,
      params: params
    ).execute
  end

  shared_examples 'a service that calls Ci::RunDastScanService' do
    it 'delegates pipeline creation to Ci::RunDastScanService', :aggregate_failures do
      service = double(Ci::RunDastScanService)
      response = ServiceResponse.error(message: 'Stubbed response')

      expect(Ci::RunDastScanService).to receive(:new).and_return(service)
      expect(service).to receive(:execute).with(expected_params).and_return(response)

      subject
    end
  end

  describe 'execute' do
    context 'when on demand scan licensed feature is not available' do
      context 'when the user cannot run an on demand scan' do
        it 'communicates failure', :aggregate_failures do
          stub_licensed_features(security_on_demand_scans: false)

          expect(subject.status).to eq(:error)
          expect(subject.message).to eq('Insufficient permissions')
        end
      end
    end

    context 'when the feature is enabled' do
      before do
        stub_licensed_features(security_on_demand_scans: true)
      end

      context 'when user can run an on demand scan' do
        before do
          project.add_developer(user)
        end

        it 'communicates success' do
          expect(subject.status).to eq(:success)
        end

        it 'returns a pipeline and pipeline_url', :aggregate_failures do
          expect(subject.payload[:pipeline]).to be_a(Ci::Pipeline)
          expect(subject.payload[:pipeline_url]).to be_a(String)
        end

        it_behaves_like 'a service that calls Ci::RunDastScanService' do
          let(:expected_params) do
            {
              auth_password_field: dast_site_profile.auth_password_field,
              auth_url: dast_site_profile.auth_url,
              auth_username: dast_site_profile.auth_username,
              auth_username_field: dast_site_profile.auth_username_field,
              branch: project.default_branch,
              dast_profile: nil,
              dast_site_profile: dast_site_profile,
              excluded_urls: dast_site_profile.excluded_urls.join(','),
              full_scan_enabled: false,
              show_debug_messages: false,
              spider_timeout: nil,
              target_timeout: nil,
              target_url: dast_site_profile.dast_site.url,
              use_ajax_spider: false
            }
          end
        end

        context 'when a branch is specified' do
          context 'when the branch does not exist' do
            let(:params) { { dast_site_profile: dast_site_profile, dast_scanner_profile: dast_scanner_profile, branch: 'other-branch' } }

            it 'responds with error message', :aggregate_failures do
              expect(subject).not_to be_success
              expect(subject.message).to eq('Reference not found')
            end
          end

          context 'when the branch exists' do
            let(:params) { { dast_site_profile: dast_site_profile, dast_scanner_profile: dast_scanner_profile, branch: 'orphaned-branch' } }

            it 'communicates success' do
              expect(subject.status).to eq(:success)
            end
          end
        end

        context 'when dast_scanner_profile is nil' do
          let(:dast_scanner_profile) { nil }

          it 'communicates success' do
            expect(subject.status).to eq(:success)
          end
        end

        context 'when dast_profile is specified' do
          let_it_be(:dast_profile) { create(:dast_profile, project: project) }

          let(:params) { { dast_profile: dast_profile } }

          it 'communicates success' do
            expect(subject.status).to eq(:success)
          end

          it_behaves_like 'a service that calls Ci::RunDastScanService' do
            let(:expected_params) { hash_including(dast_profile: dast_profile) }
          end
        end

        context 'when target is not validated and an active scan is requested' do
          let(:dast_scanner_profile) { create(:dast_scanner_profile, project: project, scan_type: 'active') }

          it 'communicates failure', :aggregate_failures do
            expect(subject.status).to eq(:error)
            expect(subject.message).to eq('Cannot run active scan against unvalidated target')
          end
        end
      end
    end
  end
end
