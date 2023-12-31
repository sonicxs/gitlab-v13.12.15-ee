<script>
import {
  GlEmptyState,
  GlIcon,
  GlLink,
  GlLoadingIcon,
  GlPagination,
  GlTable,
  GlBadge,
} from '@gitlab/ui';
import { __ } from '~/locale';
import {
  NOT_ENOUGH_DATA_ERROR,
  PAGINATION_SORT_FIELD_END_EVENT,
  PAGINATION_SORT_FIELD_DURATION,
  PAGINATION_SORT_DIRECTION_ASC,
  PAGINATION_SORT_DIRECTION_DESC,
} from '../constants';
import TotalTime from './total_time_component.vue';

const DEFAULT_WORKFLOW_TITLE_PROPERTIES = {
  thClass: 'gl-w-half',
  key: PAGINATION_SORT_FIELD_END_EVENT,
  sortable: true,
};
const WORKFLOW_COLUMN_TITLES = {
  issues: { ...DEFAULT_WORKFLOW_TITLE_PROPERTIES, label: __('Issues') },
  jobs: { ...DEFAULT_WORKFLOW_TITLE_PROPERTIES, label: __('Jobs') },
  deployments: { ...DEFAULT_WORKFLOW_TITLE_PROPERTIES, label: __('Deployments') },
  mergeRequests: { ...DEFAULT_WORKFLOW_TITLE_PROPERTIES, label: __('Merge requests') },
};

