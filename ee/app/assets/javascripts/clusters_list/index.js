import Vue from 'vue';
import VueApollo from 'vue-apollo';
import loadClusters from '~/clusters_list/load_clusters';
import loadAgents from './load_agents';

Vue.use(VueApollo);

export default () => {
  loadClusters(Vue);
  loadAgents(Vue, VueApollo);
};
