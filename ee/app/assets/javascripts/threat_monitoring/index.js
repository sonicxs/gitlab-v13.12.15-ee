import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import ThreatMonitoringApp from './components/app.vue';
import createStore from './store';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

export default () => {
  const el = document.querySelector('#js-threat-monitoring-app');
  const {
    wafStatisticsEndpoint,
    networkPolicyStatisticsEndpoint,
    environmentsEndpoint,
    networkPoliciesEndpoint,
    emptyStateSvgPath,
    wafNoDataSvgPath,
    networkPolicyNoDataSvgPath,
    newPolicyPath,
    documentationPath,
    defaultEnvironmentId,
    projectPath,
  } = el.dataset;

  const store = createStore();
  store.dispatch('threatMonitoring/setEndpoints', {
    wafStatisticsEndpoint,
    networkPolicyStatisticsEndpoint,
    environmentsEndpoint,
  });
  store.dispatch('networkPolicies/setEndpoints', {
    networkPoliciesEndpoint,
  });

  return new Vue({
    apolloProvider,
    el,
    provide: {
      documentationPath,
      emptyStateSvgPath,
      projectPath,
    },
    store,
    render(createElement) {
      return createElement(ThreatMonitoringApp, {
        props: {
          wafNoDataSvgPath,
          networkPolicyNoDataSvgPath,
          defaultEnvironmentId: parseInt(defaultEnvironmentId, 10),
          newPolicyPath,
        },
      });
    },
  });
};
