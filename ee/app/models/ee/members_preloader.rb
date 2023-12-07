# frozen_string_literal: true

module EE
  module MembersPreloader
    extend ::Gitlab::Utils::Override

    override :preload_all
    def preload_all
      super

      ActiveRecord::Associations::Preloader.new.preload(members, user: { group_saml_identities: :saml_provider })
      ActiveRecord::Associations::Preloader.new.preload(members, user: { oncall_participants: { rotation: :schedule } })
      ActiveRecord::Associations::Preloader.new.preload(members, user: :oncall_schedules)
    end
  end
end
