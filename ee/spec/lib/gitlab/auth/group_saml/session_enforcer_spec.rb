# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Auth::GroupSaml::SessionEnforcer do
  describe '#access_restricted' do
    let_it_be(:saml_provider) { create(:saml_provider, enforced_sso: true) }
    let_it_be(:user) { create(:user) }
    let_it_be(:identity) { create(:group_saml_identity, saml_provider: saml_provider, user: user) }

    let(:root_group) { saml_provider.group }

    subject { described_class.new(user, root_group).access_restricted? }

    before do
      stub_licensed_features(group_saml: true)
    end

    context 'when git check is enforced' do
      before do
        allow(saml_provider).to receive(:git_check_enforced?).and_return(true)
      end

      context 'with an active session', :clean_gitlab_redis_shared_state do
        let(:session_id) { '42' }
        let(:session_time) { 5.minutes.ago }
        let(:stored_session) do
          { 'active_group_sso_sign_ins' => { saml_provider.id => session_time } }
        end

        before do
          Gitlab::Redis::SharedState.with do |redis|
            redis.set("session:gitlab:#{session_id}", Marshal.dump(stored_session))
            redis.sadd("session:lookup:user:gitlab:#{user.id}", [session_id])
          end
        end

        it { is_expected.to be_falsey }

        context 'with sub-group' do
          let(:group) { create(:group, parent: root_group) }

          subject { described_class.new(user, group).access_restricted? }

          it { is_expected.to be_falsey }
        end

        context 'with expired session' do
          let(:session_time) { 2.days.ago }

          it { is_expected.to be_truthy }
        end

        context 'with two active sessions', :clean_gitlab_redis_shared_state do
          let(:second_session_id) { '52' }
          let(:second_stored_session) do
            { 'active_group_sso_sign_ins' => { create(:saml_provider, enforced_sso: true).id => session_time } }
          end

          before do
            Gitlab::Redis::SharedState.with do |redis|
              redis.set("session:gitlab:#{second_session_id}", Marshal.dump(second_stored_session))
              redis.sadd("session:lookup:user:gitlab:#{user.id}", [session_id, second_session_id])
            end
          end

          it { is_expected.to be_falsey }
        end

        context 'with two active sessions for the same provider and one pre-sso', :clean_gitlab_redis_shared_state do
          let(:second_session_id) { '52' }
          let(:third_session_id) { '62' }
          let(:second_stored_session) do
            { 'active_group_sso_sign_ins' => { saml_provider.id => 2.days.ago } }
          end

          before do
            Gitlab::Redis::SharedState.with do |redis|
              redis.set("session:gitlab:#{second_session_id}", Marshal.dump(second_stored_session))
              redis.set("session:gitlab:#{third_session_id}", Marshal.dump({}))
              redis.sadd("session:lookup:user:gitlab:#{user.id}", [session_id, second_session_id, third_session_id])
            end
          end

          it { is_expected.to be_falsey }
        end

        context 'without enforced_sso_expiry feature flag' do
          let(:session_time) { 2.days.ago }

          before do
            stub_feature_flags(enforced_sso_expiry: false)
          end

          it { is_expected.to be_falsey }
        end

        context 'without group' do
          let(:root_group) { nil }

          it { is_expected.to be_falsey }
        end

        context 'without saml_provider' do
          let(:root_group) { create(:group) }

          it { is_expected.to be_falsey }
        end

        context 'with admin', :enable_admin_mode do
          let(:user) { create(:user, :admin) }

          it { is_expected.to be_falsey }
        end

        context 'with auditor' do
          let(:user) { create(:user, :auditor) }

          it { is_expected.to be_falsey }
        end

        context 'with group owner' do
          before do
            root_group.add_owner(user)
          end

          it { is_expected.to be_falsey }
        end
      end

      context 'without any session' do
        it { is_expected.to be_truthy }

        context 'with admin', :enable_admin_mode do
          let(:user) { create(:user, :admin) }

          it { is_expected.to be_falsey }
        end

        context 'with auditor' do
          let(:user) { create(:user, :auditor) }

          it { is_expected.to be_falsey }
        end

        context 'with group owner' do
          before do
            root_group.add_owner(user)
          end

          it { is_expected.to be_falsey }
        end

        context 'with project bot' do
          let(:user) { create(:user, :project_bot) }

          it { is_expected.to be_falsey }
        end
      end
    end

    context 'when git check is not enforced' do
      before do
        allow(saml_provider).to receive(:git_check_enforced?).and_return(false)
      end

      context 'with an active session', :clean_gitlab_redis_shared_state do
        let(:session_id) { '42' }
        let(:stored_session) do
          { 'active_group_sso_sign_ins' => { saml_provider.id => 5.minutes.ago } }
        end

        before do
          Gitlab::Redis::SharedState.with do |redis|
            redis.set("session:gitlab:#{session_id}", Marshal.dump(stored_session))
            redis.sadd("session:lookup:user:gitlab:#{user.id}", [session_id])
          end
        end

        it { is_expected.to be_falsey }
      end

      context 'without any session' do
        it { is_expected.to be_falsey }
      end
    end
  end
end
