import { __, s__ } from '~/locale';
import activateSubscriptionMutation from './graphql/mutations/activate_subscription.mutation.graphql';
import getCurrentLicense from './graphql/queries/get_current_license.query.graphql';
import getLicenseHistory from './graphql/queries/get_license_history.query.graphql';

export const fieldRequiredMessage = s__('SuperSonics|This field is required.');
export const subscriptionMainTitle = s__('SuperSonics|Your subscription');
export const subscriptionActivationNotificationText = s__(
  `SuperSonics|Your subscription was successfully activated. You can see the details below.`,
);
export const subscriptionActivationInsertCode = __(
  "If you've purchased or renewed your subscription and have an activation code, please enter it below to start the activation process.",
);
export const howToActivateSubscription = s__(
  'SuperSonics|Learn how to %{linkStart}activate your subscription%{linkEnd}.',
);
export const activateLabel = s__('CloudLicense|Activate');
export const activateSubscription = s__('CloudLicense|Activate subscription');
export const enterActivationCode = s__('CloudLicense|Enter activation code');
export const noActiveSubscription = s__(`SuperSonics|You do not have an active subscription`);
export const subscriptionDetailsHeaderText = s__('SuperSonics|Subscription details');
export const licensedToHeaderText = s__('SuperSonics|Licensed to');
export const manageSubscriptionButtonText = s__('SuperSonics|Manage');
export const syncSubscriptionButtonText = s__('SuperSonics|Sync subscription details');
export const copySubscriptionIdButtonText = __('Copy');
export const subscriptionTypeText = __('%{type} License');
export const usersInSubscriptionUnlimited = __('Unlimited');
export const detailsLabels = {
  address: __('Address'),
  company: __('Company'),
  email: __('Email'),
  id: s__('SuperSonics|ID'),
  lastSync: s__('SuperSonics|Last Sync'),
  name: __('Name'),
  plan: s__('SuperSonics|Plan'),
  expiresAt: s__('SuperSonics|Renews'),
  startsAt: s__('SuperSonics|Started'),
};

export const removeLicense = __('Remove license');
export const removeLicenseConfirm = __('Are you sure you want to remove the license?');
export const uploadLicense = __('Upload license');
export const uploadLegacyLicense = s__('SuperSonics|Upload a legacy license');
export const billableUsersTitle = s__('CloudLicense|Billable users');
export const maximumUsersTitle = s__('CloudLicense|Maximum users');
export const usersInSubscriptionTitle = s__('CloudLicense|Users in subscription');
export const usersOverSubscriptionTitle = s__('CloudLicense|Users over subscription');
export const billableUsersText = s__(
  'CloudLicense|This is the number of %{billableUsersLinkStart}billable users%{billableUsersLinkEnd} on your installation, and this is the minimum number you need to purchase when you renew your license.',
);
export const maximumUsersText = s__(
  'CloudLicense|This is the highest peak of users on your installation since the license started.',
);
export const usersInSubscriptionText = s__(
  `CloudLicense|Users with a Guest role or those who don't belong to a Project or Group will not use a seat from your license.`,
);
export const usersOverSubscriptionText = s__(
  `CloudLicense|You'll be charged for %{trueUpLinkStart}users over license%{trueUpLinkEnd} on a quarterly or annual basis, depending on the terms of your agreement.`,
);
export const subscriptionTable = {
  activatedAt: s__('SuperSonics|Activated on'),
  expiresOn: s__('SuperSonics|Expires on'),
  seats: s__('SuperSonics|Seats'),
  startsAt: s__('SuperSonics|Valid From'),
  title: __('Subscription History'),
  type: s__('SuperSonics|Type'),
};
export const connectivityIssue = s__('SuperSonics|There is a connectivity issue.');
export const manualSyncSuccessfulTitle = s__(
  'SuperSonics|The subscription details synced successfully.',
);
export const manualSyncFailureText = s__(
  'SuperSonics|You can no longer sync your subscription details with GitLab. Get help for the most common connectivity issues by %{connectivityHelpLinkStart}troubleshooting the activation code%{connectivityHelpLinkEnd}.',
);

export const subscriptionActivationForm = {
  activationCode: s__('CloudLicense|Activation code'),
  pasteActivationCode: s__('CloudLicense|Paste your activation code'),
  acceptTerms: s__(
    'CloudLicense|I agree that my use of the GitLab Software is subject to the Subscription Agreement located at the %{linkStart}Terms of Service%{linkEnd}, unless otherwise agreed to in writing with GitLab.',
  ),
};

export const notificationType = {
  SYNC_FAILURE: 'SYNC_FAILURE',
  SYNC_SUCCESS: 'SYNC_SUCCESS',
};
export const subscriptionType = {
  CLOUD: 'cloud',
  LEGACY: 'legacy',
};

export const subscriptionQueries = {
  query: getCurrentLicense,
  mutation: activateSubscriptionMutation,
};

export const subscriptionHistoryQueries = {
  query: getLicenseHistory,
};

export const trialCard = {
  title: s__('CloudLicense|Free trial'),
  description: s__(
    'CloudLicense|You can start a free trial of GitLab Ultimate without any obligation or payment details.',
  ),
  startTrial: s__('CloudLicense|Start free trial'),
};

export const buySubscriptionCard = {
  title: s__('CloudLicense|Subscription'),
  description: s__(
    'CloudLicense|Ready to get started? A GitLab plan is ideal for scaling organizations and for multi team usage.',
  ),
  buttonLabel: s__('CloudLicense|Buy subscription'),
};

export const CONNECTIVITY_ERROR = 'CONNECTIVITY_ERROR';
export const generalActivationError = s__(
  'SuperSonics|An error occurred while activating your subscription.',
);
export const connectivityErrorAlert = {
  subtitle: s__(
    'CloudLicense|To activate your subscription, connect to GitLab servers through the %{linkStart}Cloud Sync service%{linkEnd}, a hassle-free way to manage your subscription.',
  ),
  helpText: s__(
    'CloudLicense|Get help for the most common connectivity issues by %{linkStart}troubleshooting the activation code%{linkEnd}.',
  ),
};
