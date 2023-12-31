# frozen_string_literal: true

class Admin::LicensesController < Admin::ApplicationController
  include Admin::LicenseRequest

  before_action :license, only: [:show, :download, :destroy]
  before_action :require_license, only: [:download, :destroy]
  before_action :check_cloud_license, only: [:show]

  respond_to :html

  feature_category :license

  def show
    if @license.present? || License.future_dated_only?
      @licenses = License.history
    else
      render :missing
    end
  end

  def download
    send_data @license.data, filename: @license.data_filename, disposition: 'attachment'
  end

  def new
    build_license
  end

  def create
    return upload_license_error if license_params[:data].blank? && license_params[:data_file].blank?

    @license = License.new(license_params)

    return upload_license_error if @license.cloud_license?

    respond_with(@license, location: admin_license_path) do
      if @license.save
        notice = if @license.started?
                   _('The license was successfully uploaded and is now active. You can see the details below.')
                 else
                   _('The license was successfully uploaded and will be active from %{starts_at}. You can see the details below.' % { starts_at: @license.starts_at })
                 end

        flash[:notice] = notice
      end
    end
  end

  def destroy
    Licenses::DestroyService.new(license, current_user).execute

    if License.current
      flash[:notice] = _('The license was removed. GitLab has fallen back on the previous license.')
    else
      flash[:alert] = _('The license was removed. GitLab now no longer has a valid license.')
    end

    redirect_to admin_license_path, status: :found
  rescue Licenses::DestroyService::DestroyCloudLicenseError => e
    flash[:error] = e.message

    redirect_to admin_license_path, status: :found
  end

  def sync_seat_link
    respond_to do |format|
      format.json do
        if Gitlab::SeatLinkData.new.sync
          render json: { success: true }
        else
          render json: { success: false }, status: :unprocessable_entity
        end
      end
    end
  end

  private

  def build_license
    @license ||= License.new(data: params[:trial_key])
  end

  def check_cloud_license
    redirect_to admin_cloud_license_path if Gitlab::CurrentSettings.cloud_license_enabled?
  end

  def license_params
    license_params = params.require(:license).permit(:data_file, :data)
    license_params.delete(:data) if license_params[:data_file]
    license_params
  end

  def upload_license_error
    flash[:alert] = _('Please enter or upload a valid license.')
    @license = License.new
    redirect_to new_admin_license_path
  end
end
