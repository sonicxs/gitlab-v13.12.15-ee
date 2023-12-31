<script>
import { GlEmptyState } from '@gitlab/ui';
import { mapActions } from 'vuex';
import { fetchPolicies } from '~/lib/graphql';
import { s__ } from '~/locale';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import pipelineSecurityReportSummaryQuery from '../graphql/queries/pipeline_security_report_summary.query.graphql';
import SecurityDashboard from './security_dashboard_vuex.vue';
import SecurityReportsSummary from './security_reports_summary.vue';
import VulnerabilityReport from './vulnerability_report.vue';

export default {
  name: 'PipelineSecurityDashboard',
  components: {
    GlEmptyState,
    SecurityReportsSummary,
    SecurityDashboard,
    VulnerabilityReport,
  },
  mixins: [glFeatureFlagMixin()],
  apollo: {
    securityReportSummary: {
      query: pipelineSecurityReportSummaryQuery,
      fetchPolicy: fetchPolicies.NETWORK_ONLY,
      variables() {
        return {
          fullPath: this.projectFullPath,
          pipelineIid: this.pipeline.iid,
        };
      },
      update(data) {
        const summary = data?.project?.pipeline?.securityReportSummary;
        return summary && Object.keys(summary).length ? summary : null;
      },
    },
  },
  inject: ['projectFullPath', 'pipeline', 'dashboardDocumentation', 'emptyStateSvgPath'],
  props: {
    projectId: {
      type: Number,
      required: true,
    },
    vulnerabilitiesEndpoint: {
      type: String,
      required: true,
    },
    loadingErrorIllustrations: {
      type: Object,
      required: true,
    },
  },
  computed: {
    shouldShowGraphqlVulnerabilityReport() {
      return this.glFeatures.pipelineSecurityDashboardGraphql;
    },
    emptyStateProps() {
      return {
        svgPath: this.emptyStateSvgPath,
        title: s__('SecurityReports|No vulnerabilities found for this pipeline'),
        description: s__(
          `SecurityReports|While it's rare to have no vulnerabilities for your pipeline, it can happen. In any event, we ask that you double check your settings to make sure all security scanning jobs have passed successfully.`,
        ),
        primaryButtonLink: this.dashboardDocumentation,
        primaryButtonText: s__('SecurityReports|Learn more about setting up your dashboard'),
      };
    },
  },
  created() {
    this.setSourceBranch(this.pipeline.sourceBranch);
    this.setPipelineJobsPath(this.pipeline.jobsPath);
    this.setProjectId(this.projectId);
  },
  methods: {
    ...mapActions('vulnerabilities', ['setSourceBranch']),
    ...mapActions('pipelineJobs', ['setPipelineJobsPath', 'setProjectId']),
  },
};
</script>

<template>
  <div>
    <security-reports-summary
      v-if="securityReportSummary"
      :summary="securityReportSummary"
      class="gl-my-5"
    />
    <security-dashboard
      v-if="!shouldShowGraphqlVulnerabilityReport"
      :vulnerabilities-endpoint="vulnerabilitiesEndpoint"
      :lock-to-project="{ id: projectId }"
      :pipeline-id="pipeline.id"
      :pipeline-iid="pipeline.iid"
      :project-full-path="projectFullPath"
      :loading-error-illustrations="loadingErrorIllustrations"
      :security-report-summary="securityReportSummary"
    >
      <template #empty-state>
        <gl-empty-state v-bind="emptyStateProps" />
      </template>
    </security-dashboard>
    <vulnerability-report v-else />
  </div>
</template>
