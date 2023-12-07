# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TrialRegistrationsController do
  let(:dev_env_or_com) { true }

  before do
    allow(Gitlab).to receive(:dev_env_or_com?).and_return(dev_env_or_com)
  end

  shared_examples 'a dot-com only feature' do
    let(:success_status) { :ok }

    context 'when not on gitlab.com and not in development environment' do
      let(:dev_env_or_com) { false }

      it { is_expected.to have_gitlab_http_status(:not_found) }
    end

    context 'when on gitlab.com or in dev environment' do
      it { is_expected.to have_gitlab_http_status(success_status) }
    end
  end

  describe '#new' do
    let(:logged_in_user) { nil }
    let(:get_params) { {} }

    before do
      sign_in(logged_in_user) if logged_in_user.present?
      get :new, params: get_params
    end

    subject { response }

    it_behaves_like 'a dot-com only feature'

    context 'when customer is authenticated' do
      let_it_be(:logged_in_user) { create(:user) }

      it { is_expected.to redirect_to(new_trial_url) }

      context 'when there are additional query params' do
        let(:get_params) { { glm_source: 'some_source', glm_content: 'some_content' } }

        it { is_expected.to redirect_to(new_trial_url(get_params)) }
      end
    end

    context 'when customer is not authenticated' do
      it { is_expected.to render_template(:new) }
    end
  end

  describe '#create' do
    let(:user_params) do
      {
        first_name: 'John',
        last_name: 'Doe',
        email: 'johnd2019@local.dev',
        username: 'johnd',
        password: 'abcd1234'
      }
    end

    before do
      stub_application_setting(send_user_confirmation_email: true)
      post :create, params: { user: user_params }
    end

    it_behaves_like 'a dot-com only feature' do
      let(:success_status) { :found }
      subject { response }
    end

    it 'marks the account as unconfirmed' do
      expect(User.last).not_to be_confirmed
    end

    context 'derivation of name' do
      it 'sets name from first and last name' do
        expect(User.last.name).to eq("#{user_params[:first_name]} #{user_params[:last_name]}")
      end
    end
  end
end
