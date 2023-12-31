# frozen_string_literal: true

module API
  module Concerns
    module Packages
      module DebianEndpoints
        extend ActiveSupport::Concern

        DISTRIBUTION_REGEX = %r{[a-zA-Z0-9][a-zA-Z0-9.-]*}.freeze
        COMPONENT_REGEX = %r{[a-z-]+}.freeze
        ARCHITECTURE_REGEX = %r{[a-z][a-z0-9]*}.freeze
        LETTER_REGEX = %r{(lib)?[a-z0-9]}.freeze
        PACKAGE_REGEX = API::NO_SLASH_URL_PART_REGEX
        DISTRIBUTION_REQUIREMENTS = {
          distribution: DISTRIBUTION_REGEX
        }.freeze
        COMPONENT_ARCHITECTURE_REQUIREMENTS = {
          component: COMPONENT_REGEX,
          architecture: ARCHITECTURE_REGEX
        }.freeze
        COMPONENT_LETTER_SOURCE_PACKAGE_REQUIREMENTS = {
          component: COMPONENT_REGEX,
          letter: LETTER_REGEX,
          source_package: PACKAGE_REGEX
        }.freeze
        FILE_NAME_REQUIREMENTS = {
          file_name: API::NO_SLASH_URL_PART_REGEX
        }.freeze

        included do
          feature_category :package_registry

          helpers ::API::Helpers::PackagesHelpers
          helpers ::API::Helpers::Packages::BasicAuthHelpers

          format :txt
          content_type :txt, 'text/plain'

          rescue_from ArgumentError do |e|
            render_api_error!(e.message, 400)
          end

          rescue_from ActiveRecord::RecordInvalid do |e|
            render_api_error!(e.message, 400)
          end

          before do
            require_packages_enabled!
          end

          namespace 'packages/debian' do
            params do
              requires :distribution, type: String, desc: 'The Debian Codename', regexp: Gitlab::Regex.debian_distribution_regex
            end

            namespace 'dists/*distribution', requirements: DISTRIBUTION_REQUIREMENTS do
              # GET {projects|groups}/:id/packages/debian/dists/*distribution/Release.gpg
              desc 'The Release file signature' do
                detail 'This feature was introduced in GitLab 13.5'
              end

              route_setting :authentication, deploy_token_allowed: true, basic_auth_personal_access_token: true, job_token_allowed: :basic_auth, authenticate_non_public: true
              get 'Release.gpg' do
                not_found!
              end

              # GET {projects|groups}/:id/packages/debian/dists/*distribution/Release
              desc 'The unsigned Release file' do
                detail 'This feature was introduced in GitLab 13.5'
              end

              route_setting :authentication, deploy_token_allowed: true, basic_auth_personal_access_token: true, job_token_allowed: :basic_auth, authenticate_non_public: true
              get 'Release' do
                # https://gitlab.com/gitlab-org/gitlab/-/issues/5835#note_414103286
                'TODO Release'
              end

              # GET {projects|groups}/:id/packages/debian/dists/*distribution/InRelease
              desc 'The signed Release file' do
                detail 'This feature was introduced in GitLab 13.5'
              end

              route_setting :authentication, deploy_token_allowed: true, basic_auth_personal_access_token: true, job_token_allowed: :basic_auth, authenticate_non_public: true
              get 'InRelease' do
                not_found!
              end

              params do
                requires :component, type: String, desc: 'The Debian Component', regexp: Gitlab::Regex.debian_component_regex
                requires :architecture, type: String, desc: 'The Debian Architecture', regexp: Gitlab::Regex.debian_architecture_regex
              end

              namespace ':component/binary-:architecture', requirements: COMPONENT_ARCHITECTURE_REQUIREMENTS do
                # GET {projects|groups}/:id/packages/debian/dists/*distribution/:component/binary-:architecture/Packages
                desc 'The binary files index' do
                  detail 'This feature was introduced in GitLab 13.5'
                end

                route_setting :authentication, deploy_token_allowed: true, basic_auth_personal_access_token: true, job_token_allowed: :basic_auth, authenticate_non_public: true
                get 'Packages' do
                  # https://gitlab.com/gitlab-org/gitlab/-/issues/5835#note_414103286
                  'TODO Packages'
                end
              end
            end

            params do
              requires :component, type: String, desc: 'The Debian Component', regexp: Gitlab::Regex.debian_component_regex
              requires :letter, type: String, desc: 'The Debian Classification (first-letter or lib-first-letter)'
              requires :source_package, type: String, desc: 'The Debian Source Package Name', regexp: Gitlab::Regex.debian_package_name_regex
            end

            namespace 'pool/:component/:letter/:source_package', requirements: COMPONENT_LETTER_SOURCE_PACKAGE_REQUIREMENTS do
              # GET {projects|groups}/:id/packages/debian/pool/:component/:letter/:source_package/:file_name
              params do
                requires :file_name, type: String, desc: 'The Debian File Name'
              end
              desc 'The package' do
                detail 'This feature was introduced in GitLab 13.5'
              end

              route_setting :authentication, deploy_token_allowed: true, basic_auth_personal_access_token: true, job_token_allowed: :basic_auth, authenticate_non_public: true
              get ':file_name', requirements: FILE_NAME_REQUIREMENTS do
                # https://gitlab.com/gitlab-org/gitlab/-/issues/5835#note_414103286
                'TODO File'
              end
            end
          end
        end
      end
    end
  end
end
