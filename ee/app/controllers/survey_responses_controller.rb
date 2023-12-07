# frozen_string_literal: true

class SurveyResponsesController < ApplicationController
  SURVEY_RESPONSE_SCHEMA_URL = 'iglu:com.gitlab/survey_response/jsonschema/1-0-0'
  CALENDLY_INVITE_LINK = 'https://calendly.com/mkarampalas/gitlab-user-onboarding-research'

  before_action :track_response, only: :index
  before_action :set_invite_link, only: :index

  skip_before_action :authenticate_user!

  feature_category :navigation

  def index
    render layout: false
  end

  private

  def track_response
    return unless Gitlab.dev_env_or_com?

    data = {
      survey_id: to_number(params[:survey_id]),
      instance_id: to_number(params[:instance_id]),
      user_id: to_number(params[:user_id]),
      email: params[:email],
      name: params[:name],
      username: params[:username],
      response: params[:response]
    }.compact

    context = SnowplowTracker::SelfDescribingJson.new(SURVEY_RESPONSE_SCHEMA_URL, data)

    ::Gitlab::Tracking.event(self.class.name, 'submit_response', context: [context])
  end

  def to_number(param)
    param.to_i if param&.match?(/^\d+$/)
  end

  def set_invite_link
    return unless Gitlab.dev_env_or_com?
    return unless Gitlab::Utils.to_boolean(params[:show_invite_link])
    return unless Feature.enabled?(:calendly_invite_link)

    @invite_link = CALENDLY_INVITE_LINK
  end
end
