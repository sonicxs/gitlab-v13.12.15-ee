import { shallowMount } from '@vue/test-utils';
import EpicsListEmpty from 'ee/roadmap/components/epics_list_empty.vue';
import { PRESET_TYPES } from 'ee/roadmap/constants';
import {
  getTimeframeForQuartersView,
  getTimeframeForWeeksView,
  getTimeframeForMonthsView,
} from 'ee/roadmap/utils/roadmap_utils';
import { mockTimeframeInitialDate, mockSvgPath } from 'ee_jest/roadmap/mock_data';
import { TEST_HOST } from 'helpers/test_constants';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';

const TEST_EPICS_PATH = '/epics';
const TEST_NEW_EPIC_PATH = '/epics/new';

const mockTimeframeQuarters = getTimeframeForQuartersView(mockTimeframeInitialDate);
const mockTimeframeMonths = getTimeframeForMonthsView(mockTimeframeInitialDate);
const mockTimeframeWeeks = getTimeframeForWeeksView(mockTimeframeInitialDate);

describe('ee/roadmap/components/epics_list_empty.vue', () => {
  let wrapper;

  const createWrapper = ({
    isChildEpics = false,
    hasFiltersApplied = false,
    presetType = PRESET_TYPES.MONTHS,
    timeframeStart = mockTimeframeMonths[0],
    timeframeEnd = mockTimeframeMonths[mockTimeframeMonths.length - 1],
  } = {}) => {
    wrapper = extendedWrapper(
      shallowMount(EpicsListEmpty, {
        propsData: {
          presetType,
          timeframeStart,
          timeframeEnd,
          emptyStateIllustrationPath: mockSvgPath,
          hasFiltersApplied,
          isChildEpics,
        },
        provide: {
          newEpicPath: TEST_NEW_EPIC_PATH,
          listEpicsPath: TEST_EPICS_PATH,
          epicsDocsPath: TEST_HOST,
        },
      }),
    );
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  const findTitle = () => wrapper.findByTestId('title');
  const findSubTitle = () => wrapper.findByTestId('sub-title');
  const findNewEpicButton = () => wrapper.findByTestId('new-epic-button');
  const findListEpicsButton = () => wrapper.findByTestId('list-epics-button');
  const findIllustration = () => wrapper.findByTestId('illustration');

  it('renders default message', () => {
    createWrapper({});

    expect(findTitle().text()).toBe(wrapper.vm.message);
  });

  it('renders empty state message when `hasFiltersApplied` prop is true', () => {
    createWrapper({ hasFiltersApplied: true });

    expect(findTitle().text()).toBe('Sorry, no epics matched your search');
  });

  describe('with presetType `QUARTERS`', () => {
    it('renders default empty state sub-title when `hasFiltersApplied` props is false', () => {
      createWrapper({
        presetType: PRESET_TYPES.QUARTERS,
        timeframeStart: mockTimeframeQuarters[0],
        timeframeEnd: mockTimeframeQuarters[mockTimeframeQuarters.length - 1],
      });

      expect(findSubTitle().text()).toBe(
        'To view the roadmap, add a start or due date to one of your epics in this group or its subgroups; from Jul 1, 2017 to Mar 31, 2019.',
      );
    });

    it('renders empty state sub-title when `hasFiltersApplied` prop is true', () => {
      createWrapper({
        presetType: PRESET_TYPES.QUARTERS,
        timeframeStart: mockTimeframeQuarters[0],
        timeframeEnd: mockTimeframeQuarters[mockTimeframeQuarters.length - 1],
        hasFiltersApplied: true,
      });

      expect(findSubTitle().text()).toBe(
        'To widen your search, change or remove filters; from Jul 1, 2017 to Mar 31, 2019.',
      );
    });
  });

  describe('with presetType `MONTHS`', () => {
    it('renders default empty state sub-title when `hasFiltersApplied` props is false', () => {
      createWrapper({
        presetType: PRESET_TYPES.MONTHS,
      });

      expect(findSubTitle().text()).toBe(
        'To view the roadmap, add a start or due date to one of your epics in this group or its subgroups; from Nov 1, 2017 to Jun 30, 2018.',
      );
    });

    it('renders empty state sub-title when `hasFiltersApplied` prop is true', () => {
      createWrapper({
        presetType: PRESET_TYPES.MONTHS,
        hasFiltersApplied: true,
      });

      expect(findSubTitle().text()).toBe(
        'To widen your search, change or remove filters; from Nov 1, 2017 to Jun 30, 2018.',
      );
    });
  });

  describe('with presetType `WEEKS`', () => {
    let timeframeEnd;

    beforeEach(() => {
      timeframeEnd = mockTimeframeWeeks[mockTimeframeWeeks.length - 1];
      timeframeEnd.setDate(timeframeEnd.getDate() + 6);
    });

    it('renders default empty state sub-title when `hasFiltersApplied` props is false', () => {
      createWrapper({
        presetType: PRESET_TYPES.WEEKS,
        timeframeStart: mockTimeframeWeeks[0],
        timeframeEnd,
      });

      expect(findSubTitle().text()).toBe(
        'To view the roadmap, add a start or due date to one of your epics in this group or its subgroups; from Dec 17, 2017 to Feb 9, 2018.',
      );
    });

    it('renders empty state sub-title when `hasFiltersApplied` prop is true', () => {
      createWrapper({
        presetType: PRESET_TYPES.WEEKS,
        timeframeStart: mockTimeframeWeeks[0],
        timeframeEnd,
        hasFiltersApplied: true,
      });

      expect(findSubTitle().text()).toBe(
        'To widen your search, change or remove filters; from Dec 17, 2017 to Feb 15, 2018.',
      );
    });
  });

  it('renders empty state sub-title when `isChildEpics` is set to `true`', () => {
    createWrapper({ isChildEpics: true });

    expect(findSubTitle().text()).toBe(
      'To view the roadmap, add a start or due date to one of the child epics.',
    );
  });

  it('renders empty state illustration in image element with provided `emptyStateIllustrationPath`', () => {
    createWrapper({});

    expect(findIllustration().attributes('src')).toBe(mockSvgPath);
  });

  it('renders buttons for create and list epics', () => {
    createWrapper({});

    expect(findNewEpicButton().attributes('href')).toBe(TEST_NEW_EPIC_PATH);
    expect(findListEpicsButton().attributes('href')).toBe(TEST_EPICS_PATH);
  });

  it('does not render new epic button element when `hasFiltersApplied` prop is true', () => {
    createWrapper({ hasFiltersApplied: true });

    expect(findNewEpicButton().exists()).toBe(false);
  });
});
