<script>
/* eslint-disable vue/require-default-prop, vue/no-v-html */
import highlight from '~/lib/utils/highlight';
import { truncateNamespace } from '~/lib/utils/text_utility';
import { mapVuexModuleState } from '~/lib/utils/vuex_module_mappers';
import Tracking from '~/tracking';
import Identicon from '~/vue_shared/components/identicon.vue';

const trackingMixin = Tracking.mixin();

export default {
  components: {
    Identicon,
  },
  mixins: [trackingMixin],
  inject: ['vuexModule'],
  props: {
    matcher: {
      type: String,
      required: false,
    },
    itemId: {
      type: Number,
      required: true,
    },
    itemName: {
      type: String,
      required: true,
    },
    namespace: {
      type: String,
      required: false,
    },
    webUrl: {
      type: String,
      required: true,
    },
    avatarUrl: {
      required: true,
      validator(value) {
        return value === null || typeof value === 'string';
      },
    },
  },
  computed: {
    ...mapVuexModuleState((vm) => vm.vuexModule, ['dropdownType']),
    truncatedNamespace() {
      return truncateNamespace(this.namespace);
    },
    highlightedItemName() {
      return highlight(this.itemName, this.matcher);
    },
  },
};
</script>

<template>
  <li class="frequent-items-list-item-container">
    <a
      :href="webUrl"
      class="clearfix"
      @click="track('click_link', { label: `${dropdownType}_dropdown_frequent_items_list_item` })"
    >
      <div
        ref="frequentItemsItemAvatarContainer"
        class="frequent-items-item-avatar-container avatar-container rect-avatar s32"
      >
        <img v-if="avatarUrl" ref="frequentItemsItemAvatar" :src="avatarUrl" class="avatar s32" />
        <identicon
          v-else
          :entity-id="itemId"
          :entity-name="itemName"
          size-class="s32"
          class="rect-avatar"
        />
      </div>
      <div ref="frequentItemsItemMetadataContainer" class="frequent-items-item-metadata-container">
        <div
          ref="frequentItemsItemTitle"
          :title="itemName"
          class="frequent-items-item-title"
          v-html="highlightedItemName"
        ></div>
        <div
          v-if="namespace"
          ref="frequentItemsItemNamespace"
          :title="namespace"
          class="frequent-items-item-namespace"
        >
          {{ truncatedNamespace }}
        </div>
      </div>
    </a>
  </li>
</template>
