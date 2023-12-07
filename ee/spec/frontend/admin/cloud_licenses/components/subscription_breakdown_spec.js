import { GlCard } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import AxiosMockAdapter from 'axios-mock-adapter';
import { nextTick } from 'vue';
import SubscriptionActivationModal from 'ee/pages/admin/cloud_licenses/components/subscription_activation_modal.vue';
import SubscriptionBreakdown, {
  licensedToFields,
  modalId,
  subscriptionDetailsFields,
} from 'ee/pages/admin/cloud_licenses/components/subscription_breakdown.vue';
import SubscriptionDetailsCard from 'ee/pages/admin/cloud_licenses/components/subscription_details_card.vue';
import SubscriptionDetailsHistory from 'ee/pages/admin/cloud_licenses/components/subscription_details_history.vue';
import SubscriptionDetailsUserInfo from 'ee/pages/admin/cloud_licenses/components/subscription_details_user_info.vue';
import SubscriptionSyncNotifications, {
  SUCCESS_ALERT_DISMISSED_EVENT,
} from 'ee/pages/admin/cloud_licenses/components/subscription_sync_notifications.vue';
import {
  licensedToHeaderText,
  notificationType,
  subscriptionDetailsHeaderText,
  subscriptionType,
} from 'ee/pages/admin/cloud_licenses/constants';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import axios from '~/lib/utils/axios_utils';
import { license, subscriptionHistory } from '../mock_data';

