# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::LfsObjectLegacyRegistryFinder, :geo do
  before do
    stub_feature_flags(geo_lfs_object_replication: false )
  end

  it_behaves_like 'a file registry finder' do
    before do
      stub_lfs_object_storage
    end

    let_it_be(:replicable_1) { create(:lfs_object) }
    let_it_be(:replicable_2) { create(:lfs_object) }
    let_it_be(:replicable_3) { create(:lfs_object) }
    let_it_be(:replicable_4) { create(:lfs_object) }
    let_it_be(:replicable_5) { create(:lfs_object) }
    let!(:replicable_6) { create(:lfs_object, :object_storage) }
    let!(:replicable_7) { create(:lfs_object, :object_storage) }
    let!(:replicable_8) { create(:lfs_object, :object_storage) }

    let_it_be(:registry_1) { create(:geo_lfs_object_legacy_registry, :failed, lfs_object_id: replicable_1.id) }
    let_it_be(:registry_2) { create(:geo_lfs_object_legacy_registry, lfs_object_id: replicable_2.id, missing_on_primary: true) }
    let_it_be(:registry_3) { create(:geo_lfs_object_legacy_registry, :never_synced, lfs_object_id: replicable_3.id) }
    let_it_be(:registry_4) { create(:geo_lfs_object_legacy_registry, :failed, lfs_object_id: replicable_4.id) }
    let_it_be(:registry_5) { create(:geo_lfs_object_legacy_registry, lfs_object_id: replicable_5.id, missing_on_primary: true, retry_at: 1.day.ago) }
    let!(:registry_6) { create(:geo_lfs_object_legacy_registry, :failed, lfs_object_id: replicable_6.id) }
    let!(:registry_7) { create(:geo_lfs_object_legacy_registry, :failed, lfs_object_id: replicable_7.id, missing_on_primary: true) }
    let!(:registry_8) { create(:geo_lfs_object_legacy_registry, :never_synced, lfs_object_id: replicable_8.id) }
  end
end
