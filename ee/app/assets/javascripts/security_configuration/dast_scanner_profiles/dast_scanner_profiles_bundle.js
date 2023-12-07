import Vue from 'vue';
import { returnToPreviousPageFactory } from 'ee/security_configuration/dast_profiles/redirect';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import DastScannerProfileForm from './components/dast_scanner_profile_form.vue';
import apolloProvider from './graphql/provider';

export default () => {
  const el = document.querySelector('.js-dast-scanner-profile-form');
  if (!el) {
    return false;
  }

  const { projectFullPath, profilesLibraryPath, onDemandScansPath } = el.dataset;

  const props = {
    projectFullPath,
  };

  if (el.dataset.scannerProfile) {
    props.profile = convertObjectPropsToCamelCase(JSON.parse(el.dataset.scannerProfile));
  }

  const returnToPreviousPage = ({ id } = {}) => {
    returnToPreviousPageFactory({
      onDemandScansPath,
      profilesLibraryPath,
      urlParamKey: 'scanner_profile_id',
    })(id);
  };

  return new Vue({
    el,
    apolloProvider,
    render(h) {
      return h(DastScannerProfileForm, {
        props,
        on: {
          success: returnToPreviousPage,
          cancel: returnToPreviousPage,
        },
      });
    },
  });
};
