require "rails_helper"

RSpec.describe "Insurance submissions", type: :request do
  let!(:agency) { Agency.create!(name: "Northstar Agency", slug: "northstar-agency") }
  let!(:user) { User.create!(email: "producer@example.com", password: "a-secure-password-2026", email_verified_at: Time.current) }
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

  it "queues all configured markets whose line and state appetite matches" do
    carrier = Carrier.create!(
      name: "Spec Demo Market",
      slug: "spec-demo-market",
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
    expected_carrier_ids = Carrier.where(integration_status: %w[sandbox_ready production_pending live])
      .select { |market| market.supports_submission?(submission) }.map(&:id)

    post submit_insurance_submission_path(submission)

    expect(response).to redirect_to(insurance_submission_path(submission))
    expect(submission.reload.status).to eq("marketing")
    expect(submission.market_submissions.pluck(:carrier_id)).to match_array(expected_carrier_ids)
    expect(submission.market_submissions.pluck(:carrier_id)).to include(carrier.id)
    expect(submission.market_submissions.pluck(:status).uniq).to eq(["queued"])
  end

  it "skips markets whose configured state appetite does not match" do
    submission = InsuranceSubmission.create!(
      agency: agency,
      customer: customer,
      creator: user,
      line_of_business: "general_liability",
      state: "CT",
      effective_date: Date.current + 30.days,
      status: "draft"
    )

    post submit_insurance_submission_path(submission)

    expect(response).to redirect_to(insurance_submission_path(submission))
    expect(submission.reload.status).to eq("ready")
    expect(submission.market_submissions).to be_empty
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

  it "returns a clearly labeled demo appetite result without inventing a quote" do
    carrier = Carrier.find_by!(slug: "demo-preferred-market")
    submission = InsuranceSubmission.create!(
      agency: agency,
      customer: customer,
      creator: user,
      line_of_business: "general_liability",
      state: "NY",
      effective_date: Date.current + 30.days,
      status: "marketing"
    )
    market = MarketSubmission.create!(
      agency: agency,
      insurance_submission: submission,
      carrier: carrier,
      status: "queued",
      environment: "demo",
      correlation_id: SecureRandom.uuid
    )

    expect {
      SubmitMarketJob.perform_now(market.id)
    }.not_to change(Quote, :count)

    expect(market.reload.status).to eq("eligible")
    expect(market.environment).to eq("demo")
    expect(market.appetite_result["simulated"]).to be(true)
    expect(market.response_metadata["message"]).to include("DEMO / SIMULATED")
    expect(submission.reload.status).to eq("markets_reviewed")
  end

  it "stores a genuine carrier quote and marks the application quoted" do
    carrier = Carrier.create!(
      name: "Sandbox Carrier", slug: "sandbox-carrier",
      integration_status: "sandbox_ready", environment: "sandbox",
      supported_lines: ["general_liability"], supported_states: ["NY"]
    )
    submission = InsuranceSubmission.create!(
      agency: agency, customer: customer, creator: user,
      line_of_business: "general_liability", state: "NY",
      effective_date: Date.current + 30.days, status: "marketing"
    )
    market = MarketSubmission.create!(
      agency: agency, insurance_submission: submission, carrier: carrier,
      status: "queued", environment: "sandbox", correlation_id: SecureRandom.uuid
    )
    adapter = instance_double(CarrierAdapters::Base)
    allow(CarrierAdapters::Registry).to receive(:fetch).with(carrier).and_return(adapter)
    allow(adapter).to receive(:submit).and_return(
      CarrierAdapters::Base::Result.new(
        status: "quoted", carrier_reference: "CARRIER-SUB-1", environment: "sandbox",
        appetite_result: { "decision" => "eligible" },
        quote_attributes: {
          carrier_quote_reference: "QUOTE-1001", source: "carrier", currency: "USD",
          premium: "1200.00", fees: "100.00", taxes: "50.00",
          coverages: { "each_occurrence" => 1_000_000 }, conditions: [], exclusions: []
        },
        message: "Sandbox quote received from carrier adapter."
      )
    )

    expect { SubmitMarketJob.perform_now(market.id) }.to change(Quote, :count).by(1)
    quote = market.quotes.sole
    expect(quote.agency).to eq(agency)
    expect(quote.source).to eq("carrier")
    expect(quote.environment).to eq("sandbox")
    expect(quote.premium).to eq(BigDecimal("1200.00"))
    expect(submission.reload.status).to eq("quoted")
  end

  it "marks an application partially quoted when another market needs attention" do
    submission = InsuranceSubmission.create!(
      agency: agency, customer: customer, creator: user,
      line_of_business: "general_liability", state: "NY",
      effective_date: Date.current + 30.days, status: "marketing"
    )
    quoted_carrier = Carrier.create!(name: "Quoted", slug: "quoted", integration_status: "sandbox_ready",
      environment: "sandbox", supported_lines: ["general_liability"], supported_states: ["NY"])
    referred_carrier = Carrier.create!(name: "Referred", slug: "referred", integration_status: "sandbox_ready",
      environment: "sandbox", supported_lines: ["general_liability"], supported_states: ["NY"])
    MarketSubmission.create!(agency: agency, insurance_submission: submission, carrier: quoted_carrier,
      status: "quoted", environment: "sandbox")
    MarketSubmission.create!(agency: agency, insurance_submission: submission, carrier: referred_carrier,
      status: "referred", environment: "sandbox")

    RefreshInsuranceSubmissionStatus.call(submission)
    expect(submission.reload.status).to eq("partially_quoted")
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
