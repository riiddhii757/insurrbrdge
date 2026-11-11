require "rails_helper"

RSpec.describe "Login security", type: :request do
  it "locks an account after repeated invalid passwords" do
    user = User.create!(
      email: "locked@example.com",
      password: "a-secure-password-2026",
      password_confirmation: "a-secure-password-2026"
    )

    10.times do
      post sign_in_path, params: { email: user.email, password: "incorrect-password" }
    end

    expect(user.reload.login_locked?).to be(true)
    expect(user.failed_login_attempts).to eq(10)
  end

  it "revokes existing sessions after a password change" do
    agency = Agency.create!(name: "Session Agency", slug: "session-agency")
    user = User.create!(
      email: "session@example.com",
      password: "a-secure-password-2026",
      password_confirmation: "a-secure-password-2026"
    )
    Membership.create!(agency: agency, user: user, role: "agency_admin", status: "active")

    post sign_in_path, params: { email: user.email, password: "a-secure-password-2026" }
    expect(response).to redirect_to(workspace_path)

    user.update!(password: "a-new-secure-password-2026", password_confirmation: "a-new-secure-password-2026")
    get workspace_path

    expect(response).to redirect_to(sign_in_path)
  end

  it "clears failed attempts after a successful login" do
    agency = Agency.create!(name: "Recovery Agency", slug: "recovery-agency")
    user = User.create!(
      email: "success@example.com",
      password: "a-secure-password-2026",
      password_confirmation: "a-secure-password-2026",
      failed_login_attempts: 2
    )
    Membership.create!(agency: agency, user: user, role: "agency_admin", status: "active")

    post sign_in_path, params: { email: user.email, password: "a-secure-password-2026" }

    expect(response).to redirect_to(workspace_path)
    expect(user.reload.failed_login_attempts).to eq(0)
  end
end
