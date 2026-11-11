class PasswordResetMailer < ApplicationMailer
  def reset
    @user = params[:user]
    @reset_url = edit_password_reset_url(params[:token])
    mail(to: @user.email, subject: "Reset your InsurrBrdge password")
  end
end
