import { GlDropdownItem } from '@gitlab/ui';
import { createLocalVue, shallowMount } from '@vue/test-utils';
import { sampleSize, cloneDeep } from 'lodash';
import VueRouter from 'vue-router';
import FilterItem from 'ee/security_dashboard/components/filters/filter_item.vue';
import ScannerFilter from 'ee/security_dashboard/components/filters/scanner_filter.vue';
import { DEFAULT_SCANNER, SCANNER_ID_PREFIX } from 'ee/security_dashboard/constants';
import { scannerFilter } from 'ee/security_dashboard/helpers';

const localVue = createLocalVue();
localVue.use(VueRouter);
const router = new VueRouter();

const createScannerConfig = (vendor, reportType, id) => ({
  vendor,
  report_type: reportType,
  id,
});

const scanners = [
  createScannerConfig(DEFAULT_SCANNER, 'DEPENDENCY_SCANNING', 1),
  createScannerConfig(DEFAULT_SCANNER, 'DEPENDENCY_SCANNING', 2),
  createScannerConfig(DEFAULT_SCANNER, 'SAST', 3),
  createScannerConfig(DEFAULT_SCANNER, 'SAST', 4),
  createScannerConfig(DEFAULT_SCANNER, 'SECRET_DETECTION', 5),
  createScannerConfig(DEFAULT_SCANNER, 'CONTAINER_SCANNING', 6),
  createScannerConfig(DEFAULT_SCANNER, 'COVERAGE_FUZZING', 7),
  createScannerConfig(DEFAULT_SCANNER, 'DAST', 8),
  createScannerConfig(DEFAULT_SCANNER, 'DAST', 9),
  createScannerConfig('Custom', 'SAST', 10),
  createScannerConfig('Custom', 'SAST', 11),
  createScannerConfig('Custom', 'DAST', 12),
];

describe('Scanner Filter component', () => {
  let wrapper;
  let filter;

  const createWrapper = () => {
    filter = cloneDeep(scannerFilter);

    wrapper = shallowMount(ScannerFilter, {
      localVue,
      router,
      propsData: { filter },
      provide: { scanners },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    // Clear out the querystring if one exists, it persists between tests.
    if (router.currentRoute.query[filter.id]) {
      router.replace('/');
    }
  });

  it('shows the correct dropdown items', () => {
    createWrapper();
    const getTestIds = (selector) =>
      wrapper.findAll(selector).wrappers.map((x) => x.attributes('data-testid'));

    const options = getTestIds(FilterItem);
    const expectedOptions = [
      'all',
      ...filter.options.map((x) => x.id),
      'Custom.SAST',
      'Custom.DAST',
    ];

    const headers = getTestIds(GlDropdownItem);
    const expectedHeaders = ['GitLabHeader', 'CustomHeader'];

    expect(options).toEqual(expectedOptions);
    expect(headers).toEqual(expectedHeaders);
  });

  it('toggles selection of all items in a group when the group header is clicked', async () => {
    createWrapper();
    const expectSelectedItems = (items) => {
      const checkedItems = wrapper
        .findAll(FilterItem)
        .wrappers.filter((x) => x.props('isChecked'))
        .map((x) => x.attributes('data-testid'));
      const expectedItems = items.map((x) => x.id);

      expect(checkedItems.sort()).toEqual(expectedItems.sort());
    };

    const clickAndCheck = async (expectedOptions) => {
      await wrapper.find('[data-testid="GitLabHeader"]').trigger('click');

      expectSelectedItems(expectedOptions);
    };

    const selectedOptions = sampleSize(filter.options, 3); // Randomly select some options.
    await wrapper.setData({ selectedOptions });

    expectSelectedItems(selectedOptions);

    await clickAndCheck(filter.options); // First click selects all.
    await clickAndCheck([filter.allOption]); // Second check unselects all.
    await clickAndCheck(filter.options); // Third click selects all again.
  });

  it('emits filter-changed event with expected data for selected options', async () => {
    const ids = ['GitLab.SAST', 'Custom.SAST'];
    router.replace({ query: { [scannerFilter.id]: ids } });
    const selectedScanners = scanners.filter((x) => ids.includes(`${x.vendor}.${x.report_type}`));
    createWrapper();
    await wrapper.vm.$nextTick();

    expect(wrapper.emitted('filter-changed')[0][0]).toEqual({
      scannerId: selectedScanners.map((x) => `${SCANNER_ID_PREFIX}${x.id}`),
    });
  });
});
