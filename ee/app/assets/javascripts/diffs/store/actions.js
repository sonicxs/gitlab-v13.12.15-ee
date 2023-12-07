import Visibility from 'visibilityjs';
import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import httpStatusCodes from '~/lib/utils/http_status';
import Poll from '~/lib/utils/poll';
import { __ } from '~/locale';

import * as types from './mutation_types';

export * from '~/diffs/store/actions';

let codequalityPoll;

export const setCodequalityEndpoint = ({ commit }, endpoint) => {
  commit(types.SET_CODEQUALITY_ENDPOINT, endpoint);
};

export const clearCodequalityPoll = () => {
  codequalityPoll = null;
};

export const stopCodequalityPolling = () => {
  if (codequalityPoll) codequalityPoll.stop();
};

export const restartCodequalityPolling = () => {
  if (codequalityPoll) codequalityPoll.restart();
};

export const fetchCodequality = ({ commit, state, dispatch }) => {
  codequalityPoll = new Poll({
    resource: {
      getCodequalityDiffReports: (endpoint) => axios.get(endpoint),
    },
    data: state.endpointCodequality,
    method: 'getCodequalityDiffReports',
    successCallback: ({ status, data }) => {
      if (status === httpStatusCodes.OK) {
        commit(types.SET_CODEQUALITY_DATA, data);

        dispatch('stopCodequalityPolling');
      }
    },
    errorCallback: () =>
      createFlash(__('Something went wrong on our end while loading the code quality diff.')),
  });

  if (!Visibility.hidden()) {
    codequalityPoll.makeRequest();
  }

  Visibility.change(() => {
    if (!Visibility.hidden()) {
      dispatch('restartCodequalityPolling');
    } else {
      dispatch('stopCodequalityPolling');
    }
  });
};
