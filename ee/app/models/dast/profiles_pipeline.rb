# frozen_string_literal: true

module Dast
  class ProfilesPipeline < ApplicationRecord
    extend SuppressCompositePrimaryKeyWarning

    self.table_name = 'dast_profiles_pipelines'

    belongs_to :ci_pipeline, class_name: 'Ci::Pipeline', optional: false, inverse_of: :dast_profiles_pipeline
    belongs_to :dast_profile, class_name: 'Dast::Profile', optional: false, inverse_of: :dast_profiles_pipelines
  end
end