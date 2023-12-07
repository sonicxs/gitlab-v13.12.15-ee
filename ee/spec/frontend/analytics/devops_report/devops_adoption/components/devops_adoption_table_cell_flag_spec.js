import { shallowMount } from '@vue/test-utils';
import DevopsAdoptionTableCellFlag from 'ee/analytics/devops_report/devops_adoption/components/devops_adoption_table_cell_flag.vue';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';

describe('DevopsAdoptionTableCellFlag', () => {
  let wrapper;

  const createComponent = (props) => {
    wrapper = shallowMount(DevopsAdoptionTableCellFlag, {
      propsData: {
        enabled: true,
        ...props,
      },
      directives: {
        GlTooltip: createMockDirective(),
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('enabled', () => {
    beforeEach(() => createComponent());

    it('contains the circle-enabled class', () => {
      expect(wrapper.classes()).toContain('circle');
      expect(wrapper.classes()).toContain('circle-enabled');
    });

    it('contains a tooltip', () => {
      const tooltip = getBinding(wrapper.element, 'gl-tooltip');

      expect(tooltip).toBeDefined();
      expect(tooltip.value).toBe('Adopted');
    });
  });

  describe('disabled', () => {
    beforeEach(() => createComponent({ enabled: false }));

    it('does not contain the circle-enabled class', () => {
      expect(wrapper.classes()).toContain('circle');
      expect(wrapper.classes()).not.toContain('circle-enabled');
    });

    it('contains a tooltip', () => {
      const tooltip = getBinding(wrapper.element, 'gl-tooltip');

      expect(tooltip).toBeDefined();
      expect(tooltip.value).toBe('Not adopted');
    });
  });
});
