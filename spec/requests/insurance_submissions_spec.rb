require "rails_helper"

RSpec.describe "Insurance submissions", type: :request do
  let!(:agency) { Agency.create!(name: "Northstar Agency", slug: "northstar-agency") }
  let!(:user) { User.create!(email: "producer@example.com", password: "a-secure-password-2026") }
  let!(:customer) { Customer.create!(agency: agency, legal_name: "Harbor Electric LLC") }

  before do
    Membership.create!(agency: agency, user: user, role: "producer", status: "active")
    post sign_in_path, params: { email: user.email, password: "a-secure-password-2026" }
  end

  it "creates an application under the signed-in agency and customer" do
    expect {
      post insurance_submissions_path(customer_id: customer.id), params: {
        insurance_submission: {
          line_of_business: "general_liability",
          state: "NY",
          effective_date: Date.current + 30.days,
          agency_id: 999999
        }
      }
    }.to change(agency.insurance_submissions, :count).by(1)

    submission = agency.insurance_submissions.sole
    expect(submission.customer).to eq(customer)
    expect(submission.agency).to eq(agency)
    expect(submission.creator).to eq(user)
    expect(response).to redirect_to(insurance_submission_path(submission))
  end

  it "does not create an application for another agency's customer" do
    other_agency = Agency.create!(name: "Other Agency", slug: "other-agency")
    other_customer = Customer.create!(agency: other_agency, legal_name: "Private Business")

    expect {
      post insurance_submissions_path(customer_id: other_customer.id), params: {
        insurance_submission: { line_of_business: "general_liability" }
      }
    }.not_to change(InsuranceSubmission, :count)

    expect(response).to have_http_status(:not_found)
  end

  it "does not allow a user to view another agency's application" do
    other_agency = Agency.create!(name: "Other Agency", slug: "other-agency")
    other_customer = Customer.create!(agency: other_agency, legal_name: "Private Business")
    other_submission = InsuranceSubmission.create!(
      agency: other_agency,
      customer: other_customer,
      line_of_business: "general_liability",
      status: "draft"
    )

    get insurance_submission_path(other_submission)

    expect(response).to have_http_status(:not_found)
  end

  it "queues a market attempt only after required placement details are present" do
    carrier = Carrier.create!(
      name: "Demo Market",
      slug: "demo-market",
      integration_status: "sandbox_ready",
      environment: "demo",
      supported_lines: ["general_liability"],
      supported_states: ["NY"]
    )
    submission = InsuranceSubmission.create!(
      agency: agency,
      customer: customer,
      creator: user,
      line_of_business: "general_liability",
      state: "NY",
      effective_date: Date.current + 30.days,
      status: "draft"
    )

    post submit_insurance_submission_path(submission)

    expect(response).to redirect_to(insurance_submission_path(submission))
    expect(submission.reload.status).to eq("marketing")
    expect(submission.market_submissions.count).to eq(1)
    expect(submission.market_submissions.sole.carrier).to eq(carrier)
    expect(submission.market_submissions.sole.status).to eq("queued")
  end

  it "does not market an application without an effective date and state" do
    submission = InsuranceSubmission.create!(
      agency: agency,
      customer: customer,
      creator: user,
      line_of_business: "general_liability",
      status: "draft"
    )

    post submit_insurance_submission_path(submission)

    expect(response).to redirect_to(insurance_submission_path(submission))
    expect(submission.reload.status).to eq("draft")
    expect(submission.market_submissions).to be_empty
  end

  it "prevents read-only members from creating applications" do
    Membership.find_by!(agency: agency, user: user).update!(role: "read_only")

    expect {
      post insurance_submissions_path(customer_id: customer.id), params: {
        insurance_submission: { line_of_business: "general_liability" }
      }
    }.not_to change(InsuranceSubmission, :count)

    expect(response).to redirect_to(insurance_submissions_path)
  end
end
