<script>
import { GlAlert } from '@gitlab/ui';
import { mapState, mapMutations } from 'vuex';
import { scrollToElement } from '~/lib/utils/common_utils';
import { HIDE_ERROR } from '../store/mutation_types';
import FilterSortContainer from './filter_sort/filter_sort_container.vue';
import MembersTable from './table/members_table.vue';

export default {
  name: 'MembersApp',
  components: { MembersTable, FilterSortContainer, GlAlert },
  inject: ['namespace'],
  computed: {
    ...mapState({
      showError(state) {
        return state[this.namespace].showError;
      },
      errorMessage(state) {
        return state[this.namespace].errorMessage;
      },
    }),
  },
  watch: {
    showError(value) {
      if (value) {
        this.$nextTick(() => {
          scrollToElement(this.$refs.errorAlert.$el);
        });
      }
    },
  },
  methods: {
    ...mapMutations({
      hideError(commit) {
        return commit(`${this.namespace}/${HIDE_ERROR}`);
      },
    }),
  },
};
</script>

<template>
  <div>
    <gl-alert v-if="showError" ref="errorAlert" variant="danger" @dismiss="hideError">{{
      errorMessage
    }}</gl-alert>
    <filter-sort-container />
    <members-table />
  </div>
</template>
