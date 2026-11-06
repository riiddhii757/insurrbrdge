require "rails_helper"

RSpec.describe "Customer management", type: :request do
  let!(:agency) { Agency.create!(name: "Owner Agency", slug: "owner-agency") }
  let!(:user) { User.create!(email: "producer@example.com", password: "a-secure-password-2026") }

  before do
    Membership.create!(agency: agency, user: user, role: "producer", status: "active")
    post sign_in_path, params: { email: user.email, password: "a-secure-password-2026" }
  end

  it "creates a customer inside the signed-in agency without accepting a tenant id" do
    expect {
      post customers_path, params: {
        customer: { legal_name: "Harbor Electric LLC", industry: "Electrical contractor" }
      }
    }.to change(agency.customers, :count).by(1)

    expect(response).to redirect_to(customer_path(Customer.last))
    expect(Customer.last.agency).to eq(agency)
  end

  it "does not allow a user to view another agency's customer" do
    other_agency = Agency.create!(name: "Other Agency", slug: "other-agency")
    secret_customer = Customer.create!(agency: other_agency, legal_name: "Private Client")

    get customer_path(secret_customer)

    expect(response).to have_http_status(:not_found)
  end

  it "prevents read-only members from creating customers" do
    Membership.find_by!(agency: agency, user: user).update!(role: "read_only")

    expect {
      post customers_path, params: { customer: { legal_name: "Blocked Account" } }
    }.not_to change(Customer, :count)

    expect(response).to redirect_to(customers_path)
  end
end
