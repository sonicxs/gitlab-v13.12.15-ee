<script>
import {
  GlButton,
  GlForm,
  GlFormCheckbox,
  GlFormGroup,
  GlFormInput,
  GlLink,
  GlSprintf,
} from '@gitlab/ui';
import validation from '~/vue_shared/directives/validation';
import {
  activateLabel,
  fieldRequiredMessage,
  subscriptionActivationForm,
  subscriptionQueries,
} from '../constants';
import { getErrorsAsData, updateSubscriptionAppCache } from '../graphql/utils';

export const SUBSCRIPTION_ACTIVATION_FAILURE_EVENT = 'subscription-activation-failure';
export const SUBSCRIPTION_ACTIVATION_SUCCESS_EVENT = 'subscription-activation-success';

export default {
  name: 'CloudLicenseSubscriptionActivationForm',
  components: {
    GlButton,
    GlForm,
    GlFormGroup,
    GlFormInput,
    GlFormCheckbox,
    GlSprintf,
    GlLink,
  },
  i18n: {
    acceptTerms: subscriptionActivationForm.acceptTerms,
    activateLabel,
    activationCode: subscriptionActivationForm.activationCode,
    fieldRequiredMessage,
    pasteActivationCode: subscriptionActivationForm.pasteActivationCode,
  },
  directives: {
    validation: validation(),
  },
  props: {
    hideSubmitButton: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  emits: [SUBSCRIPTION_ACTIVATION_FAILURE_EVENT, SUBSCRIPTION_ACTIVATION_SUCCESS_EVENT],
  data() {
    const form = {
      state: false,
      showValidation: false,
      fields: {
        activationCode: {
          required: true,
          state: null,
          value: '',
        },
        terms: {
          required: true,
          state: null,
        },
      },
    };
    return {
      form,
      isLoading: false,
    };
  },
  computed: {
    isCheckboxValid() {
      if (this.form.showValidation) {
        return this.form.fields.terms.state ? null : false;
      }
      return null;
    },
    isRequestingActivation() {
      return this.isLoading;
    },
  },
  methods: {
    submit() {
      if (!this.form.state) {
        this.form.showValidation = true;
        return;
      }
      this.form.showValidation = false;
      this.isLoading = true;
      this.$apollo
        .mutate({
          mutation: subscriptionQueries.mutation,
          variables: {
            gitlabSubscriptionActivateInput: {
              activationCode: this.form.fields.activationCode.value,
            },
          },
          update: this.updateSubscriptionAppCache,
        })
        .then((res) => {
          const errors = getErrorsAsData(res);
          if (errors.length) {
            const [error] = errors;
            throw new Error(error);
          }
          this.$emit(SUBSCRIPTION_ACTIVATION_SUCCESS_EVENT);
        })
        .catch((error) => {
          this.$emit(SUBSCRIPTION_ACTIVATION_FAILURE_EVENT, error.message);
        })
        .finally(() => {
          this.isLoading = false;
        });
    },
    updateSubscriptionAppCache,
  },
};
</script>
<template>
  <gl-form novalidate @submit.prevent="submit">
    <div class="gl-display-flex gl-flex-wrap">
      <gl-form-group
        class="gl-flex-grow-1"
        :invalid-feedback="form.fields.activationCode.feedback"
        data-testid="form-group-activation-code"
      >
        <label class="gl-w-full" for="activation-code-group">
          {{ $options.i18n.activationCode }}
        </label>
        <gl-form-input
          id="activation-code-group"
          v-model="form.fields.activationCode.value"
          v-validation:[form.showValidation]
          :disabled="isLoading"
          :placeholder="$options.i18n.pasteActivationCode"
          :state="form.fields.activationCode.state"
          name="activationCode"
          class="gl-mb-4"
          required
        />
      </gl-form-group>

      <gl-form-group
        class="gl-mb-0"
        :state="isCheckboxValid"
        :invalid-feedback="$options.i18n.fieldRequiredMessage"
        data-testid="form-group-terms"
      >
        <gl-form-checkbox
          id="subscription-form-terms-check"
          v-model="form.fields.terms.state"
          :state="isCheckboxValid"
        >
          <gl-sprintf :message="$options.i18n.acceptTerms">
            <template #link="{ content }">
              <gl-link href="https://about.gitlab.com/terms/" target="_blank"
                >{{ content }}
              </gl-link>
            </template>
          </gl-sprintf>
        </gl-form-checkbox>
      </gl-form-group>

      <gl-button
        v-if="!hideSubmitButton"
        :loading="isRequestingActivation"
        category="primary"
        class="gl-mt-6 js-no-auto-disable"
        data-testid="activate-button"
        type="submit"
        variant="confirm"
      >
        {{ $options.i18n.activateLabel }}
      </gl-button>
    </div>
  </gl-form>
</template>
