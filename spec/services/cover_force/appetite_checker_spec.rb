require "rails_helper"

RSpec.describe CoverForce::AppetiteChecker do
  let(:api_client) { instance_double(CoverForce::ApiClient) }
  let(:response) do
    instance_double(
      Net::HTTPOK, code: "200", body: {
        appetiteInfos: [{
          carrier: "ACCIDENTFUND", policyType: "CGL", state: "NY",
          naicsCode: "111110", hasAppetite: "IN_APPETITE"
        }]
      }.to_json
    )
  end
  subject(:checker) do
    described_class.new(api_client: api_client, request_id_generator: -> { "req-test-1" })
  end

  it "posts the documented appetite request and returns the carrier results" do
    expect(api_client).to receive(:request).with(
      :post, "check-appetite",
      headers: { "Content-Type" => "application/json", "x-request-id" => "req-test-1" },
      body: {
        carriers: ["ACCIDENTFUND"], naicsCode: "111110", policyType: "CGL", state: "NY"
      }.to_json
    ).and_return(response)

    expect(checker.call(
      carriers: ["ACCIDENTFUND"], naics_code: "111110", policy_type: "CGL", state: "NY"
    ).first["hasAppetite"]).to eq("IN_APPETITE")
  end

  it "rejects malformed NAICS codes before making a request" do
    expect {
      checker.call(carriers: ["ACCIDENTFUND"], naics_code: "123", policy_type: "CGL", state: "NY")
    }.to raise_error(described_class::InvalidRequest, /6 digits/)
    expect(api_client).not_to have_received(:request)
  end

  it "rejects unsupported carrier and state values" do
    expect {
      checker.call(carriers: ["NOT_A_CARRIER"], naics_code: "111110", policy_type: "CGL", state: "NY")
    }.to raise_error(described_class::InvalidRequest)
    expect {
      checker.call(carriers: ["ACCIDENTFUND"], naics_code: "111110", policy_type: "CGL", state: "XX")
    }.to raise_error(described_class::InvalidRequest)
  end

  it "surfaces provider errors with the response request id" do
    failed = instance_double(Net::HTTPBadRequest, code: "400", body: '{"message":"bad request"}', "[]" => "cf-req-1")
    allow(api_client).to receive(:request).and_return(failed)

    expect {
      checker.call(carriers: ["ACCIDENTFUND"], naics_code: "111110", policy_type: "CGL", state: "NY")
    }.to raise_error(described_class::ProviderError) { |error|
      expect(error.status).to eq(400)
      expect(error.request_id).to eq("cf-req-1")
    }
  end
end