export default {
  name: 'StageTableNew',
  components: {
    GlEmptyState,
    GlIcon,
    GlLink,
    GlLoadingIcon,
    GlPagination,
    GlTable,
    GlBadge,
    TotalTime,
  },
  props: {
    selectedStage: {
      type: Object,
      required: true,
    },
    isLoading: {
      type: Boolean,
      required: true,
    },
    stageEvents: {
      type: Array,
      required: true,
    },
    stageCount: {
      type: Number,
      required: false,
      default: null,
    },
    noDataSvgPath: {
      type: String,
      required: true,
    },
    emptyStateMessage: {
      type: String,
      required: false,
      default: '',
    },
    pagination: {
      type: Object,
      required: true,
    },
  },
  data() {
    const {
      pagination: { sort, direction },
    } = this;
    return {
      sort,
      sortDesc: direction === PAGINATION_SORT_DIRECTION_DESC,
    };
  },
  computed: {
    isEmptyStage() {
      return !this.stageEvents.length;
    },
    emptyStateTitle() {
      const { emptyStateMessage } = this;
      return emptyStateMessage || NOT_ENOUGH_DATA_ERROR;
    },
    isDefaultTestStage() {
      const { selectedStage } = this;
      return !selectedStage.custom && selectedStage.title?.toLowerCase().trim() === 'test';
    },
    isDefaultStagingStage() {
      const { selectedStage } = this;
      return !selectedStage.custom && selectedStage.title?.toLowerCase().trim() === 'staging';
    },
    isMergeRequestStage() {
      const [firstEvent] = this.stageEvents;
      return this.isMrLink(firstEvent.url);
    },
    workflowTitle() {
      if (this.isDefaultTestStage) {
        return WORKFLOW_COLUMN_TITLES.jobs;
      } else if (this.isDefaultStagingStage) {
        return WORKFLOW_COLUMN_TITLES.deployments;
      } else if (this.isMergeRequestStage) {
        return WORKFLOW_COLUMN_TITLES.mergeRequests;
      }
      return WORKFLOW_COLUMN_TITLES.issues;
    },
    fields() {
      return [
        this.workflowTitle,
        {
          key: PAGINATION_SORT_FIELD_DURATION,
          label: __('Time'),
          thClass: 'gl-w-half',
          sortable: true,
        },
      ];
    },
    prevPage() {
      return Math.max(this.pagination.page - 1, 0);
    },
    nextPage() {
      return this.pagination.hasNextPage ? this.pagination.page + 1 : null;
    },
  },
  methods: {
    isMrLink(url = '') {
      return url.includes('/merge_request');
    },
    itemTitle(item) {
      return item.title || item.name;
    },
    onSelectPage(page) {
      const { sort, direction } = this.pagination;
      this.$emit('handleUpdatePagination', { sort, direction, page });
    },
    onSort({ sortBy, sortDesc }) {
      this.sort = sortBy;
      this.sortDesc = sortDesc;
      this.$emit('handleUpdatePagination', {
        sort: sortBy,
        direction: sortDesc ? PAGINATION_SORT_DIRECTION_DESC : PAGINATION_SORT_DIRECTION_ASC,
      });
    },
  },
};
</script>
<template>
  <div data-testid="vsa-stage-table">
    <gl-loading-icon v-if="isLoading" class="gl-mt-4" size="md" />
    <gl-empty-state v-else-if="isEmptyStage" :title="emptyStateTitle" :svg-path="noDataSvgPath" />
    <gl-table
      v-else
      head-variant="white"
      stacked="lg"
      thead-class="border-bottom"
      show-empty
      :sort-by.sync="sort"
      :sort-direction.sync="pagination.direction"
      :sort-desc.sync="sortDesc"
      :fields="fields"
      :items="stageEvents"
      :empty-text="emptyStateMessage"
      @sort-changed="onSort"
    >
      <template #head(end_event)="data">
        <span>{{ data.label }}</span
        ><gl-badge v-if="stageCount" class="gl-ml-2" size="sm">{{ stageCount }}</gl-badge>
      </template>
      <template #cell(end_event)="{ item }">
        <div data-testid="vsa-stage-event">
          <div v-if="item.id" data-testid="vsa-stage-content">
            <p class="gl-m-0">
              <template v-if="isDefaultTestStage">
                <span
                  class="icon-build-status gl-vertical-align-middle gl-text-green-500"
                  data-testid="vsa-stage-event-build-status"
                >
                  <gl-icon name="status_success" :size="14" />
                </span>
                <gl-link
                  class="gl-text-black-normal item-build-name"
                  data-testid="vsa-stage-event-build-name"
                  :href="item.url"
                >
                  {{ item.name }}
                </gl-link>
                &middot;
              </template>
              <gl-link class="gl-text-black-normal pipeline-id" :href="item.url"
                >#{{ item.id }}</gl-link
              >
              <gl-icon :size="16" name="fork" />
              <gl-link
                v-if="item.branch"
                :href="item.branch.url"
                class="gl-text-black-normal ref-name"
                >{{ item.branch.name }}</gl-link
              >
              <span class="icon-branch gl-text-gray-400">
                <gl-icon name="commit" :size="14" />
              </span>
              <gl-link
                class="commit-sha"
                :href="item.commitUrl"
                data-testid="vsa-stage-event-build-sha"
                >{{ item.shortSha }}</gl-link
              >
            </p>
            <p class="gl-m-0">
              <span v-if="isDefaultTestStage" data-testid="vsa-stage-event-build-status-date">
                <gl-link class="gl-text-black-normal issue-date" :href="item.url">{{
                  item.date
                }}</gl-link>
              </span>
              <span v-else data-testid="vsa-stage-event-build-author-and-date">
                <gl-link class="gl-text-black-normal build-date" :href="item.url">{{
                  item.date
                }}</gl-link>
                {{ s__('ByAuthor|by') }}
                <gl-link
                  class="gl-text-black-normal issue-author-link"
                  :href="item.author.webUrl"
                  >{{ item.author.name }}</gl-link
                >
              </span>
            </p>
          </div>
          <div v-else data-testid="vsa-stage-content">
            <h5 class="gl-font-weight-bold gl-my-1" data-testid="vsa-stage-event-title">
              <gl-link class="gl-text-black-normal" :href="item.url">{{ itemTitle(item) }}</gl-link>
            </h5>
            <p class="gl-m-0">
              <template v-if="isMrLink(item.url)">
                <gl-link class="gl-text-black-normal" :href="item.url">!{{ item.iid }}</gl-link>
              </template>
              <template v-else>
                <gl-link class="gl-text-black-normal" :href="item.url">#{{ item.iid }}</gl-link>
              </template>
              <span class="gl-font-lg">&middot;</span>
              <span data-testid="vsa-stage-event-date">
                {{ s__('OpenedNDaysAgo|Opened') }}
                <gl-link class="gl-text-black-normal" :href="item.url">{{
                  item.createdAt
                }}</gl-link>
              </span>
              <span data-testid="vsa-stage-event-author">
                {{ s__('ByAuthor|by') }}
                <gl-link class="gl-text-black-normal" :href="item.author.webUrl">{{
                  item.author.name
                }}</gl-link>
              </span>
            </p>
          </div>
        </div>
      </template>
      <template #cell(duration)="{ item }">
        <total-time :time="item.totalTime" data-testid="vsa-stage-event-time" />
      </template>
    </gl-table>
    <gl-pagination
      v-if="!isLoading"
      :value="pagination.page"
      :prev-page="prevPage"
      :next-page="nextPage"
      align="center"
      class="gl-mt-3"
      data-testid="vsa-stage-pagination"
      @input="onSelectPage"
    />
  </div>
</template>
