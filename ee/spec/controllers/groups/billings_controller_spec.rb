# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::BillingsController do
  let_it_be(:user)  { create(:user) }
  let_it_be(:group) { create(:group, :private) }

  describe 'GET index' do
    before do
      sign_in(user)
      stub_application_setting(check_namespace_plan: true)
      allow(Gitlab::CurrentSettings).to receive(:should_check_namespace_plan?) { true }
    end

    def get_index
      get :index, params: { group_id: group }
    end

    def add_group_owner
      group.add_owner(user)
    end

    subject { response }

    context 'authorized' do
      before do
        add_group_owner
        allow_next_instance_of(GitlabSubscriptions::FetchSubscriptionPlansService) do |instance|
          allow(instance).to receive(:execute).and_return([])
        end
        allow(controller).to receive(:track_experiment_event)
      end

      it 'renders index with 200 status code' do
        get_index

        is_expected.to have_gitlab_http_status(:ok)
        is_expected.to render_template(:index)
      end

      it 'fetches subscription plans data from customers.gitlab.com' do
        data = double
        expect_next_instance_of(GitlabSubscriptions::FetchSubscriptionPlansService) do |instance|
          expect(instance).to receive(:execute).and_return(data)
        end

        get_index

        expect(assigns(:plans_data)).to eq(data)
      end

      it 'tracks the page view for the contact_sales_btn_in_app experiment' do
        expect(controller).to receive(:track_experiment_event).with(:contact_sales_btn_in_app, 'page_view:billing_plans:group')

        get_index
      end

      it 'records user for the contact_sales_btn_in_app experiment' do
        expect(controller).to receive(:record_experiment_user).with(:contact_sales_btn_in_app)

        get_index
      end

      context 'when CustomersDot is unavailable' do
        before do
          allow_next_instance_of(GitlabSubscriptions::FetchSubscriptionPlansService) do |instance|
            allow(instance).to receive(:execute).and_return(nil)
          end
        end

        it 'does not track the page view for the contact_sales_btn_in_app experiment' do
          expect(controller).not_to receive(:track_experiment_event)

          get_index

          expect(response).to render_template('shared/billings/customers_dot_unavailable')
        end

        it 'does not record the user for the contact_sales_btn_in_app experiment' do
          expect(controller).not_to receive(:record_experiment_user)

          get_index

          expect(response).to render_template('shared/billings/customers_dot_unavailable')
        end
      end
    end

    context 'unauthorized' do
      it 'renders 404 when user is not an owner' do
        group.add_developer(user)

        get_index

        is_expected.to have_gitlab_http_status(:not_found)
      end

      it 'renders 404 when it is not gitlab.com' do
        add_group_owner
        expect(Gitlab::CurrentSettings).to receive(:should_check_namespace_plan?).at_least(:once) { false }

        get_index

        is_expected.to have_gitlab_http_status(:not_found)
      end
    end
  end
end
