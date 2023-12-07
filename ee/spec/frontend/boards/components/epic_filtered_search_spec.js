import { shallowMount } from '@vue/test-utils';
import EpicFilteredSearch from 'ee_component/boards/components/epic_filtered_search.vue';
import BoardFilteredSearch from '~/boards/components/board_filtered_search.vue';
import { __ } from '~/locale';
import AuthorToken from '~/vue_shared/components/filtered_search_bar/tokens/author_token.vue';
import LabelToken from '~/vue_shared/components/filtered_search_bar/tokens/label_token.vue';

describe('EpicFilteredSearch', () => {
  let wrapper;
  let store;

  const createComponent = ({ initialFilterParams = {} } = {}) => {
    wrapper = shallowMount(EpicFilteredSearch, {
      provide: { initialFilterParams, fullPath: '' },
      store,
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('default', () => {
    beforeEach(() => {
      createComponent();
    });

    it('finds BoardFilteredSearch', () => {
      expect(wrapper.find(BoardFilteredSearch).exists()).toBe(true);
    });

    it('passes tokens to BoardFilteredSearch', () => {
      const tokens = [
        {
          icon: 'labels',
          title: __('Label'),
          type: 'label_name',
          operators: [
            { value: '=', description: 'is' },
            { value: '!=', description: 'is not' },
          ],
          token: LabelToken,
          unique: false,
          symbol: '~',
          fetchLabels: wrapper.vm.fetchLabels,
        },
        {
          icon: 'pencil',
          title: __('Author'),
          type: 'author_username',
          operators: [
            { value: '=', description: 'is' },
            { value: '!=', description: 'is not' },
          ],
          symbol: '@',
          token: AuthorToken,
          unique: true,
          fetchAuthors: wrapper.vm.fetchAuthors,
        },
      ];
      expect(wrapper.find(BoardFilteredSearch).props('tokens')).toEqual(tokens);
    });
  });
});
