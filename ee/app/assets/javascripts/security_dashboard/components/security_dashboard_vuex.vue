<script>
import { mapActions, mapState, mapGetters } from 'vuex';
import PipelineArtifactDownload from 'ee/vue_shared/security_reports/components/artifact_downloads/pipeline_artifact_download.vue';
import IssueModal from 'ee/vue_shared/security_reports/components/modal.vue';
import { securityReportTypeEnumToReportType } from 'ee/vue_shared/security_reports/constants';
import { vulnerabilityModalMixin } from 'ee/vue_shared/security_reports/mixins/vulnerability_modal_mixin';
import Filters from './filters.vue';
import LoadingError from './loading_error.vue';
import SecurityDashboardLayout from './security_dashboard_layout.vue';
import SecurityDashboardTable from './security_dashboard_table.vue';

export default {
  components: {
    Filters,
    IssueModal,
    SecurityDashboardLayout,
    SecurityDashboardTable,
    LoadingError,
    PipelineArtifactDownload,
  },
  mixins: [vulnerabilityModalMixin('vulnerabilities')],
  props: {
    vulnerabilitiesEndpoint: {
      type: String,
      required: true,
    },
    projectFullPath: {
      type: String,
      required: true,
    },
    pipelineId: {
      type: Number,
      required: false,
      default: null,
    },
    pipelineIid: {
      type: Number,
      required: false,
      default: null,
    },
    loadingErrorIllustrations: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  computed: {
    ...mapState('vulnerabilities', [
      'modal',
      'pageInfo',
      'loadingVulnerabilitiesErrorCode',
      'isCreatingIssue',
      'isDismissingVulnerability',
      'isCreatingMergeRequest',
    ]),
    ...mapState('pipelineJobs', ['projectId']),
    ...mapState('filters', ['filters']),
    ...mapGetters('vulnerabilities', ['loadingVulnerabilitiesFailedWithRecognizedErrorCode']),
    shouldShowDownloadGuidance() {
      return this.projectFullPath && this.pipelineIid;
    },
    canCreateIssue() {
      const path = this.vulnerability.create_vulnerability_feedback_issue_path;
      return Boolean(path);
    },
    canCreateMergeRequest() {
      const path = this.vulnerability.create_vulnerability_feedback_merge_request_path;
      return Boolean(path);
    },
    canDismissVulnerability() {
      const path = this.vulnerability.create_vulnerability_feedback_dismissal_path;
      return Boolean(path);
    },
    vulnerability() {
      return this.modal.vulnerability;
    },
  },
  created() {
    this.setPipelineId(this.pipelineId);
    this.setVulnerabilitiesEndpoint(this.vulnerabilitiesEndpoint);
    this.fetchPipelineJobs();
  },
  methods: {
    ...mapActions('vulnerabilities', [
      'closeDismissalCommentBox',
      'createIssue',
      'createMergeRequest',
      'openDismissalCommentBox',
      'setPipelineId',
      'setVulnerabilitiesEndpoint',
      'showDismissalDeleteButtons',
      'hideDismissalDeleteButtons',
      'downloadPatch',
    ]),
    ...mapActions('pipelineJobs', ['fetchPipelineJobs']),
    ...mapActions('filters', ['lockFilter', 'setHideDismissedToggleInitialState']),
  },
  reportTypes: {
    COVERAGE_FUZZING: [securityReportTypeEnumToReportType.COVERAGE_FUZZING],
  },
};
</script>

<template>
  <section>
    <loading-error
      v-if="loadingVulnerabilitiesFailedWithRecognizedErrorCode"
      :error-code="loadingVulnerabilitiesErrorCode"
      :illustrations="loadingErrorIllustrations"
    />
    <template v-else>
      <security-dashboard-layout>
        <template #header>
          <filters>
            <template v-if="shouldShowDownloadGuidance" #buttons>
              <pipeline-artifact-download
                class="gl-display-flex gl-flex-direction-column gl-align-self-center"
                :report-types="$options.reportTypes.COVERAGE_FUZZING"
                :target-project-full-path="projectFullPath"
                :pipeline-iid="pipelineIid"
              >
                <template #label>
                  <strong class="gl-mb-2">{{ s__('SecurityReports|Coverage fuzzing') }}</strong>
                </template>
              </pipeline-artifact-download>
            </template>
          </filters>
        </template>

        <security-dashboard-table>
          <template #empty-state>
            <slot name="empty-state"></slot>
          </template>
        </security-dashboard-table>
      </security-dashboard-layout>

      <issue-modal
        :modal="modal"
        :can-create-issue="canCreateIssue"
        :can-create-merge-request="canCreateMergeRequest"
        :can-dismiss-vulnerability="canDismissVulnerability"
        :is-creating-issue="isCreatingIssue"
        :is-dismissing-vulnerability="isDismissingVulnerability"
        :is-creating-merge-request="isCreatingMergeRequest"
        @addDismissalComment="handleAddDismissalComment({ vulnerability, comment: $event })"
        @editVulnerabilityDismissalComment="openDismissalCommentBox"
        @showDismissalDeleteButtons="showDismissalDeleteButtons"
        @hideDismissalDeleteButtons="hideDismissalDeleteButtons"
        @deleteDismissalComment="handleDeleteDismissalComment({ vulnerability })"
        @closeDismissalCommentBox="closeDismissalCommentBox"
        @createMergeRequest="createMergeRequest({ vulnerability })"
        @createNewIssue="createIssue({ vulnerability })"
        @dismissVulnerability="handleDismissVulnerability({ vulnerability, comment: $event })"
        @openDismissalCommentBox="openDismissalCommentBox"
        @revertDismissVulnerability="handleRevertDismissVulnerability({ vulnerability })"
        @downloadPatch="downloadPatch({ vulnerability })"
      />
    </template>
  </section>
</template>
