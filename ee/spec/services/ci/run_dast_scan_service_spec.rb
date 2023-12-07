# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::RunDastScanService do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository, creator: user) }
  let_it_be(:dast_profile) { create(:dast_profile) }
  let_it_be(:dast_site_profile) { dast_profile.dast_site_profile }
  let_it_be(:branch) { project.default_branch }
  let_it_be(:spider_timeout) { 42 }
  let_it_be(:target_timeout) { 21 }
  let_it_be(:target_url) { generate(:url) }
  let_it_be(:use_ajax_spider) { true }
  let_it_be(:show_debug_messages) { false }
  let_it_be(:full_scan_enabled) { true }
  let_it_be(:excluded_urls) { "#{target_url}/hello,#{target_url}/world" }
  let_it_be(:auth_url) { "#{target_url}/login" }

  before do
    stub_licensed_features(security_on_demand_scans: true)
  end

  describe '#execute' do
    subject do
      described_class.new(project, user).execute(
        branch: branch,
        target_url: target_url,
        spider_timeout: spider_timeout,
        target_timeout: target_timeout,
        use_ajax_spider: use_ajax_spider,
        show_debug_messages: show_debug_messages,
        full_scan_enabled: full_scan_enabled,
        excluded_urls: excluded_urls,
        auth_url: auth_url,
        auth_username_field: 'session[username]',
        auth_password_field: 'session[password]',
        auth_username: 'tanuki',
        dast_profile: dast_profile,
        dast_site_profile: dast_site_profile
      )
    end

    let(:status) { subject.status }
    let(:pipeline) { subject.payload }
    let(:message) { subject.message }

    context 'when a user does not have access to the project' do
      it 'returns an error status' do
        expect(status).to eq(:error)
      end

      it 'populates message' do
        expect(message).to eq('Insufficient permissions')
      end
    end

    context 'when the user can run a dast scan' do
      before do
        project.add_developer(user)
      end

      it 'returns a success status' do
        expect(status).to eq(:success)
      end

      it 'returns a pipeline' do
        expect(pipeline).to be_a(Ci::Pipeline)
      end

      it 'creates a pipeline' do
        expect { subject }.to change(Ci::Pipeline, :count).by(1)
      end

      it 'sets the pipeline ref to the branch' do
        expect(pipeline.ref).to eq(branch)
      end

      it 'sets the source to indicate an ondemand scan' do
        expect(pipeline.source).to eq('ondemand_dast_scan')
      end

      it 'creates a stage' do
        expect { subject }.to change(Ci::Stage, :count).by(1)
      end

      it 'creates a build' do
        expect { subject }.to change(Ci::Build, :count).by(1)
      end

      it 'sets the build name to indicate a DAST scan' do
        build = pipeline.builds.first
        expect(build.name).to eq('dast')
      end

      it 'creates a build with appropriate options' do
        build = pipeline.builds.first
        expected_options = {
          'image' => {
            'name' => '$SECURE_ANALYZERS_PREFIX/dast:$DAST_VERSION'
          },
          'script' => [
            '/analyze'
          ],
          'artifacts' => {
            'reports' => {
              'dast' => ['gl-dast-report.json']
            }
          }
        }
        expect(build.options).to eq(expected_options)
      end

      it 'creates a build with appropriate variables' do
        build = pipeline.builds.first

        expected_variables = [
          {
            'key' => 'DAST_AUTH_URL',
            'value' => auth_url,
            'public' => true
          }, {
            'key' => 'DAST_DEBUG',
            'value' => 'false',
            'public' => true
          }, {
            'key' => 'DAST_EXCLUDE_URLS',
            'value' => excluded_urls,
            'public' => true
          }, {
            'key' => 'DAST_FULL_SCAN_ENABLED',
            'value' => 'true',
            'public' => true
          }, {
            'key' => 'DAST_PASSWORD_FIELD',
            'value' => 'session[password]',
            'public' => true
          }, {
            'key' => 'DAST_SPIDER_MINS',
            'value' => spider_timeout.to_s,
            'public' => true
          }, {
            'key' => 'DAST_TARGET_AVAILABILITY_TIMEOUT',
            'value' => target_timeout.to_s,
            'public' => true
          }, {
            'key' => 'DAST_USERNAME',
            'value' => 'tanuki',
            'public' => true
          }, {
            'key' => 'DAST_USERNAME_FIELD',
            'value' => 'session[username]',
            'public' => true
          }, {
            'key' => 'DAST_USE_AJAX_SPIDER',
            'value' => 'true',
            'public' => true
          }, {
            'key' => 'DAST_VERSION',
            'value' => '1',
            'public' => true
          }, {
            'key' => 'DAST_WEBSITE',
            'value' => target_url,
            'public' => true
          }, {
            'key' => 'GIT_STRATEGY',
            'value' => 'none',
            'public' => true
          }, {
            'key' => 'SECURE_ANALYZERS_PREFIX',
            'value' => 'registry.gitlab.com/gitlab-org/security-products/analyzers',
            'public' => true
          }
        ]

        expect(build.yaml_variables).to contain_exactly(*expected_variables)
      end

      shared_examples 'transactional creation' do
        let_it_be(:type_mismatch) { build(:dast_scanner_profile) }

        it 'does not create a Ci::Pipeline' do
          expect { subject }.to raise_error(ActiveRecord::AssociationTypeMismatch).and change { Ci::Pipeline.count }.by(0)
        end
      end

      context 'when the dast_profile and dast_site_profile are provided' do
        it 'associates the dast_profile with the pipeline' do
          expect(pipeline.dast_profile).to eq(dast_profile)
        end

        it 'does associate the dast_site_profile with the pipeline' do
          expect(pipeline.dast_site_profile).to be_nil
        end

        it_behaves_like 'transactional creation' do
          let_it_be(:dast_profile) { type_mismatch }
        end
      end

      context 'when the dast_site_profile is provided' do
        let(:dast_profile) { nil }

        it 'associates the dast_site_profile with the pipeline' do
          expect(pipeline.dast_site_profile).to eq(dast_site_profile)
        end

        it_behaves_like 'transactional creation' do
          let_it_be(:dast_site_profile) { type_mismatch }
        end
      end

      context 'when the pipeline fails to save' do
        before do
          allow_any_instance_of(Ci::Pipeline).to receive(:created_successfully?).and_return(false)
          allow_any_instance_of(Ci::Pipeline).to receive(:full_error_messages).and_return(full_error_messages)
        end

        let(:full_error_messages) { SecureRandom.hex }

        it 'returns an error status' do
          expect(status).to eq(:error)
        end

        it 'populates message' do
          expect(message).to eq(full_error_messages)
        end
      end

      context 'when on demand scan licensed feature is not available' do
        before do
          stub_licensed_features(security_on_demand_scans: false)
        end

        it 'returns an error status' do
          expect(status).to eq(:error)
        end

        it 'populates message' do
          expect(message).to eq('Insufficient permissions')
        end
      end
    end
  end
end
