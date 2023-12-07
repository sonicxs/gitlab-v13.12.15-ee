# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::SecurityOrchestrationPolicies::OnDemandScanPipelineConfigurationService do
  describe '#execute' do
    let_it_be_with_reload(:project) { create(:project, :repository) }

    let_it_be(:site_profile) { create(:dast_site_profile, project: project) }
    let_it_be(:scanner_profile) { create(:dast_scanner_profile, project: project) }

    let(:service) { described_class.new(project) }
    let(:actions) do
      [
        {
          scan: 'dast',
          site_profile: site_profile.name,
          scanner_profile: scanner_profile.name
        },
        {
          scan: 'dast',
          site_profile: 'Site Profile B'
        }
      ]
    end

    subject(:pipeline_configuration) { service.execute(actions) }

    before do
      allow(DastSiteProfilesFinder).to receive(:new).and_return(double(execute: []))
      allow(DastSiteProfilesFinder).to receive(:new).with(project_id: project.id, name: site_profile.name).and_return(double(execute: [site_profile]))
      allow(DastScannerProfilesFinder).to receive(:new).and_return(double(execute: []))
      allow(DastScannerProfilesFinder).to receive(:new).with(project_ids: [project.id], name: scanner_profile.name).and_return(double(execute: [scanner_profile]))
    end

    it 'uses DastSiteProfilesFinder and DastScannerProfilesFinder to find DAST profiles within the project' do
      expect(DastSiteProfilesFinder).to receive(:new).with(project_id: project.id, name: site_profile.name)
      expect(DastSiteProfilesFinder).to receive(:new).with(project_id: project.id, name: 'Site Profile B')
      expect(DastScannerProfilesFinder).to receive(:new).with(project_ids: [project.id], name: scanner_profile.name)

      pipeline_configuration
    end

    it 'delegates params creation to DastOnDemandScans::ParamsCreateService' do
      expect(DastOnDemandScans::ParamsCreateService).to receive(:new).with(container: project, params: { dast_site_profile: site_profile, dast_scanner_profile: scanner_profile }).and_call_original
      expect(DastOnDemandScans::ParamsCreateService).to receive(:new).with(container: project, params: { dast_site_profile: nil, dast_scanner_profile: nil }).and_call_original

      pipeline_configuration
    end

    it 'delegates variables preparation to ::Ci::DastScanCiConfigurationService' do
      expected_params = {
        auth_password_field: site_profile.auth_password_field,
        auth_url: site_profile.auth_url,
        auth_username: site_profile.auth_username,
        auth_username_field: site_profile.auth_username_field,
        dast_profile: nil,
        dast_site_profile: site_profile,
        branch: project.default_branch,
        excluded_urls: site_profile.excluded_urls.join(','),
        full_scan_enabled: false,
        show_debug_messages: false,
        spider_timeout: nil,
        target_timeout: nil,
        target_url: site_profile.dast_site.url,
        use_ajax_spider: false
      }

      expect(::Ci::DastScanCiConfigurationService).to receive(:execute).with(expected_params).and_call_original

      pipeline_configuration
    end

    it 'fetches template content using ::TemplateFinder' do
      expect(::TemplateFinder).to receive(:build).with(:gitlab_ci_ymls, nil, name: 'DAST-On-Demand-Scan').and_call_original

      pipeline_configuration
    end

    it 'returns prepared CI configuration with DAST On-Demand scans defined' do
      expected_configuration = {
        'dast-on-demand-0': {
          stage: 'test',
          image: { name: '$SECURE_ANALYZERS_PREFIX/dast:$DAST_VERSION' },
          variables: {
            DAST_AUTH_URL: site_profile.auth_url,
            DAST_DEBUG: 'false',
            DAST_EXCLUDE_URLS: site_profile.excluded_urls.join(','),
            DAST_FULL_SCAN_ENABLED: 'false',
            DAST_PASSWORD_FIELD: site_profile.auth_password_field,
            DAST_USERNAME: site_profile.auth_username,
            DAST_USERNAME_FIELD: site_profile.auth_username_field,
            DAST_USE_AJAX_SPIDER: 'false',
            DAST_VERSION: 1,
            DAST_WEBSITE: site_profile.dast_site.url,
            SECURE_ANALYZERS_PREFIX: 'registry.gitlab.com/gitlab-org/security-products/analyzers'
          },
          allow_failure: true,
          script: ['/analyze'],
          artifacts: { reports: { dast: 'gl-dast-report.json' } }
        },
        'dast-on-demand-1': {
          script: 'echo "Error during On-Demand Scan execution: Dast site profile was not provided" && false',
          allow_failure: true
        }
      }

      expect(pipeline_configuration).to eq(expected_configuration)
    end
  end
end
