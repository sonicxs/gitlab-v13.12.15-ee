<script>
import { GlAlert, GlButton, GlLoadingIcon, GlTab, GlTabs } from '@gitlab/ui';
import * as Sentry from '@sentry/browser';

import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { s__ } from '~/locale';

import { DANGER, INFO } from '../constants';
import getComplianceFrameworkQuery from '../graphql/queries/get_compliance_framework.query.graphql';
import { injectIdIntoEditPath } from '../utils';
import DeleteModal from './delete_modal.vue';
import EmptyState from './list_empty_state.vue';
import ListItem from './list_item.vue';

export default {
  components: {
    DeleteModal,
    EmptyState,
    GlAlert,
    GlButton,
    GlLoadingIcon,
    ListItem,
    GlTab,
    GlTabs,
  },
  props: {
    addFrameworkPath: {
      type: String,
      required: false,
      default: null,
    },
    editFrameworkPath: {
      type: String,
      required: false,
      default: null,
    },
    emptyStateSvgPath: {
      type: String,
      required: true,
    },
    groupPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      markedForDeletion: {},
      deletingFrameworksIds: [],
      complianceFrameworks: [],
      error: '',
      message: '',
    };
  },
  apollo: {
    complianceFrameworks: {
      query: getComplianceFrameworkQuery,
      variables() {
        return {
          fullPath: this.groupPath,
        };
      },
      update(data) {
        const nodes = data.namespace?.complianceFrameworks?.nodes;
        return (
          nodes?.map((framework) => {
            const parsedId = getIdFromGraphQLId(framework.id);

            return {
              ...framework,
              parsedId,
              editPath: injectIdIntoEditPath(this.editFrameworkPath, parsedId),
            };
          }) || []
        );
      },
      error(error) {
        this.error = this.$options.i18n.fetchError;
        Sentry.captureException(error);
      },
    },
  },
  computed: {
    isLoading() {
      return this.$apollo.loading && this.deletingFrameworksIds.length === 0;
    },
    hasLoaded() {
      return !this.isLoading && !this.error;
    },
    frameworksCount() {
      return this.complianceFrameworks.length;
    },
    isEmpty() {
      return this.hasLoaded && this.frameworksCount === 0;
    },
    hasFrameworks() {
      return this.hasLoaded && this.frameworksCount > 0;
    },
    regulatedCount() {
      return 0;
    },
    alertDismissible() {
      return !this.error;
    },
    alertVariant() {
      return this.error ? DANGER : INFO;
    },
    alertMessage() {
      return this.error || this.message;
    },
  },
  methods: {
    dismissAlertMessage() {
      this.message = null;
    },
    markForDeletion(framework) {
      this.markedForDeletion = framework;
      this.$refs.modal.show();
    },
    onError() {
      this.error = this.$options.i18n.deleteError;
    },
    onDelete(id) {
      this.message = this.$options.i18n.deleteMessage;
      const idx = this.deletingFrameworksIds.indexOf(id);
      if (idx > -1) {
        this.deletingFrameworksIds.splice(idx, 1);
      }
    },
    onDeleting() {
      this.deletingFrameworksIds.push(this.markedForDeletion.id);
    },
    isDeleting(id) {
      return this.deletingFrameworksIds.includes(id);
    },
  },
  i18n: {
    deleteMessage: s__('ComplianceFrameworks|Compliance framework deleted successfully'),
    deleteError: s__(
      'ComplianceFrameworks|Error deleting the compliance framework. Please try again',
    ),
    fetchError: s__(
      'ComplianceFrameworks|Error fetching compliance frameworks data. Please refresh the page',
    ),
    allTab: s__('ComplianceFrameworks|All'),
    regulatedTab: s__('ComplianceFrameworks|Regulated'),
    addBtn: s__('ComplianceFrameworks|Add framework'),
  },
};
</script>
<template>
  <div class="gl-border-t-1 gl-border-t-solid gl-border-t-gray-100">
    <gl-alert
      v-if="alertMessage"
      class="gl-mt-5"
      :variant="alertVariant"
      :dismissible="alertDismissible"
      @dismiss="dismissAlertMessage"
    >
      {{ alertMessage }}
    </gl-alert>
    <gl-loading-icon v-if="isLoading" size="lg" class="gl-mt-5" />
    <empty-state
      v-if="isEmpty"
      :image-path="emptyStateSvgPath"
      :add-framework-path="addFrameworkPath"
    />

    <gl-tabs v-if="hasFrameworks">
      <gl-tab class="gl-mt-6" :title="$options.i18n.allTab">
        <list-item
          v-for="framework in complianceFrameworks"
          :key="framework.parsedId"
          :framework="framework"
          :loading="isDeleting(framework.id)"
          @delete="markForDeletion"
        />
      </gl-tab>
      <gl-tab disabled :title="$options.i18n.regulatedTab" />
      <template #tabs-end>
        <gl-button
          v-if="addFrameworkPath"
          class="gl-align-self-center gl-ml-auto"
          category="primary"
          variant="confirm"
          :href="addFrameworkPath"
        >
          {{ $options.i18n.addBtn }}
        </gl-button>
      </template>
    </gl-tabs>
    <delete-modal
      v-if="hasFrameworks"
      :id="markedForDeletion.id"
      ref="modal"
      :name="markedForDeletion.name"
      :group-path="groupPath"
      @deleting="onDeleting"
      @delete="onDelete"
      @error="onError"
    />
  </div>
</template>
