import { shallowMount } from '@vue/test-utils';
import SecurityDashboardLayout from 'ee/security_dashboard/components/security_dashboard_layout.vue';

describe('Security Dashboard Layout component', () => {
  let wrapper;
  const SMALLER_SECTION_CLASS = 'col-xl-7';
  const STICKY_SECTION_SELECTOR = '[data-testid="sticky-section"]';

  const DummyComponent = {
    name: 'dummy-component',
    template: '<p>dummy component</p>',
  };

  const createWrapper = (slots) => {
    wrapper = shallowMount(SecurityDashboardLayout, { slots });
  };

  const findArticle = () => wrapper.find('article');
  const findHeader = () => wrapper.find('header');
  const findAside = () => wrapper.find('aside');
  const findStickySection = () => wrapper.find(STICKY_SECTION_SELECTOR);

  afterEach(() => {
    wrapper.destroy();
  });

  describe('with the main slot only', () => {
    beforeEach(() => {
      createWrapper({
        default: DummyComponent,
      });
    });

    it.each`
      element                    | exists
      ${'article'}               | ${true}
      ${'header'}                | ${false}
      ${'aside'}                 | ${false}
      ${STICKY_SECTION_SELECTOR} | ${false}
    `('should find that $element exists is $exists', ({ element, exists }) => {
      expect(wrapper.find(element).exists()).toBe(exists);
    });

    it('should render the dummy component in the main section', () => {
      const article = wrapper.find('article');

      expect(article.find(DummyComponent).exists()).toBe(true);
    });

    it('should not make the main section smaller', () => {
      const article = wrapper.find('article');

      expect(article.classes()).not.toContain(SMALLER_SECTION_CLASS);
    });
  });

  describe('with the header and main slots', () => {
    beforeEach(() => {
      createWrapper({
        default: DummyComponent,
        header: DummyComponent,
      });
    });

    it.each`
      element                    | exists
      ${'article'}               | ${true}
      ${'header'}                | ${true}
      ${'aside'}                 | ${false}
      ${STICKY_SECTION_SELECTOR} | ${false}
    `('should find that $element exists is $exists', ({ element, exists }) => {
      expect(wrapper.find(element).exists()).toBe(exists);
    });

    it('should render the dummy component in the main section', () => {
      const article = findArticle();

      expect(article.find(DummyComponent).exists()).toBe(true);
    });

    it('should render the dummy component in the header section', () => {
      const header = findHeader();

      expect(header.find(DummyComponent).exists()).toBe(true);
    });
  });
  describe('with the sticky section and main slots', () => {
    beforeEach(() => {
      createWrapper({
        default: DummyComponent,
        sticky: DummyComponent,
      });
    });

    it.each`
      element                    | exists
      ${'article'}               | ${true}
      ${'header'}                | ${false}
      ${'aside'}                 | ${false}
      ${STICKY_SECTION_SELECTOR} | ${true}
    `('should find that $element exists is $exists', ({ element, exists }) => {
      expect(wrapper.find(element).exists()).toBe(exists);
    });

    it('should render the dummy component in the main section', () => {
      const article = findArticle();

      expect(article.find(DummyComponent).exists()).toBe(true);
    });

    it('should render the dummy component in the sticky section', () => {
      const section = findStickySection();

      expect(section.find(DummyComponent).exists()).toBe(true);
    });
  });

  describe('with the aside and main slots', () => {
    beforeEach(() => {
      createWrapper({
        default: DummyComponent,
        aside: DummyComponent,
      });
    });

    it.each`
      element                    | exists
      ${'article'}               | ${true}
      ${'header'}                | ${false}
      ${'aside'}                 | ${true}
      ${STICKY_SECTION_SELECTOR} | ${false}
    `('should find that $element exists is $exists', ({ element, exists }) => {
      expect(wrapper.find(element).exists()).toBe(exists);
    });

    it('should render the dummy component in the main section', () => {
      const article = findArticle();

      expect(article.find(DummyComponent).exists()).toBe(true);
    });

    it('should render the dummy component in the header section', () => {
      const aside = findAside();

      expect(aside.find(DummyComponent).exists()).toBe(true);
    });

    it('should make the main section smaller', () => {
      const article = findArticle();

      expect(article.classes()).toContain(SMALLER_SECTION_CLASS);
    });
  });
});
