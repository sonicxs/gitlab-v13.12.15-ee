import { isAbsolute, isSafeURL } from '~/lib/utils/url_utility';
import { REGEXES, gidPrefix, uidPrefix } from './constants';

// Get the issue in the format expected by the descendant components of related_issues_block.vue.
export const getFormattedIssue = (issue) => ({
  ...issue,
  reference: `#${issue.iid}`,
  path: issue.web_url,
});

export const getAddRelatedIssueRequestParams = (reference, defaultProjectId) => {
  let issueId = reference;
  let projectId = defaultProjectId;

  // If the reference is an issue number, parse out just the issue number.
  if (REGEXES.ISSUE_FORMAT.test(reference)) {
    [, issueId] = REGEXES.ISSUE_FORMAT.exec(reference);
  }
  // If the reference is an absolute URL and matches the issues URL format, parse out the project and issue.
  else if (isSafeURL(reference) && isAbsolute(reference)) {
    const { pathname } = new URL(reference);

    if (REGEXES.LINK_FORMAT.test(pathname)) {
      [, projectId, issueId] = REGEXES.LINK_FORMAT.exec(pathname);
    }
  }

  return { target_issue_iid: issueId, target_project_id: projectId };
};

export const normalizeGraphQLVulnerability = (vulnerability) => {
  if (!vulnerability) {
    return null;
  }

  const newVulnerability = { ...vulnerability };

  if (vulnerability.id) {
    newVulnerability.id = vulnerability.id.replace(gidPrefix, '');
  }

  if (vulnerability.state) {
    newVulnerability.state = vulnerability.state.toLowerCase();
  }

  ['confirmed', 'resolved', 'dismissed'].forEach((state) => {
    if (vulnerability[`${state}By`]?.id) {
      newVulnerability[`${state}ById`] = vulnerability[`${state}By`].id.replace(uidPrefix, '');
      delete newVulnerability[`${state}By`];
    }
  });

  return newVulnerability;
};
