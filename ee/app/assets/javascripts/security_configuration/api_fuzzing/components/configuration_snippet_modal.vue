<script>
import { GlModal } from '@gitlab/ui';
import Clipboard from 'clipboard';
import { getBaseURL, setUrlParams, redirectTo } from '~/lib/utils/url_utility';
import { CODE_SNIPPET_SOURCE_URL_PARAM } from '~/pipeline_editor/components/code_snippet_alert/constants';
import { CONFIGURATION_SNIPPET_MODAL_ID } from '../constants';

export default {
  CONFIGURATION_SNIPPET_MODAL_ID,
  components: {
    GlModal,
  },
  props: {
    ciYamlEditUrl: {
      type: String,
      required: true,
    },
    yaml: {
      type: String,
      required: true,
    },
    redirectParam: {
      type: String,
      required: true,
    },
  },
  methods: {
    show() {
      this.$refs.modal.show();
    },
    onHide() {
      this.clipboard?.destroy();
    },
    copySnippet(andRedirect = true) {
      const id = andRedirect ? 'copy-yaml-snippet-and-edit-button' : 'copy-yaml-snippet-button';
      const clipboard = new Clipboard(`#${id}`, {
        text: () => this.yaml,
      });
      clipboard.on('success', () => {
        if (andRedirect) {
          const url = new URL(this.ciYamlEditUrl, getBaseURL());
          redirectTo(
            setUrlParams(
              {
                [CODE_SNIPPET_SOURCE_URL_PARAM]: this.redirectParam,
              },
              url,
            ),
          );
        }
      });
    },
  },
};
</script>

<template>
  <gl-modal
    ref="modal"
    :action-primary="{
      text: s__('APIFuzzing|Copy code and open .gitlab-ci.yml file'),
      attributes: [{ variant: 'confirm' }, { id: 'copy-yaml-snippet-and-edit-button' }],
    }"
    :action-secondary="{
      text: s__('APIFuzzing|Copy code only'),
      attributes: [{ variant: 'default' }, { id: 'copy-yaml-snippet-button' }],
    }"
    :action-cancel="{
      text: __('Cancel'),
    }"
    :modal-id="$options.CONFIGURATION_SNIPPET_MODAL_ID"
    :title="s__('APIFuzzing|Code snippet for the API Fuzzing configuration')"
    @hide="onHide"
    @primary="copySnippet"
    @secondary="copySnippet(false)"
  >
    <pre><code data-testid="api-fuzzing-modal-yaml-snippet" v-text="yaml"></code></pre>
  </gl-modal>
</template>
