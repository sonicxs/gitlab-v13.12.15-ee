import Vue from 'vue';
import PipelineSecurityDashboard from './components/pipeline_security_dashboard.vue';
import apolloProvider from './graphql/provider';
import createDashboardStore from './store';
import { DASHBOARD_TYPES } from './store/constants';
import { LOADING_VULNERABILITIES_ERROR_CODES } from './store/modules/vulnerabilities/constants';

export default () => {
  const el = document.getElementById('js-security-report-app');

  if (!el) {
    return null;
  }

  const {
    dashboardDocumentation,
    emptyStateSvgPath,
    pipelineId,
    pipelineIid,
    projectId,
    sourceBranch,
    vulnerabilitiesEndpoint,
    emptyStateUnauthorizedSvgPath,
    emptyStateForbiddenSvgPath,
    projectFullPath,
    pipelineJobsPath,
  } = el.dataset;

  const loadingErrorIllustrations = {
    [LOADING_VULNERABILITIES_ERROR_CODES.UNAUTHORIZED]: emptyStateUnauthorizedSvgPath,
    [LOADING_VULNERABILITIES_ERROR_CODES.FORBIDDEN]: emptyStateForbiddenSvgPath,
  };

  return new Vue({
    el,
    apolloProvider,
    store: createDashboardStore({
      dashboardType: DASHBOARD_TYPES.PIPELINE,
    }),
    provide: {
      dashboardType: DASHBOARD_TYPES.PIPELINE,
      projectFullPath,
      dashboardDocumentation,
      emptyStateSvgPath,
      pipeline: {
        id: parseInt(pipelineId, 10),
        iid: parseInt(pipelineIid, 10),
        jobsPath: pipelineJobsPath,
        sourceBranch,
      },
    },
    render(createElement) {
      return createElement(PipelineSecurityDashboard, {
        props: {
          projectId: parseInt(projectId, 10),
          vulnerabilitiesEndpoint,
          loadingErrorIllustrations,
        },
      });
    },
  });
};
