import { shallowMount } from '@vue/test-utils';
import Branch from 'ee/status_checks/components/branch.vue';

describe('Status checks branch', () => {
  let wrapper;

  const createWrapper = (props = {}) => {
    wrapper = shallowMount(Branch, {
      propsData: props,
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findBranch = () => wrapper.find('span');

  it('renders "Any branch" if no branch is given', () => {
    createWrapper();

    expect(findBranch().text()).toBe('Any branch');
    expect(findBranch().classes('monospace')).toBe(true);
  });

  it('renders the first branch name when branches are given', () => {
    createWrapper({ branches: [{ name: 'Foo' }, { name: 'Bar' }] });

    expect(findBranch().text()).toBe('Foo');
    expect(findBranch().classes('monospace')).toBe(false);
  });
});
