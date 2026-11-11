class PasswordResetsController < ApplicationController
  rate_limit to: 5, within: 1.hour,
             by: -> { request.remote_ip },
             with: -> { head :too_many_requests },
             name: "password-reset-by-ip"

  skip_before_action :set_current_context
  before_action :set_user_from_token, only: %i[edit update]

  def new
  end

  def create
    user = User.find_by(email: params[:email].to_s.strip.downcase)
    if user && user.disabled_at.nil?
      token = user.issue_password_reset_token!
      PasswordResetMailer.with(user: user, token: token).reset.deliver_later
    end

    redirect_to sign_in_path,
                notice: "If an active account matches that email, password reset instructions will be sent."
  end

  def edit
    unless @user&.password_reset_token_valid?(params[:token])
      redirect_to new_password_reset_path, alert: "That password reset link is invalid or has expired."
    end
  end

  def update
    unless @user&.password_reset_token_valid?(params[:token])
      redirect_to new_password_reset_path, alert: "That password reset link is invalid or has expired."
      return
    end

    if @user.update(password_params.merge(failed_login_attempts: 0, locked_at: nil,
                                          password_reset_digest: nil, password_reset_sent_at: nil))
      redirect_to sign_in_path, notice: "Your password has been reset. Please sign in."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_user_from_token
    digest = Digest::SHA256.hexdigest(params[:token].to_s)
    @user = User.find_by(password_reset_digest: digest)
  end

  def password_params
    params.require(:user).permit(:password, :password_confirmation)
  end
end