describe('Subscription Breakdown', () => {
  let axiosMock;
  let wrapper;
  let glModalDirective;

  const [, legacyLicense] = subscriptionHistory;
  const connectivityHelpURL = 'connectivity/help/url';
  const customersPortalUrl = 'customers.dot';
  const licenseRemovePath = '/license/remove/';
  const licenseUploadPath = '/license/upload/';
  const subscriptionSyncPath = '/sync/path/';

  const findDetailsCards = () => wrapper.findAllComponents(SubscriptionDetailsCard);
  const findDetailsCardFooter = () => wrapper.find('.gl-card-footer');
  const findDetailsHistory = () => wrapper.findComponent(SubscriptionDetailsHistory);
  const findDetailsUserInfo = () => wrapper.findComponent(SubscriptionDetailsUserInfo);
  const findLicenseUploadAction = () => wrapper.findByTestId('license-upload-action');
  const findLicenseRemoveAction = () => wrapper.findByTestId('license-remove-action');
  const findSubscriptionActivationAction = () =>
    wrapper.findByTestId('subscription-activation-action');
  const findSubscriptionMangeAction = () => wrapper.findByTestId('subscription-manage-action');
  const findSubscriptionSyncAction = () => wrapper.findByTestId('subscription-sync-action');
  const findSubscriptionActivationModal = () => wrapper.findComponent(SubscriptionActivationModal);
  const findSubscriptionSyncNotifications = () =>
    wrapper.findComponent(SubscriptionSyncNotifications);

  const createComponent = ({ props = {}, provide = {}, stubs = {} } = {}) => {
    glModalDirective = jest.fn();
    wrapper = extendedWrapper(
      shallowMount(SubscriptionBreakdown, {
        directives: {
          glModal: {
            bind(_, { value }) {
              glModalDirective(value);
            },
          },
        },
        provide: {
          connectivityHelpURL,
          customersPortalUrl,
          licenseUploadPath,
          licenseRemovePath,
          subscriptionSyncPath,
          ...provide,
        },
        propsData: {
          subscription: license.ULTIMATE,
          subscriptionList: subscriptionHistory,
          ...props,
        },
        stubs,
      }),
    );
  };

  beforeEach(() => {
    axiosMock = new AxiosMockAdapter(axios);
  });

  afterEach(() => {
    axiosMock.restore();
    wrapper.destroy();
  });

  describe('with subscription data', () => {
    beforeEach(() => {
      createComponent();
    });

    it('shows 2 details card', () => {
      expect(findDetailsCards()).toHaveLength(2);
    });

    it('provides the correct props to the cards', () => {
      const props = findDetailsCards().wrappers.map((w) => w.props());

      expect(props).toEqual([
        {
          detailsFields: subscriptionDetailsFields,
          headerText: subscriptionDetailsHeaderText,
          subscription: license.ULTIMATE,
        },
        {
          detailsFields: licensedToFields,
          headerText: licensedToHeaderText,
          subscription: license.ULTIMATE,
        },
      ]);
    });

    it('shows the user info', () => {
      expect(findDetailsUserInfo().exists()).toBe(true);
    });

    it('provides the correct props to the user info component', () => {
      expect(findDetailsUserInfo().props('subscription')).toBe(license.ULTIMATE);
    });

    it('does not show notifications', () => {
      expect(findSubscriptionSyncNotifications().exists()).toBe(false);
    });

    it('shows the subscription details footer', () => {
      createComponent({ stubs: { GlCard, SubscriptionDetailsCard } });

      expect(findDetailsCardFooter().exists()).toBe(true);
    });

    it('shows a button to activate a new subscription', () => {
      createComponent({ stubs: { GlCard, SubscriptionDetailsCard } });

      expect(findSubscriptionActivationAction().exists()).toBe(true);
    });

    it('presents a subscription activation modal', () => {
      expect(findSubscriptionActivationModal().exists()).toBe(true);
    });

    it('passes the correct modal id', () => {
      expect(findSubscriptionActivationModal().attributes('modalid')).toBe(modalId);
    });

    describe('footer buttons', () => {
      it.each`
        url                     | type                       | shouldShow
        ${subscriptionSyncPath} | ${subscriptionType.CLOUD}  | ${true}
        ${subscriptionSyncPath} | ${subscriptionType.LEGACY} | ${false}
        ${''}                   | ${subscriptionType.CLOUD}  | ${false}
        ${''}                   | ${subscriptionType.LEGACY} | ${false}
        ${undefined}            | ${subscriptionType.CLOUD}  | ${false}
        ${undefined}            | ${subscriptionType.LEGACY} | ${false}
      `(
        'with url is $url and type is $type the sync button is shown: $shouldShow',
        ({ url, type, shouldShow }) => {
          const provide = {
            connectivityHelpURL: '',
            customersPortalUrl: '',
            licenseUploadPath: '',
            licenseRemovePath: '',
            subscriptionSyncPath: url,
          };
          const props = { subscription: { ...license.ULTIMATE, type } };
          const stubs = { GlCard, SubscriptionDetailsCard };
          createComponent({ props, provide, stubs });

          expect(findSubscriptionSyncAction().exists()).toBe(shouldShow);
        },
      );

      it.each`
        url                  | type                       | shouldShow
        ${licenseUploadPath} | ${subscriptionType.LEGACY} | ${true}
        ${licenseUploadPath} | ${subscriptionType.CLOUD}  | ${false}
        ${''}                | ${subscriptionType.LEGACY} | ${false}
        ${''}                | ${subscriptionType.CLOUD}  | ${false}
        ${undefined}         | ${subscriptionType.LEGACY} | ${false}
        ${undefined}         | ${subscriptionType.CLOUD}  | ${false}
      `(
        'with url is $url and type is $type the upload button is shown: $shouldShow',
        ({ url, type, shouldShow }) => {
          const provide = {
            connectivityHelpURL: '',
            customersPortalUrl: '',
            licenseRemovePath: '',
            subscriptionSyncPath: '',
            licenseUploadPath: url,
          };
          const props = { subscription: { ...license.ULTIMATE, type } };
          const stubs = { GlCard, SubscriptionDetailsCard };
          createComponent({ props, provide, stubs });

          expect(findLicenseUploadAction().exists()).toBe(shouldShow);
        },
      );

      it.each`
        url                   | shouldShow
        ${customersPortalUrl} | ${true}
        ${''}                 | ${false}
        ${undefined}          | ${false}
      `('with url is $url the manage button is shown: $shouldShow', ({ url, shouldShow }) => {
        const provide = {
          connectivityHelpURL: '',
          licenseUploadPath: '',
          licenseRemovePath: '',
          subscriptionSyncPath: '',
          customersPortalUrl: url,
        };
        const stubs = { GlCard, SubscriptionDetailsCard };
        createComponent({ provide, stubs });

        expect(findSubscriptionMangeAction().exists()).toBe(shouldShow);
      });

      it.each`
        url                  | type                       | shouldShow
        ${licenseRemovePath} | ${subscriptionType.LEGACY} | ${true}
        ${licenseRemovePath} | ${subscriptionType.CLOUD}  | ${false}
        ${''}                | ${subscriptionType.LEGACY} | ${false}
        ${''}                | ${subscriptionType.CLOUD}  | ${false}
        ${undefined}         | ${subscriptionType.LEGACY} | ${false}
        ${undefined}         | ${subscriptionType.CLOUD}  | ${false}
      `(
        'with url is $url and type is $type the remove button is shown: $shouldShow',
        ({ url, type, shouldShow }) => {
          const provide = {
            connectivityHelpURL: '',
            customersPortalUrl: '',
            licenseUploadPath: '',
            subscriptionSyncPath: '',
            licenseRemovePath: url,
          };
          const props = { subscription: { ...license.ULTIMATE, type } };
          const stubs = { GlCard, SubscriptionDetailsCard };
          createComponent({ props, provide, stubs });

          expect(findLicenseRemoveAction().exists()).toBe(shouldShow);
        },
      );
    });

    describe('with a legacy license', () => {
      beforeEach(() => {
        createComponent({
          props: { subscription: legacyLicense },
          stubs: { GlCard, SubscriptionDetailsCard },
        });
      });

      it('does not show a button to sync the subscription', () => {
        expect(findSubscriptionSyncAction().exists()).toBe(false);
      });

      it('shows the subscription details footer', () => {
        expect(findDetailsCardFooter().exists()).toBe(true);
      });

      it('does not show the sync subscription notifications', () => {
        expect(findSubscriptionSyncNotifications().exists()).toBe(false);
      });
    });

    describe('sync a subscription success', () => {
      beforeEach(() => {
        axiosMock.onPost(subscriptionSyncPath).reply(200, { success: true });
        createComponent({ stubs: { GlCard, SubscriptionDetailsCard } });
        findSubscriptionSyncAction().vm.$emit('click');
        return waitForPromises();
      });

      it('shows a success notification', () => {
        expect(findSubscriptionSyncNotifications().props('notification')).toBe(
          notificationType.SYNC_SUCCESS,
        );
      });

      it('dismisses the success notification', async () => {
        findSubscriptionSyncNotifications().vm.$emit(SUCCESS_ALERT_DISMISSED_EVENT);
        await nextTick();

        expect(findSubscriptionSyncNotifications().exists()).toBe(false);
      });
    });

    describe('sync a subscription failure', () => {
      beforeEach(() => {
        axiosMock.onPost(subscriptionSyncPath).reply(422, { success: false });
        createComponent({ stubs: { GlCard, SubscriptionDetailsCard } });
        findSubscriptionSyncAction().vm.$emit('click');
        return waitForPromises();
      });

      it('shows a failure notification', () => {
        expect(findSubscriptionSyncNotifications().props('notification')).toBe(
          notificationType.SYNC_FAILURE,
        );
      });

      it('dismisses the failure notification when retrying to sync', async () => {
        await findSubscriptionSyncAction().vm.$emit('click');

        expect(findSubscriptionSyncNotifications().exists()).toBe(false);
      });
    });
  });

  describe('with subscription history data', () => {
    beforeEach(() => {
      createComponent();
    });

    it('shows the subscription history', () => {
      expect(findDetailsHistory().exists()).toBe(true);
    });

    it('provides the correct props to the subscription history component', () => {
      expect(findDetailsHistory().props('currentSubscriptionId')).toBe(license.ULTIMATE.id);
      expect(findDetailsHistory().props('subscriptionList')).toBe(subscriptionHistory);
    });
  });

  describe('with no subscription data', () => {
    beforeEach(() => {
      createComponent({ props: { subscription: {} } });
    });

    it('does not show user info', () => {
      expect(findDetailsUserInfo().exists()).toBe(false);
    });

    it('does not show details', () => {
      createComponent({ props: { subscription: {}, subscriptionList: [] } });

      expect(findDetailsUserInfo().exists()).toBe(false);
    });

    it('does not show the subscription details footer', () => {
      expect(findDetailsCardFooter().exists()).toBe(false);
    });
  });

  describe('with no subscription history data', () => {
    it('shows the current subscription as the only history item', () => {
      createComponent({ props: { subscriptionList: [] } });

      expect(findDetailsHistory().props('')).toMatchObject({
        currentSubscriptionId: license.ULTIMATE.id,
        subscriptionList: [license.ULTIMATE],
      });
    });
  });

  describe('activating a new subscription', () => {
    it('shows a modal', () => {
      createComponent({ stubs: { GlCard, SubscriptionDetailsCard } });
      findSubscriptionActivationAction().vm.$emit('click');

      expect(glModalDirective).toHaveBeenCalledWith(modalId);
    });
  });
});
