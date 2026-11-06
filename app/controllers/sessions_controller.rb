class SessionsController < ApplicationController
  skip_before_action :set_current_context, only: %i[new create]
  before_action :redirect_if_authenticated, only: %i[new create]

  def new
  end

  def create
    user = User.find_by(email: params[:email].to_s.strip.downcase)
    if user&.authenticate(params[:password].to_s) && user.disabled_at.nil?
      membership = user.memberships.includes(:agency).find_by(status: "active")
      if membership
        reset_session
        session[:user_id] = user.id
        session[:agency_id] = membership.agency_id
        redirect_to workspace_path, notice: "Welcome back."
      else
        flash.now[:alert] = "Your account is not assigned to an active agency. Contact your administrator."
        render :new, status: :unprocessable_entity
      end
    else
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
