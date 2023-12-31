# frozen_string_literal: true

module Types
  module Projects
    class ServiceTypeEnum < BaseEnum
      graphql_name 'ServiceType'

      ::Integration.available_services_types(include_dev: false).each do |service_type|
        value service_type.underscore.upcase, value: service_type, description: "#{service_type} type"
      end
    end
  end
end
