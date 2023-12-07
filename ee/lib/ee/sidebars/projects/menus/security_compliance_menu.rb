# frozen_string_literal: true

module EE
  module Sidebars
    module Projects
      module Menus
        module SecurityComplianceMenu
          extend ::Gitlab::Utils::Override

          override :configure_menu_items
          def configure_menu_items
            return false unless can?(context.current_user, :access_security_and_compliance, context.project)

            add_item(security_dashboard_menu_item)
            add_item(vulnerability_report_menu_item)
            add_item(on_demand_scans_menu_item)
            add_item(dependencies_menu_item)
            add_item(license_compliance_menu_item)
            add_item(threat_monitoring_menu_item)
            add_item(scan_policies_menu_item)
            add_item(configuration_menu_item)
            add_item(audit_events_menu_item)

            true
          end

          override :link
          def link
            return project_security_discover_path(context.project) unless has_items?
            return security_dashboard_menu_item.link if security_dashboard_menu_item.render?
            return audit_events_menu_item.link if audit_events_menu_item.render?
            return dependencies_menu_item.link if dependencies_menu_item.render?

            renderable_items.first.link
          end

          override :render?
          def render?
            super || context.show_discover_project_security
          end

          private

          override :configuration_menu_item_paths
          def configuration_menu_item_paths
            super + %w[
              projects/security/sast_configuration#show
              projects/security/api_fuzzing_configuration#show
              projects/security/dast_profiles#show
              projects/security/dast_site_profiles#new
              projects/security/dast_site_profiles#edit
              projects/security/dast_scanner_profiles#new
              projects/security/dast_scanner_profiles#edit
            ]
          end

          override :render_configuration_menu_item?
          def render_configuration_menu_item?
            super ||
              (context.project.licensed_feature_available?(:security_dashboard) && can?(context.current_user, :read_project_security_dashboard, context.project))
          end

          def security_dashboard_menu_item
            strong_memoize(:security_dashboard_menu_item) do
              unless can?(context.current_user, :read_project_security_dashboard, context.project)
                next ::Sidebars::NilMenuItem.new(item_id: :dashboard)
              end

              ::Sidebars::MenuItem.new(
                title: _('Security Dashboard'),
                link: project_security_dashboard_index_path(context.project),
                active_routes: { path: 'projects/security/dashboard#index' },
                item_id: :dashboard
              )
            end
          end

          def vulnerability_report_menu_item
            strong_memoize(:vulnerability_report_menu_item) do
              unless can?(context.current_user, :read_project_security_dashboard, context.project)
                next ::Sidebars::NilMenuItem.new(item_id: :vulnerability_report)
              end

              ::Sidebars::MenuItem.new(
                title: _('Vulnerability Report'),
                link: project_security_vulnerability_report_index_path(context.project),
                active_routes: { path: %w[projects/security/vulnerability_report#index projects/security/vulnerabilities#show] },
                item_id: :vulnerability_report
              )
            end
          end

          def on_demand_scans_menu_item
            strong_memoize(:on_demand_scans_menu_item) do
              unless can?(context.current_user, :read_on_demand_scans, context.project)
                next ::Sidebars::NilMenuItem.new(item_id: :on_demand_scans)
              end

              ::Sidebars::MenuItem.new(
                title: s_('OnDemandScans|On-demand Scans'),
                link: new_project_on_demand_scan_path(context.project),
                item_id: :on_demand_scans,
                active_routes: { path: %w[
                  projects/on_demand_scans#index
                  projects/on_demand_scans#new
                  projects/on_demand_scans#edit
                ] }
              )
            end
          end

          def dependencies_menu_item
            strong_memoize(:dependencies_menu_item) do
              unless can?(context.current_user, :read_dependencies, context.project)
                next ::Sidebars::NilMenuItem.new(item_id: :dependency_list)
              end

              ::Sidebars::MenuItem.new(
                title: _('Dependency List'),
                link: project_dependencies_path(context.project),
                active_routes: { path: 'projects/dependencies#index' },
                item_id: :dependency_list
              )
            end
          end

          def license_compliance_menu_item
            strong_memoize(:license_compliance_menu_item) do
              unless can?(context.current_user, :read_licenses, context.project)
                next ::Sidebars::NilMenuItem.new(item_id: :license_compliance)
              end

              ::Sidebars::MenuItem.new(
                title: _('License Compliance'),
                link: project_licenses_path(context.project),
                active_routes: { path: 'projects/licenses#index' },
                item_id: :license_compliance
              )
            end
          end

          def threat_monitoring_menu_item
            strong_memoize(:threat_monitoring_menu_item) do
              unless can?(context.current_user, :read_threat_monitoring, context.project)
                next ::Sidebars::NilMenuItem.new(item_id: :threat_monitoring)
              end

              ::Sidebars::MenuItem.new(
                title: _('Threat Monitoring'),
                link: project_threat_monitoring_path(context.project),
                active_routes: { controller: ['projects/threat_monitoring'] },
                item_id: :threat_monitoring
              )
            end
          end

          def scan_policies_menu_item
            strong_memoize(:scan_policies_menu_item) do
              if ::Feature.disabled?(:security_orchestration_policies_configuration, context.project) ||
                !can?(context.current_user, :security_orchestration_policies, context.project)
                next ::Sidebars::NilMenuItem.new(item_id: :scan_policies)
              end

              ::Sidebars::MenuItem.new(
                title: _('Scan Policies'),
                link: project_security_policy_path(context.project),
                active_routes: { controller: ['projects/security/policies'] },
                item_id: :scan_policies
              )
            end
          end

          def audit_events_menu_item
            strong_memoize(:audit_events_menu_item) do
              unless show_audit_events?
                next ::Sidebars::NilMenuItem.new(item_id: :audit_events)
              end

              ::Sidebars::MenuItem.new(
                title: _('Audit Events'),
                link: project_audit_events_path(context.project),
                active_routes: { controller: :audit_events },
                item_id: :audit_events
              )
            end
          end

          def show_audit_events?
            can?(context.current_user, :read_project_audit_events, context.project) &&
              (context.project.licensed_feature_available?(:audit_events) || context.show_promotions)
          end
        end
      end
    end
  end
end
