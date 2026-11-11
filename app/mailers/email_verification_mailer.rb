class EmailVerificationMailer < ApplicationMailer
  def verify
    @user = params[:user]
    @verification_url = verify_email_url(params[:token])
    mail(to: @user.email, subject: "Verify your InsurrBrdge email")
  end
end
