class EmailVerificationsController < ApplicationController
  VERIFICATION_TTL = 24.hours

  rate_limit to: 5, within: 1.hour,
             by: -> { request.remote_ip },
             with: -> { head :too_many_requests },
             name: "email-verification-resend-by-ip"

  skip_before_action :set_current_context

  def show
    user = User.find_by(email_verification_digest: digest(params[:token]))
    if user && user.email_verification_sent_at && user.email_verification_sent_at >= VERIFICATION_TTL.ago
      user.update!(email_verified_at: Time.current, email_verification_digest: nil, email_verification_sent_at: nil)
      redirect_to sign_in_path, notice: "Your email is verified. You can now sign in."
    else
      redirect_to new_email_verification_path, alert: "That verification link is invalid or expired. Request a new one."
    end
  end

  def new
  end

  def create
    user = User.find_by(email: params[:email].to_s.strip.downcase)
    if user && user.email_verified_at.nil?
      token = user.issue_email_verification_token!
      EmailVerificationMailer.with(user: user, token: token).verify.deliver_later
    end
    redirect_to sign_in_path, notice: "If an unverified account matches that email, a verification link will be sent."
  end

  private

  def digest(token)
    Digest::SHA256.hexdigest(token.to_s)
  end
end
