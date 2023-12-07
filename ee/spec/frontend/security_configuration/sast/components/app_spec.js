import { GlLink, GlLoadingIcon, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { merge } from 'lodash';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import SASTConfigurationApp from 'ee/security_configuration/sast/components/app.vue';
import ConfigurationForm from 'ee/security_configuration/sast/components/configuration_form.vue';
import sastCiConfigurationQuery from 'ee/security_configuration/sast/graphql/sast_ci_configuration.query.graphql';
import { stripTypenames } from 'helpers/graphql_helpers';
import createMockApollo from 'helpers/mock_apollo_helper';
import { sastCiConfigurationQueryResponse } from '../mock_data';

Vue.use(VueApollo);

const sastDocumentationPath = '/help/sast';
const projectPath = 'namespace/project';

describe('SAST Configuration App', () => {
  let wrapper;

  const pendingHandler = () => new Promise(() => {});
  const successHandler = async () => sastCiConfigurationQueryResponse;
  const failureHandler = async () => ({ errors: [{ message: 'some error' }] });
  const createMockApolloProvider = (handler) =>
    createMockApollo([[sastCiConfigurationQuery, handler]]);

  const createComponent = (options) => {
    wrapper = shallowMount(
      SASTConfigurationApp,
      merge(
        {
          // Use a function reference here so it's lazily initialized, and can
          // be replaced with other handlers in certain tests without
          // initialising twice.
          apolloProvider: () => createMockApolloProvider(successHandler),
          provide: {
            sastDocumentationPath,
            projectPath,
          },
        },
        options,
      ),
    );
  };

  const findHeader = () => wrapper.find('header');
  const findSubHeading = () => findHeader().find('p');
  const findLink = (container = wrapper) => container.find(GlLink);
  const findConfigurationForm = () => wrapper.find(ConfigurationForm);
  const findLoadingIcon = () => wrapper.find(GlLoadingIcon);
  const findErrorAlert = () => wrapper.find('[data-testid="error-alert"]');
  const findFeedbackAlert = () => wrapper.find('[data-testid="feedback-alert"]');

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('feedback alert', () => {
    beforeEach(() => {
      createComponent({
        stubs: { GlSprintf },
      });
    });

    it('should be displayed', () => {
      expect(findFeedbackAlert().exists()).toBe(true);
    });

    it('links to the feedback issue', () => {
      const link = findFeedbackAlert().find(GlLink);
      expect(link.attributes()).toMatchObject({
        href: SASTConfigurationApp.feedbackIssue,
        target: '_blank',
      });
    });

    describe('when it is dismissed', () => {
      beforeEach(() => {
        findFeedbackAlert().vm.$emit('dismiss');
        return wrapper.vm.$nextTick();
      });

      it('should not be displayed', () => {
        expect(findFeedbackAlert().exists()).toBe(false);
      });
    });
  });

  describe('header', () => {
    beforeEach(() => {
      createComponent({
        stubs: { GlSprintf },
      });
    });

    it('displays a link to sastDocumentationPath', () => {
      expect(findLink(findHeader()).attributes('href')).toBe(sastDocumentationPath);
    });

    it('displays the subheading', () => {
      expect(findSubHeading().text()).toMatchInterpolatedText(SASTConfigurationApp.i18n.helpText);
    });
  });

  describe('when loading', () => {
    beforeEach(() => {
      createComponent({
        apolloProvider: createMockApolloProvider(pendingHandler),
      });
    });

    it('displays a loading spinner', () => {
      expect(findLoadingIcon().exists()).toBe(true);
    });

    it('does not display the configuration form', () => {
      expect(findConfigurationForm().exists()).toBe(false);
    });

    it('does not display an alert message', () => {
      expect(findErrorAlert().exists()).toBe(false);
    });
  });

  describe('when loading failed', () => {
    beforeEach(() => {
      createComponent({
        apolloProvider: createMockApolloProvider(failureHandler),
      });
    });

    it('does not display a loading spinner', () => {
      expect(findLoadingIcon().exists()).toBe(false);
    });

    it('does not display the configuration form', () => {
      expect(findConfigurationForm().exists()).toBe(false);
    });

    it('displays an alert message', () => {
      expect(findErrorAlert().exists()).toBe(true);
    });
  });

  describe('when loaded', () => {
    beforeEach(() => {
      createComponent();
    });

    it('does not display a loading spinner', () => {
      expect(findLoadingIcon().exists()).toBe(false);
    });

    it('displays the configuration form', () => {
      expect(findConfigurationForm().exists()).toBe(true);
    });

    it('passes the sastCiConfiguration to the sastCiConfiguration prop', () => {
      expect(findConfigurationForm().props('sastCiConfiguration')).toEqual(
        stripTypenames(sastCiConfigurationQueryResponse.data.project.sastCiConfiguration),
      );
    });

    it('does not display an alert message', () => {
      expect(findErrorAlert().exists()).toBe(false);
    });
  });
});
