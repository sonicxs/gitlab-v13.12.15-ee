<script>
import { GlButton, GlModalDirective } from '@gitlab/ui';
import axios from '~/lib/utils/axios_utils';
import {
  enterActivationCode,
  licensedToHeaderText,
  manageSubscriptionButtonText,
  notificationType,
  removeLicense,
  removeLicenseConfirm,
  subscriptionDetailsHeaderText,
  subscriptionType,
  syncSubscriptionButtonText,
  uploadLicense,
} from '../constants';
import SubscriptionActivationModal from './subscription_activation_modal.vue';
import SubscriptionDetailsCard from './subscription_details_card.vue';
import SubscriptionDetailsHistory from './subscription_details_history.vue';
import SubscriptionDetailsUserInfo from './subscription_details_user_info.vue';

export const subscriptionDetailsFields = ['id', 'plan', 'expiresAt', 'lastSync', 'startsAt'];
export const licensedToFields = ['name', 'email', 'company'];
export const modalId = 'subscription-activation-modal';

export default {
  i18n: {
    enterActivationCode,
    licensedToHeaderText,
    manageSubscriptionButtonText,
    removeLicense,
    removeLicenseConfirm,
    subscriptionDetailsHeaderText,
    syncSubscriptionButtonText,
    uploadLicense,
  },
  modal: {
    id: modalId,
  },
  name: 'SubscriptionBreakdown',
  directives: {
    GlModal: GlModalDirective,
  },
  components: {
    GlButton,
    SubscriptionActivationModal,
    SubscriptionDetailsCard,
    SubscriptionDetailsHistory,
    SubscriptionDetailsUserInfo,
    SubscriptionSyncNotifications: () => import('./subscription_sync_notifications.vue'),
  },
  inject: ['customersPortalUrl', 'licenseRemovePath', 'licenseUploadPath', 'subscriptionSyncPath'],
  props: {
    subscription: {
      type: Object,
      required: true,
    },
    subscriptionList: {
      type: Array,
      required: true,
    },
  },
  data() {
    return {
      hasAsyncActivity: false,
      licensedToFields,
      notification: null,
      subscriptionDetailsFields,
    };
  },
  computed: {
    canManageSubscription() {
      return this.customersPortalUrl && this.hasSubscription;
    },
    canSyncSubscription() {
      return this.subscriptionSyncPath && this.isCloudType;
    },
    canUploadLicense() {
      return this.licenseUploadPath && this.isLegacyType;
    },
    canRemoveLicense() {
      return this.licenseRemovePath && this.isLegacyType;
    },
    hasSubscription() {
      return Boolean(Object.keys(this.subscription).length);
    },
    hasSubscriptionHistory() {
      return Boolean(this.subscriptionList.length);
    },
    isCloudType() {
      return this.subscription.type === subscriptionType.CLOUD;
    },
    isLegacyType() {
      return this.subscription.type === subscriptionType.LEGACY;
    },
    shouldShowFooter() {
      return (
        this.canRemoveLicense ||
        this.canManageSubscription ||
        this.canSyncSubscription ||
        this.canUploadLicense
      );
    },
    subscriptionHistory() {
      return this.hasSubscriptionHistory ? this.subscriptionList : [this.subscription];
    },
  },
  methods: {
    didDismissSuccessAlert() {
      this.notification = null;
    },
    syncSubscription() {
      this.hasAsyncActivity = true;
      this.notification = null;
      axios
        .post(this.subscriptionSyncPath)
        .then(() => {
          this.notification = notificationType.SYNC_SUCCESS;
        })
        .catch(() => {
          this.notification = notificationType.SYNC_FAILURE;
        })
        .finally(() => {
          this.hasAsyncActivity = false;
        });
    },
  },
};
</script>

<template>
  <div>
    <subscription-activation-modal v-if="hasSubscription" :modal-id="$options.modal.id" />
    <subscription-sync-notifications
      v-if="notification"
      class="mb-4"
      :notification="notification"
      @success-alert-dismissed="didDismissSuccessAlert"
    />
    <section class="row gl-mb-5">
      <div class="col-md-6 gl-mb-5">
        <subscription-details-card
          :details-fields="subscriptionDetailsFields"
          :header-text="$options.i18n.subscriptionDetailsHeaderText"
          :subscription="subscription"
        >
          <template v-if="shouldShowFooter" #footer>
            <gl-button
              v-if="canSyncSubscription"
              category="primary"
              :loading="hasAsyncActivity"
              variant="confirm"
              data-testid="subscription-sync-action"
              @click="syncSubscription"
            >
              {{ $options.i18n.syncSubscriptionButtonText }}
            </gl-button>
            <gl-button
              v-if="hasSubscription"
              v-gl-modal="$options.modal.id"
              category="primary"
              variant="confirm"
              data-testid="subscription-activation-action"
            >
              {{ $options.i18n.enterActivationCode }}
            </gl-button>
            <gl-button
              v-if="canUploadLicense"
              :href="licenseUploadPath"
              category="secondary"
              variant="confirm"
              data-testid="license-upload-action"
              data-qa-selector="license_upload_link"
            >
              {{ $options.i18n.uploadLicense }}
            </gl-button>
            <gl-button
              v-if="canManageSubscription"
              :href="customersPortalUrl"
              target="_blank"
              category="secondary"
              variant="confirm"
              data-testid="subscription-manage-action"
            >
              {{ $options.i18n.manageSubscriptionButtonText }}
            </gl-button>
            <gl-button
              v-if="canRemoveLicense"
              category="secondary"
              variant="danger"
              :href="licenseRemovePath"
              :data-confirm="$options.i18n.removeLicenseConfirm"
              data-method="delete"
              data-testid="license-remove-action"
              data-qa-selector="remove_license_link"
            >
              {{ $options.i18n.removeLicense }}
            </gl-button>
          </template>
        </subscription-details-card>
      </div>

      <div class="col-md-6 gl-mb-5">
        <subscription-details-card
          :details-fields="licensedToFields"
          :header-text="$options.i18n.licensedToHeaderText"
          :subscription="subscription"
        />
      </div>
    </section>
    <subscription-details-user-info v-if="hasSubscription" :subscription="subscription" />
    <subscription-details-history
      v-if="hasSubscription"
      :current-subscription-id="subscription.id"
      :subscription-list="subscriptionHistory"
    />
  </div>
</template>
