class SessionsController < ApplicationController
  rate_limit to: 10, within: 15.minutes,
             by: -> { request.remote_ip },
             with: -> { head :too_many_requests },
             name: "sign-in-by-ip"

  skip_before_action :set_current_context, only: %i[new create]
  before_action :redirect_if_authenticated, only: %i[new create]

  def new
  end

  def create
    user = User.find_by(email: params[:email].to_s.strip.downcase)

    if user&.login_locked?
      flash.now[:alert] = "Email or password is incorrect."
      render :new, status: :too_many_requests
      return
    end

    if user&.authenticate(params[:password].to_s) && user.disabled_at.nil?
      membership = user.memberships.includes(:agency).find_by(status: "active")
      if membership
        user.reset_failed_login!
        reset_session
        session[:user_id] = user.id
        session[:agency_id] = membership.agency_id
        session[:auth_session_version] = user.auth_session_version
        redirect_to workspace_path, notice: "Welcome back."
      else
        flash.now[:alert] = "Your account is not assigned to an active agency. Contact your administrator."
        render :new, status: :unprocessable_entity
      end
    else
      user&.register_failed_login!
      flash.now[:alert] = "Email or password is incorrect."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    reset_session
    redirect_to root_path, notice: "You have been signed out."
  end

  private

  def redirect_if_authenticated
    redirect_to workspace_path if current_user && current_agency
  end
end
