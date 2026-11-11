require "rails_helper"

RSpec.describe "Password resets", type: :request do
  include ActiveJob::TestHelper

  let!(:user) do
    User.create!(
      email: "reset@example.com",
      password: "a-secure-password-2026",
      password_confirmation: "a-secure-password-2026"
    )
  end

  it "sends a reset link without revealing whether an account exists" do
    expect {
      post password_resets_path, params: { email: user.email }
    }.to have_enqueued_mail(PasswordResetMailer, :reset)

    expect(response).to redirect_to(sign_in_path)
    expect(flash[:notice]).to include("If an active account matches")
  end

  it "resets the password and consumes the token" do
    ActionMailer::Base.deliveries.clear

    post password_resets_path, params: { email: user.email }
    expect(response).to redirect_to(sign_in_path)

    # The request enqueues the mail. Drain the test queue explicitly so the
    # ActionMailer delivery is available before extracting the one-time token.
    perform_enqueued_jobs(only: ActionMailer::MailDeliveryJob)

    email = ActionMailer::Base.deliveries.last
    expect(email).to be_present

    token = email.body.to_s[/password\/reset\/([A-Za-z0-9_-]+)/, 1]
    expect(token).to be_present

    patch password_reset_path(token), params: {
      user: {
        password: "a-different-secure-password-2026",
        password_confirmation: "a-different-secure-password-2026"
      }
    }

    expect(response).to redirect_to(sign_in_path)
    expect(user.reload.authenticate("a-different-secure-password-2026")).to be_truthy
    expect(user.password_reset_digest).to be_nil

    patch password_reset_path(token), params: {
      user: {
        password: "another-secure-password-2026",
        password_confirmation: "another-secure-password-2026"
      }
    }
    expect(response).to redirect_to(new_password_reset_path)
  end

  it "does not send mail or disclose unknown accounts" do
    expect {
      post password_resets_path, params: { email: "unknown@example.com" }
    }.not_to have_enqueued_mail(PasswordResetMailer, :reset)

    expect(response).to redirect_to(sign_in_path)
    expect(flash[:notice]).to include("If an active account matches")
  end
end
