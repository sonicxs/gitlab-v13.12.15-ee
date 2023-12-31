<script>
import { GlAlert, GlIntersectionObserver, GlLoadingIcon } from '@gitlab/ui';
import { produce } from 'immer';
import findingsQuery from '../graphql/queries/pipeline_findings.query.graphql';
import { preparePageInfo } from '../helpers';
import { VULNERABILITIES_PER_PAGE } from '../store/constants';
import VulnerabilityList from './vulnerability_list.vue';

export default {
  name: 'PipelineFindings',
  components: {
    GlAlert,
    GlIntersectionObserver,
    GlLoadingIcon,
    VulnerabilityList,
  },
  inject: ['pipeline', 'projectFullPath'],
  props: {
    filters: {
      type: Object,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      pageInfo: {},
      findings: [],
      errorLoadingFindings: false,
      sortBy: 'severity',
      sortDirection: 'desc',
    };
  },
  computed: {
    isLoadingQuery() {
      return this.$apollo.queries.findings.loading;
    },
    isLoadingFirstResult() {
      return this.isLoadingQuery && this.findings.length === 0;
    },
    sort() {
      return `${this.sortBy}_${this.sortDirection}`;
    },
  },
  apollo: {
    findings: {
      query: findingsQuery,
      variables() {
        return {
          pipelineId: this.pipeline.iid,
          fullPath: this.projectFullPath,
          first: VULNERABILITIES_PER_PAGE,
        };
      },
      update: ({ project }) =>
        project?.pipeline?.securityReportFindings?.nodes?.map((finding) => ({
          ...finding,
          // vulnerabilties and findings are different but similar entities. Vulnerabilities have
          // ids, findings have uuid. To make the selection work with the vulnerability list, we're
          // going to massage the data and add an `id` field to the finding.
          id: finding.uuid,
        })),
      result({ data }) {
        this.pageInfo = preparePageInfo(data.project?.pipeline?.securityReportFindings?.pageInfo);
      },
      error() {
        this.errorLoadingFindings = true;
      },
      skip() {
        return !this.filters;
      },
    },
  },
  watch: {
    filters() {
      // Clear out the existing vulnerabilities so that the skeleton loader is shown.
      this.findings = [];
      this.pageInfo = {};
    },
    sort() {
      // Clear out the existing vulnerabilities so that the skeleton loader is shown.
      this.findings = [];
    },
  },
  methods: {
    onErrorDismiss() {
      this.errorLoadingFindings = false;
    },
    fetchNextPage() {
      if (this.pageInfo.hasNextPage) {
        this.$apollo.queries.findings.fetchMore({
          variables: { after: this.pageInfo.endCursor },
          updateQuery: (previousResult, { fetchMoreResult }) => {
            return produce(fetchMoreResult, (draftData) => {
              draftData.project.pipeline.securityReportFindings.nodes = [
                ...previousResult.project.pipeline.securityReportFindings.nodes,
                ...draftData.project.pipeline.securityReportFindings.nodes,
              ];
            });
          },
        });
      }
    },
    handleSortChange({ sortBy, sortDesc }) {
      this.sortDirection = sortDesc ? 'desc' : 'asc';
      this.sortBy = sortBy;
    },
  },
};
</script>

<template>
  <div>
    <gl-alert
      v-if="errorLoadingFindings"
      class="gl-mb-6"
      variant="danger"
      @dismiss="onErrorDismiss"
    >
      {{
        s__(
          'SecurityReports|Error fetching the vulnerability list. Please check your network connection and try again.',
        )
      }}
    </gl-alert>
    <vulnerability-list
      v-else
      :filters="filters"
      :is-loading="isLoadingFirstResult"
      :vulnerabilities="findings"
      @sort-changed="handleSortChange"
    />
    <gl-intersection-observer
      v-if="pageInfo.hasNextPage"
      class="gl-text-center"
      @appear="fetchNextPage"
    >
      <gl-loading-icon v-if="isLoadingQuery" size="md" />
    </gl-intersection-observer>
  </div>
</template>
