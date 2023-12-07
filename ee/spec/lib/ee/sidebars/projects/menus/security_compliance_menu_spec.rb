# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Projects::Menus::SecurityComplianceMenu do
  let_it_be(:project) { create(:project) }

  let(:user) { project.owner }
  let(:show_promotions) { true }
  let(:show_discover_project_security) { true }
  let(:context) { Sidebars::Projects::Context.new(current_user: user, container: project, show_promotions: show_promotions, show_discover_project_security: show_discover_project_security) }

  subject { described_class.new(context) }

  describe 'render?' do
    context 'when user can access security and compliance' do
      it 'returns true' do
        expect(subject.render?).to eq true
      end
    end

    context 'when user cannot access security and compliance' do
      let(:user) { nil }

      context 'when show discover project security is enabled' do
        it 'returns true' do
          expect(subject.render?).to eq true
        end
      end

      context 'when show discover project security is disabled' do
        let(:show_discover_project_security) { false }

        it 'returns false' do
          expect(subject.render?).to eq false
        end
      end
    end
  end

  describe '#link' do
    let(:show_promotions) { false }

    using RSpec::Parameterized::TableSyntax

    where(:security_dashboard_feature, :audit_events_feature, :dependency_scanning_feature, :expected_link) do
      true  | true  | true  | "/-/security/dashboard"
      false | true  | true  | "/-/audit_events"
      false | false | true  | "/-/dependencies"
      false | false | false | "/-/security/configuration"
    end

    with_them do
      it 'returns the expected link' do
        stub_licensed_features(security_dashboard: security_dashboard_feature, audit_events: audit_events_feature, dependency_scanning: dependency_scanning_feature)

        expect(subject.link).to include(expected_link)
      end
    end

    context 'when no security menu item and show promotions' do
      let(:user) { nil }

      it 'returns the link to the discover security path', :aggregate_failures do
        expect(subject.renderable_items).to be_empty
        expect(subject.link).to eq("/#{project.full_path}/-/security/discover")
      end
    end
  end

  describe 'Menu items' do
    subject { described_class.new(context).renderable_items.find { |i| i.item_id == item_id } }

    describe 'Configuration' do
      let(:item_id) { :configuration }

      describe '#sidebar_security_configuration_paths' do
        let(:expected_security_configuration_paths) do
          %w[
            projects/security/configuration#show
            projects/security/sast_configuration#show
            projects/security/api_fuzzing_configuration#show
            projects/security/dast_profiles#show
            projects/security/dast_site_profiles#new
            projects/security/dast_site_profiles#edit
            projects/security/dast_scanner_profiles#new
            projects/security/dast_scanner_profiles#edit
          ]
        end

        it 'includes all the security configuration paths' do
          expect(subject.active_routes[:path]).to eq expected_security_configuration_paths
        end
      end
    end

    describe 'Security Dashboard' do
      let(:item_id) { :dashboard }

      before do
        stub_licensed_features(security_dashboard: true)
      end

      context 'when user can access security dashboard' do
        it { is_expected.not_to be_nil }
      end

      context 'when user cannot access security dashboard' do
        let(:user) { nil }

        it { is_expected.to be_nil }
      end
    end

    describe 'Vulnerability Report' do
      let(:item_id) { :vulnerability_report }

      before do
        stub_licensed_features(security_dashboard: true)
      end

      context 'when user can access vulnerabilities report' do
        it { is_expected.not_to be_nil }
      end

      context 'when user cannot access vulnerabilities report' do
        let(:user) { nil }

        it { is_expected.to be_nil }
      end
    end

    describe 'On Demand Scans' do
      let(:item_id) { :on_demand_scans }

      before do
        stub_licensed_features(security_on_demand_scans: true)
      end

      context 'when user can access vulnerabilities report' do
        it { is_expected.not_to be_nil }
      end

      context 'when user cannot access vulnerabilities report' do
        let(:user) { nil }

        it { is_expected.to be_nil }
      end
    end

    describe 'Dependency List' do
      let(:item_id) { :dependency_list }

      before do
        stub_licensed_features(dependency_scanning: true)
      end

      context 'when user can access dependency list' do
        it { is_expected.not_to be_nil }
      end

      context 'when user cannot access dependency list' do
        let(:user) { nil }

        it { is_expected.to be_nil }
      end
    end

    describe 'License Compliance' do
      let(:item_id) { :license_compliance }

      before do
        stub_licensed_features(license_scanning: true)
      end

      context 'when user can access license compliance' do
        it { is_expected.not_to be_nil }
      end

      context 'when user cannot access license compliance' do
        let(:user) { nil }

        it { is_expected.to be_nil }
      end
    end

    describe 'Threat monitoring' do
      let(:item_id) { :threat_monitoring }

      before do
        stub_licensed_features(threat_monitoring: true)
      end

      context 'when user can access threat monitoring' do
        it { is_expected.not_to be_nil }
      end

      context 'when user cannot access threat monitoring' do
        let(:user) { nil }

        it { is_expected.to be_nil }
      end
    end

    describe 'Scan Policies' do
      let(:item_id) { :scan_policies }

      context 'when feature flag :security_orchestration_policies_configuration is enabled' do
        before do
          stub_feature_flags(security_orchestration_policies_configuration: true)
          stub_licensed_features(security_orchestration_policies: true)
        end

        context 'when user can access scan policies' do
          it { is_expected.not_to be_nil }
        end

        context 'when user cannot access scan policies' do
          let(:user) { nil }

          it { is_expected.to be_nil }
        end
      end

      context 'when feature flag :security_orchestration_policies_configuration is disabled' do
        before do
          stub_feature_flags(security_orchestration_policies_configuration: false)
        end

        it { is_expected.to be_nil }
      end
    end

    describe 'Audit Events' do
      let(:item_id) { :audit_events }

      context 'when user can access audit events' do
        it { is_expected.not_to be_nil }

        context 'when feature audit events is licensed' do
          before do
            stub_licensed_features(audit_events: true)
          end

          it { is_expected.not_to be_nil }
        end

        context 'when feature audit events is not licensed' do
          before do
            stub_licensed_features(audit_events: false)
          end

          context 'when show promotions is enabled' do
            it { is_expected.not_to be_nil }
          end

          context 'when show promotions is disabled' do
            let(:show_promotions) { false }

            it { is_expected.to be_nil }
          end
        end
      end

      context 'when user cannot access audit events' do
        let(:user) { nil }

        it { is_expected.to be_nil }
      end
    end
  end
end
