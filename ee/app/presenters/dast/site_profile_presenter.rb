# frozen_string_literal: true

module Dast
  class SiteProfilePresenter < Gitlab::View::Presenter::Delegated
    REDACTED_PASSWORD = '••••••••'
    REDACTED_REQUEST_HEADERS = '••••••••'

    presents :site_profile

    def password
      return unless Feature.enabled?(:security_dast_site_profiles_additional_fields, site_profile.project, default_enabled: :yaml)
      return unless site_profile.secret_variables.any? { |variable| variable.key == ::Dast::SiteProfileSecretVariable::PASSWORD }

      REDACTED_PASSWORD
    end

    def request_headers
      return unless Feature.enabled?(:security_dast_site_profiles_additional_fields, site_profile.project, default_enabled: :yaml)
      return unless site_profile.secret_variables.any? { |variable| variable.key == ::Dast::SiteProfileSecretVariable::REQUEST_HEADERS }

      REDACTED_REQUEST_HEADERS
    end
  end
end
