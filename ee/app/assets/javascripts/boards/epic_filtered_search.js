import Vue from 'vue';
import EpicFilteredSearch from 'ee_component/boards/components/epic_filtered_search.vue';
import store from '~/boards/stores';
import { urlParamsToObject, convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';

export default (apolloProvider) => {
  const el = document.getElementById('js-board-filtered-search');
  const rawFilterParams = urlParamsToObject(window.location.search);
  const initialFilterParams = {
    ...convertObjectPropsToCamelCase(rawFilterParams, {}),
  };
  const { fullPath } = el.dataset;
  if (!el) {
    return null;
  }

  return new Vue({
    el,
    provide: {
      initialFilterParams,
      fullPath,
    },
    store, // TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/324094
    apolloProvider,
    render: (createElement) => createElement(EpicFilteredSearch),
  });
};
