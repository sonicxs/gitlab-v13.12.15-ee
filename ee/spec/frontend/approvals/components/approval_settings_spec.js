import { GlButton, GlForm } from '@gitlab/ui';
import { createLocalVue, shallowMount } from '@vue/test-utils';
import Vuex from 'vuex';

import ApprovalSettings from 'ee/approvals/components/approval_settings.vue';
import { APPROVAL_SETTINGS_I18N } from 'ee/approvals/constants';
import { createStoreOptions } from 'ee/approvals/stores';
import groupSettingsModule from 'ee/approvals/stores/modules/group_settings';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('ApprovalSettings', () => {
  let wrapper;
  let store;
  let actions;

  const approvalSettingsPath = 'groups/22/merge_request_approval_settings';

  const createWrapper = () => {
    wrapper = extendedWrapper(
      shallowMount(ApprovalSettings, {
        localVue,
        store: new Vuex.Store(store),
        propsData: { approvalSettingsPath },
      }),
    );
  };

  const findForm = () => wrapper.findComponent(GlForm);
  const findSaveButton = () => wrapper.findComponent(GlButton);

  beforeEach(() => {
    store = createStoreOptions(groupSettingsModule());

    actions = store.modules.approvals.actions;
    jest.spyOn(actions, 'fetchSettings').mockImplementation();
    jest.spyOn(actions, 'updateSettings').mockImplementation();
  });

  afterEach(() => {
    wrapper.destroy();
    store = null;
  });

  it('fetches settings from API', () => {
    createWrapper();

    expect(actions.fetchSettings).toHaveBeenCalledWith(expect.any(Object), approvalSettingsPath);
  });

  describe.each`
    testid                             | setting                        | labelKey                            | anchor
    ${'prevent-author-approval'}       | ${'preventAuthorApproval'}     | ${'authorApprovalLabel'}            | ${'allowing-merge-request-authors-to-approve-their-own-merge-requests'}
    ${'prevent-committers-approval'}   | ${'preventCommittersApproval'} | ${'preventCommittersApprovalLabel'} | ${'prevent-approval-of-merge-requests-by-their-committers'}
    ${'prevent-mr-approval-rule-edit'} | ${'preventMrApprovalRuleEdit'} | ${'preventMrApprovalRuleEditLabel'} | ${'editing--overriding-approval-rules-per-merge-request'}
    ${'require-user-password'}         | ${'requireUserPassword'}       | ${'requireUserPasswordLabel'}       | ${'require-authentication-when-approving-a-merge-request'}
    ${'remove-approvals-on-push'}      | ${'removeApprovalsOnPush'}     | ${'removeApprovalsOnPushLabel'}     | ${'resetting-approvals-on-push'}
  `('with $testid checkbox', ({ testid, setting, labelKey, anchor }) => {
    let checkbox = null;

    beforeEach(() => {
      store.modules.approvals.state.settings[setting] = false;
      createWrapper();
      checkbox = wrapper.findByTestId(testid);
    });

    afterEach(() => {
      checkbox = null;
    });

    it('renders', () => {
      expect(checkbox.exists()).toBe(true);
    });

    it('has the anchor and label props', () => {
      expect(checkbox.props()).toMatchObject({
        anchor,
        label: APPROVAL_SETTINGS_I18N[labelKey],
      });
    });

    it('updates the store when the value is changed', async () => {
      await checkbox.vm.$emit('input', true);

      expect(store.modules.approvals.state.settings[setting]).toBe(true);
    });
  });

  describe('loading', () => {
    it('renders enabled button when not loading', () => {
      store.modules.approvals.state.isLoading = false;

      createWrapper();

      expect(findSaveButton().props('disabled')).toBe(false);
    });

    it('renders disabled button when loading', () => {
      store.modules.approvals.state.isLoading = true;

      createWrapper();

      expect(findSaveButton().props('disabled')).toBe(true);
    });
  });

  describe('form submission', () => {
    it('update settings via API', async () => {
      createWrapper();

      await findForm().vm.$emit('submit', { preventDefault: () => {} });

      expect(actions.updateSettings).toHaveBeenCalledWith(expect.any(Object), approvalSettingsPath);
    });
  });
});
