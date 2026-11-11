require "rails_helper"

RSpec.describe "Multi-factor authentication", type: :request do
  let(:agency) { Agency.create!(name: "MFA Agency", slug: "mfa-agency") }
  let(:user) do
    account = User.create!(email: "mfa@example.com", password: "a-secure-password-2026",
                           email_verified_at: Time.current)
    Membership.create!(agency: agency, user: account, role: "agency_admin", status: "active")
    account
  end

  def sign_in_with_password(account)
    post sign_in_path, params: { email: account.email, password: "a-secure-password-2026" }
  end

  it "requires an authenticator code after password authentication when MFA is enabled" do
    account = user
    account.begin_mfa_setup!
    code = account.send(:totp_code, Time.current.to_i / 30)
    account.enable_mfa!(code)

    sign_in_with_password(account)

    expect(response).to redirect_to(mfa_challenge_path)
    expect(session[:user_id]).to be_nil
    expect(session[:pending_mfa_user_id]).to eq(account.id)

    post verify_mfa_challenge_path, params: { code: account.send(:totp_code, Time.current.to_i / 30) }

    expect(response).to redirect_to(workspace_path)
    expect(session[:user_id]).to eq(account.id)
    expect(session[:pending_mfa_user_id]).to be_nil
  end

  it "allows a recovery code once and rejects it on a later sign-in" do
    account = user
    account.begin_mfa_setup!
    recovery_codes = account.enable_mfa!(account.send(:totp_code, Time.current.to_i / 30))

    sign_in_with_password(account)
    post verify_mfa_challenge_path, params: { code: recovery_codes.first }
    expect(response).to redirect_to(workspace_path)
    expect(account.mfa_recovery_codes.find_by!(digest: Digest::SHA256.hexdigest(recovery_codes.first)).used_at).to be_present

    delete sign_out_path
    sign_in_with_password(account)
    post verify_mfa_challenge_path, params: { code: recovery_codes.first }

    expect(response).to have_http_status(:unprocessable_entity)
    expect(session[:user_id]).to be_nil
  end

  it "does not enable MFA with an incorrect authenticator code" do
    account = user
    account.begin_mfa_setup!

    expect(account.enable_mfa!("000000")).to be(false)
    expect(account.reload.mfa_enabled?).to be(false)
    expect(account.mfa_recovery_codes).to be_empty
  end

  it "rejects an expired or stale pending MFA session after the user security version changes" do
    account = user
    account.begin_mfa_setup!
    account.enable_mfa!(account.send(:totp_code, Time.current.to_i / 30))
    sign_in_with_password(account)
    account.update!(password: "a-different-secure-password-2026", password_confirmation: "a-different-secure-password-2026")

    post verify_mfa_challenge_path, params: { code: account.send(:totp_code, Time.current.to_i / 30) }

    expect(response).to redirect_to(sign_in_path)
    expect(session[:user_id]).to be_nil
  end
end
