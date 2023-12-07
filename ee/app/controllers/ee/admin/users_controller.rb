# frozen_string_literal: true

# rubocop:disable Gitlab/ModuleWithInstanceVariables
module EE
  module Admin
    module UsersController
      extend ::Gitlab::Utils::Override

      def reset_runners_minutes
        user

        if ClearNamespaceSharedRunnersMinutesService.new(@user.namespace).execute
          redirect_to [:admin, @user], notice: _('User pipeline minutes were successfully reset.')
        else
          flash.now[:error] = _('There was an error resetting user pipeline minutes.')
          render "edit"
        end
      end

      private

      override :users_with_included_associations
      def users_with_included_associations(users)
        super.includes(:oncall_schedules) # rubocop: disable CodeReuse/ActiveRecord
      end

      override :log_impersonation_event
      def log_impersonation_event
        super

        log_audit_event
      end

      def log_audit_event
        EE::AuditEvents::ImpersonationAuditEventService.new(current_user, request.remote_ip, 'Started Impersonation')
          .for_user(full_path: user.username, entity_id: user.id).security_event
      end

      def allowed_user_params
        super + [
          namespace_attributes: [
            :id,
            :shared_runners_minutes_limit,
            gitlab_subscription_attributes: [:hosted_plan_id]
          ]
        ]
      end
    end
  end
end
