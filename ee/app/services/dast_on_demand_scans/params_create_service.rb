# frozen_string_literal: true

module DastOnDemandScans
  class ParamsCreateService < BaseContainerService
    include Gitlab::Utils::StrongMemoize

    def execute
      return ServiceResponse.error(message: 'Dast site profile was not provided') unless dast_site_profile.present?
      return ServiceResponse.error(message: 'Cannot run active scan against unvalidated target') unless active_scan_allowed?

      ServiceResponse.success(
        payload: default_config.merge(target_config, site_profile_config, scanner_profile_config)
      )
    end

    private

    def active_scan_allowed?
      return true unless dast_scanner_profile&.full_scan_enabled?

      DastSiteValidationsFinder.new(
        project_id: container.id,
        state: :passed,
        url_base: url_base
      ).execute.present?
    end

    def dast_profile
      strong_memoize(:dast_profile) do
        params[:dast_profile]
      end
    end

    def dast_site_profile
      strong_memoize(:dast_site_profile) do
        dast_profile&.dast_site_profile || params[:dast_site_profile]
      end
    end

    def dast_scanner_profile
      strong_memoize(:dast_scanner_profile) do
        dast_profile&.dast_scanner_profile || params[:dast_scanner_profile]
      end
    end

    def dast_site
      strong_memoize(:dast_site) do
        dast_site_profile.dast_site
      end
    end

    def branch
      strong_memoize(:branch) do
        dast_profile&.branch_name || params[:branch] || container.default_branch
      end
    end

    def url_base
      strong_memoize(:url_base) do
        DastSiteValidation.get_normalized_url_base(dast_site&.url)
      end
    end

    def default_config
      { dast_profile: dast_profile, dast_site_profile: dast_site_profile, branch: branch }
    end

    def target_config
      url = dast_site.url

      if dast_site_profile.target_type == 'website'
        { target_url: url }
      else
        { api_specification_url: url, api_host_override: URI(url).host }
      end
    end

    def site_profile_config
      return {} unless dast_site_profile

      excluded_urls = dast_site_profile.excluded_urls.presence&.join(',')
      return { excluded_urls: excluded_urls } unless dast_site_profile.auth_enabled

      {
        excluded_urls: excluded_urls,
        auth_username_field: dast_site_profile.auth_username_field,
        auth_password_field: dast_site_profile.auth_password_field,
        auth_username: dast_site_profile.auth_username,
        auth_url: dast_site_profile.auth_url
      }
    end

    def scanner_profile_config
      return {} unless dast_scanner_profile

      {
        spider_timeout: dast_scanner_profile.spider_timeout,
        target_timeout: dast_scanner_profile.target_timeout,
        full_scan_enabled: dast_scanner_profile.full_scan_enabled?,
        use_ajax_spider: dast_scanner_profile.use_ajax_spider,
        show_debug_messages: dast_scanner_profile.show_debug_messages
      }
    end
  end
end
