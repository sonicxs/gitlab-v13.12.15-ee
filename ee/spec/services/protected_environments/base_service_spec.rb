# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProtectedEnvironments::BaseService, '#execute' do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project) }
  let_it_be(:other_group) { create(:group) }
  let_it_be(:child_group) { create(:group, parent: group) }
  let_it_be(:current_user) { create(:user) }

  let(:service) do
    described_class.new(container, current_user, params)
  end

  before_all do
    create(:project_group_link, group: group, project: project)
    create(:project_group_link, group: child_group, project: project)
  end

  describe '#sanitized_params' do
    subject { service.send(:sanitized_params) }

    context 'with project container' do
      let(:container) { project }

      context 'with group-based access control' do
        let(:params) do
          {
            deploy_access_levels_attributes: [
              { group_id: group.id },
              { group_id: other_group.id },
              { group_id: child_group.id }
            ]
          }
        end

        it 'filters out inappropriate group id' do
          is_expected.to eq(
            deploy_access_levels_attributes: [
              { group_id: group.id },
              { group_id: child_group.id }
            ]
          )
        end

        context 'with delete flag' do
          let(:params) do
            {
              deploy_access_levels_attributes: [
                { group_id: group.id },
                { group_id: other_group.id, '_destroy' => 1 },
                { group_id: child_group.id }
              ]
            }
          end

          it 'contains inappropriate group id for deleting it' do
            is_expected.to eq(
              deploy_access_levels_attributes: [
                { group_id: group.id },
                { group_id: other_group.id, '_destroy' => 1 },
                { group_id: child_group.id }
              ]
            )
          end
        end
      end

      context 'with user-based access control' do
        let(:params) do
          {
            deploy_access_levels_attributes: [
              { user_id: group_maintainer.id },
              { user_id: group_developer.id },
              { user_id: other_group_maintainer.id },
              { user_id: child_group_maintainer.id }
            ]
          }
        end

        let!(:group_maintainer) { create(:user) }
        let!(:group_developer) { create(:user) }
        let!(:other_group_maintainer) { create(:user) }
        let!(:child_group_maintainer) { create(:user) }

        before do
          group.add_maintainer(group_maintainer)
          group.add_developer(group_developer)
          other_group.add_maintainer(other_group_maintainer)
          child_group.add_maintainer(child_group_maintainer)
        end

        it 'filters out inappropriate user ids' do
          is_expected.to eq(
            deploy_access_levels_attributes: [
              { user_id: group_maintainer.id },
              { user_id: group_developer.id },
              { user_id: child_group_maintainer.id }
            ]
          )
        end

        context 'with delte flag' do
          let(:params) do
            {
              deploy_access_levels_attributes: [
                { user_id: group_maintainer.id },
                { user_id: group_developer.id, '_destroy' => 1 },
                { user_id: other_group_maintainer.id, '_destroy' => 1 },
                { user_id: child_group_maintainer.id, '_destroy' => 1 }
              ]
            }
          end

          it 'contains inappropriate user ids for deleting it' do
            is_expected.to eq(params)
          end
        end
      end
    end
  end
end
