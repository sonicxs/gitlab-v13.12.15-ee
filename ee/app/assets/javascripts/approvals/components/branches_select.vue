<script>
import { GlDropdown, GlDropdownItem, GlSearchBoxByType } from '@gitlab/ui';
import { debounce } from 'lodash';
import Api from 'ee/api';
import { __ } from '~/locale';
import { BRANCH_FETCH_DELAY, ANY_BRANCH } from '../constants';

export default {
  components: {
    GlDropdown,
    GlDropdownItem,
    GlSearchBoxByType,
  },
  props: {
    projectId: {
      type: String,
      required: true,
    },
    initRule: {
      type: Object,
      required: false,
      default: null,
    },
    isInvalid: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      branches: [],
      initialLoading: false,
      searching: false,
      searchTerm: '',
      selected: this.initRule?.protectedBranches[0] || ANY_BRANCH,
    };
  },
  computed: {
    dropdownClass() {
      return {
        'gl-w-full': true,
        'gl-dropdown-menu-full-width': true,
        'is-invalid': this.isInvalid,
      };
    },
    dropdownText() {
      return this.selected.name;
    },
  },
  mounted() {
    this.initialLoading = true;
    this.fetchBranches()
      .then(() => {
        this.initialLoading = false;
      })
      .catch(() => {});
  },
  methods: {
    async fetchBranches(term) {
      this.searching = true;
      const excludeAnyBranch = term && !term.toLowerCase().includes('any');

      const branches = await Api.projectProtectedBranches(this.projectId, term);

      this.branches = excludeAnyBranch ? branches : [ANY_BRANCH, ...branches];
      this.searching = false;
    },
    search: debounce(function debouncedSearch() {
      this.fetchBranches(this.searchTerm);
    }, BRANCH_FETCH_DELAY),
    isSelectedBranch(id) {
      return this.selected.id === id;
    },
    onSelect(branch) {
      this.selected = branch;
      this.$emit('input', branch.id);
    },
    branchNameClass(id) {
      return {
        monospace: id !== null,
      };
    },
  },
  i18n: {
    header: __('Select branch'),
  },
};
</script>

<template>
  <gl-dropdown
    :class="dropdownClass"
    :text="dropdownText"
    :loading="initialLoading"
    :header-text="$options.i18n.header"
  >
    <template #header>
      <gl-search-box-by-type v-model="searchTerm" :is-loading="searching" @input="search" />
    </template>
    <gl-dropdown-item
      v-for="branch in branches"
      :key="branch.id"
      :is-check-item="true"
      :is-checked="isSelectedBranch(branch.id)"
      @click="onSelect(branch)"
    >
      <span :class="branchNameClass(branch.id)">{{ branch.name }}</span>
    </gl-dropdown-item>
  </gl-dropdown>
</template>
