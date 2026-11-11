class MfaController < ApplicationController
  before_action :require_authentication, except: %i[challenge verify]
  before_action :load_pending_user, only: %i[challenge verify]

  rate_limit to: 10, within: 15.minutes,
             by: -> { request.remote_ip },
             with: -> { head :too_many_requests },
             name: "mfa-challenge-by-ip",
             only: :verify

  def show
  end

  def setup
    @secret = current_user.begin_mfa_setup!
    render :setup
  end

  def enable
    @recovery_codes = current_user.enable_mfa!(params[:code])
    if @recovery_codes
      render :recovery_codes
    else
      @secret = current_user.totp_secret
      flash.now[:alert] = "That code did not match. Try the current code from your authenticator app."
      render :setup, status: :unprocessable_entity
    end
  end

  def challenge
  end

  def verify
    unless @pending_user.verify_mfa_code(params[:code])
      flash.now[:alert] = "That authentication code is invalid or has already been used."
      render :challenge, status: :unprocessable_entity
      return
    end

    membership = @pending_user.memberships.includes(:agency).find_by(status: "active")
    unless membership && @pending_user.disabled_at.nil?
      reset_session
      redirect_to sign_in_path, alert: "Your account is not assigned to an active agency."
      return
    end

    reset_session
    session[:user_id] = @pending_user.id
    session[:agency_id] = membership.agency_id
    session[:auth_session_version] = @pending_user.auth_session_version
    @pending_user.reset_failed_login!
    redirect_to workspace_path, notice: "Welcome back."
  end

  private

  def load_pending_user
    @pending_user = User.find_by(id: session[:pending_mfa_user_id])
    valid_session = @pending_user &&
                    session[:pending_mfa_session_version].to_i == @pending_user.auth_session_version.to_i &&
                    session[:pending_mfa_started_at].to_i >= 5.minutes.ago.to_i &&
                    @pending_user.mfa_enabled? &&
                    @pending_user.disabled_at.nil?
    unless valid_session
      reset_session
      redirect_to sign_in_path, alert: "Please sign in again to continue."
    end
  end
end
