# frozen_string_literal: true

module QA
  module EE
    module Page
      module Admin
        class License < QA::Page::Base
          view 'ee/app/views/admin/licenses/missing.html.haml' do
            element :missing_license_content
          end

          view 'ee/app/views/admin/licenses/show.html.haml' do
            element :license_upload_link
          end

          view 'ee/app/views/admin/licenses/_info.html.haml' do
            element :remove_license_link
          end

          view 'ee/app/views/admin/licenses/new.html.haml' do
            element :accept_eula_checkbox
            element :license_key_field
            element :license_type_key_radio
            element :license_upload_button
          end

          def license?
            has_element?(:remove_license_link) || !has_element?(:missing_license_content)
          end

          def add_new_license(key)
            raise 'License key empty!' if key.to_s.empty?

            click_element(:license_upload_link)
            choose_element(:license_type_key_radio)
            fill_element(:license_key_field, key)
            check_element(:accept_eula_checkbox)
            click_element(:license_upload_button)
          end
        end
      end
    end
  end
end
