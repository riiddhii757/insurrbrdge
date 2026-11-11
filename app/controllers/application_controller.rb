class ApplicationController < ActionController::Base
  allow_browser versions: :modern
  protect_from_forgery with: :exception

  before_action :set_current_context

  helper_method :current_user, :current_agency, :current_membership

  private

  def current_user
    return unless session[:user_id]

    @current_user ||= User.find_by(id: session[:user_id])
    unless @current_user && session[:auth_session_version].to_i == @current_user.auth_session_version.to_i
      reset_session
      @current_user = nil
    end
    @current_user
  end

  def current_membership
    @current_membership ||= current_user&.memberships&.includes(:agency)&.find_by(
      agency_id: session[:agency_id], status: "active"
    )
  end

  def current_agency
    current_membership&.agency
  end

  def set_current_context
    Current.user = current_user
    Current.agency = current_agency
  end

  def require_authentication
    return if current_user && current_agency && current_user.disabled_at.nil?

    reset_session
    redirect_to sign_in_path, alert: "Please sign in to continue."
  end

  def require_agency_admin
    return if current_membership&.role == "agency_admin" || current_user&.platform_admin?

    redirect_to workspace_path, alert: "You do not have permission to do that."
  end
end
