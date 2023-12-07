import { IssuableType } from '~/issue_show/constants';
import { s__, __ } from '~/locale';
import groupIterationsQuery from './queries/group_iterations.query.graphql';
import projectIssueIterationMutation from './queries/project_issue_iteration.mutation.graphql';
import projectIssueIterationQuery from './queries/project_issue_iteration.query.graphql';

export const healthStatus = {
  ON_TRACK: 'onTrack',
  NEEDS_ATTENTION: 'needsAttention',
  AT_RISK: 'atRisk',
};

export const edit = __('Edit');
export const none = __('None');

export const healthStatusTextMap = {
  [healthStatus.ON_TRACK]: __('On track'),
  [healthStatus.NEEDS_ATTENTION]: __('Needs attention'),
  [healthStatus.AT_RISK]: __('At risk'),
};

export const iterationSelectTextMap = {
  iteration: __('Iteration'),
  noIteration: __('No iteration'),
  noIterationItem: [{ title: __('No iteration'), id: null }],
  assignIteration: __('Assign Iteration'),
  iterationSelectFail: __('Failed to set iteration on this issue. Please try again.'),
  currentIterationFetchError: __('Failed to fetch the iteration for this issue. Please try again.'),
  iterationsFetchError: __('Failed to fetch the iterations for the group. Please try again.'),
  noIterationsFound: __('No iterations found'),
};

export const noIteration = null;

export const iterationDisplayState = 'opened';

export const healthStatusForRestApi = {
  NO_STATUS: '0',
  [healthStatus.ON_TRACK]: 'on_track',
  [healthStatus.NEEDS_ATTENTION]: 'needs_attention',
  [healthStatus.AT_RISK]: 'at_risk',
};

export const MAX_DISPLAY_WEIGHT = 99999;

export const I18N_DROPDOWN = {
  dropdownHeaderText: s__('Sidebar|Assign health status'),
  noStatusText: s__('Sidebar|No status'),
  noneText: s__('Sidebar|None'),
  selectPlaceholderText: s__('Select health status'),
};

export const CVE_ID_REQUEST_SIDEBAR_I18N = {
  action: s__('CVE|Request CVE ID'),
  description: s__('CVE|CVE ID Request'),
  createRequest: s__('CVE|Create CVE ID Request'),
  whyRequest: s__('CVE|Why Request a CVE ID?'),
  whyText1: s__(
    'CVE|Common Vulnerability Enumeration (CVE) identifiers are used to track distinct vulnerabilities in specific versions of code.',
  ),
  whyText2: s__(
    'CVE|As a maintainer, requesting a CVE for a vulnerability in your project will help your users stay secure and informed.',
  ),
  learnMore: __('Learn more'),
};

export const issuableIterationQueries = {
  [IssuableType.Issue]: {
    query: projectIssueIterationQuery,
    mutation: projectIssueIterationMutation,
  },
};

export const iterationsQueries = {
  [IssuableType.Issue]: {
    query: groupIterationsQuery,
  },
};
