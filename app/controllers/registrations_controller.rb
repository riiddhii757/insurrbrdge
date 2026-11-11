class RegistrationsController < ApplicationController
  skip_before_action :set_current_context, only: %i[new create]
  before_action :redirect_if_authenticated, only: %i[new create]

  def new
    @user = User.new
    @agency = Agency.new
  end

  def create
    @user = User.new(user_params)
    @agency = Agency.new(agency_params)

    ActiveRecord::Base.transaction do
      @agency.slug = unique_slug(@agency.name)
      @agency.save!
      @user.save!
      @user.memberships.create!(agency: @agency, role: "agency_admin", status: "active")
    end

    token = @user.issue_email_verification_token!
    EmailVerificationMailer.with(user: @user, token: token).verify.deliver_later
    reset_session
    redirect_to sign_in_path, notice: "Your agency is created. Check your email to verify your address before signing in."
  rescue ActiveRecord::RecordInvalid
    render :new, status: :unprocessable_entity
  end

  private

  def user_params
    params.require(:user).permit(:first_name, :last_name, :email, :password, :password_confirmation)
  end

  def agency_params
    params.require(:agency).permit(:name)
  end

  def unique_slug(name)
    base = name.to_s.parameterize.presence || "agency"
    candidate = base
    suffix = 2
    while Agency.exists?(slug: candidate)
      candidate = "#{base}-#{suffix}"
      suffix += 1
    end
    candidate
  end

  def redirect_if_authenticated
    redirect_to workspace_path if current_user && current_agency
  end
end
