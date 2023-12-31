<script>
import { GlDropdownDivider, GlDropdownItem, GlTruncate } from '@gitlab/ui';
import { union, without, get, set, keyBy } from 'lodash';
import { DEFAULT_SCANNER, SCANNER_ID_PREFIX } from 'ee/security_dashboard/constants';
import { createScannerOption } from '../../helpers';
import FilterBody from './filter_body.vue';
import FilterItem from './filter_item.vue';
import StandardFilter from './standard_filter.vue';

export default {
  components: {
    GlDropdownDivider,
    GlDropdownItem,
    GlTruncate,
    FilterBody,
    FilterItem,
  },
  extends: StandardFilter,
  inject: ['scanners'],
  computed: {
    options() {
      return Object.values(this.groups).flatMap((x) => Object.values(x));
    },
    /**
     * For this computed property, we create an object with the following hierarchy:
     *   {
     *     $vendor: {
     *       $category: {
     *         id: 'used for querystring',
     *         reportType: 'used for GraphQL',
     *         name: 'used for Vue template',
     *         scannerIds: ['used', 'for', 'GraphQL'],
     *       },
     *       $category: { ... }
     *     },
     *     $vendor: {
     *       $category: { ... },
     *       $category: { ... }
     *     }
     *   }
     * The category object is added/removed from selectedOptions when an option is clicked on in the
     * dropdown. It contains the data needed for the GraphQL query and to upate the querystring. The
     * parent keys are used for O(1) lookups so we can assign the entries in the scanners array to
     * the correct category object:
     *
     *   const scanners = [{ vendor: 'GitLab', report_type: 'SAST', id: 123}]
     *   this.groups.GitLab.SAST.scannerIds.push(scanner[0].id)
     *
     * In the template, we use Object.entries() and Object.values() on this computed property to
     * render the hierarchical options.
     */
    groups() {
      const options = keyBy(this.filter.options, 'reportType');
      const groups = { GitLab: options };

      this.scanners.forEach((scanner) => {
        const vendor = scanner.vendor || DEFAULT_SCANNER; // Default to GitLab if there's no vendor.
        const reportType = scanner.report_type;
        const id = `${vendor}.${reportType}`;

        // Create the vendor and report type key if they don't exist.
        if (!get(groups, id)) {
          set(groups, id, createScannerOption(vendor, reportType));
        }

        // Add the scanner ID to the group's report type.
        groups[vendor][reportType].scannerIds.push(scanner.id);
      });

      return groups;
    },
    filterObject() {
      const ids = this.selectedOptions.flatMap((x) => x.scannerIds);
      return { scannerId: ids.map((x) => `${SCANNER_ID_PREFIX}${x}`) };
    },
  },
  methods: {
    toggleGroup(groupName) {
      const options = Object.values(this.groups[groupName]);
      // If every option is selected, de-select all of them. Otherwise, select all of them.
      this.selectedOptions = options.every((option) => this.selectedSet.has(option))
        ? without(this.selectedOptions, ...options)
        : union(this.selectedOptions, options);

      this.updateQuerystring();
    },
  },
};
</script>

<template>
  <filter-body
    :name="filter.name"
    :selected-options="selectedOptionsOrAll"
    :show-search-box="false"
  >
    <filter-item
      v-if="filter.allOption"
      :is-checked="isNoOptionsSelected"
      :text="filter.allOption.name"
      data-testid="all"
      @click="deselectAllOptions"
    />

    <template v-for="[groupName, groupOptions] in Object.entries(groups)">
      <gl-dropdown-divider :key="`${groupName}:divider`" />

      <gl-dropdown-item
        :key="`${groupName}:header`"
        :data-testid="`${groupName}Header`"
        @click.native.capture.stop="toggleGroup(groupName)"
      >
        <gl-truncate class="gl-font-weight-bold" :text="groupName" />
      </gl-dropdown-item>

      <filter-item
        v-for="option in Object.values(groupOptions)"
        :key="option.id"
        :is-checked="isSelected(option)"
        :text="option.name"
        :data-testid="option.id"
        @click="toggleOption(option)"
      />
    </template>
  </filter-body>
</template>
