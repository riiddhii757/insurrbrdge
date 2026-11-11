require "rails_helper"

RSpec.describe "Agency authentication", type: :request do
  include ActiveJob::TestHelper
  describe "POST /sign_up" do
    it "creates an agency and sends the owner an email verification link" do
      expect {
        expect {
        post sign_up_path, params: {
          agency: { name: "Northstar Insurance" },
          user: {
            first_name: "Taylor",
            last_name: "Broker",
            email: "Taylor@Example.com",
            password: "a-secure-password-2026",
            password_confirmation: "a-secure-password-2026"
          }
        }
        }.to change(Agency, :count).by(1).and change(User, :count).by(1).and change(Membership, :count).by(1)
      }.to have_enqueued_mail(EmailVerificationMailer, :verify)

      user = User.find_by!(email: "taylor@example.com")
      membership = user.memberships.sole
      expect(membership.role).to eq("agency_admin")
      expect(membership.status).to eq("active")
      expect(user.email_verified_at).to be_nil
      expect(response).to redirect_to(sign_in_path)
      expect(flash[:notice]).to include("verify your address")
    end

    it "does not create an account with a short password" do
      expect {
        post sign_up_path, params: {
          agency: { name: "Northstar Insurance" },
          user: { first_name: "Taylor", last_name: "Broker", email: "taylor@example.com",
                  password: "short", password_confirmation: "short" }
        }
      }.not_to change(User, :count)
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "workspace tenant isolation" do
    it "only displays records belonging to the signed-in agency" do
      agency_a = Agency.create!(name: "Agency Alpha", slug: "agency-alpha")
      agency_b = Agency.create!(name: "Agency Beta", slug: "agency-beta")
      user = User.create!(email: "alpha@example.com", password: "a-secure-password-2026")
      user.update!(email_verified_at: Time.current)
      Membership.create!(agency: agency_a, user: user, role: "producer", status: "active")
      Customer.create!(agency: agency_a, legal_name: "Alpha Client")
      Customer.create!(agency: agency_b, legal_name: "Beta Confidential Client")

      post sign_in_path, params: { email: user.email, password: "a-secure-password-2026" }
      get workspace_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Agency Alpha")
      expect(response.body).not_to include("Beta Confidential Client")
    end
  end
end
