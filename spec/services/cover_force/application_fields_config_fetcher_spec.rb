require "rails_helper"

RSpec.describe CoverForce::ApplicationFieldsConfigFetcher do
  let(:api_client) { instance_double(CoverForce::ApiClient) }
  let(:response) do
    instance_double(Net::HTTPOK, code: "200", body: {
      applicationId: "APP-test-123",
      fieldsConfig: [{
        fieldPath: "APPLICATION_BUSINESSINFO_ANNUALREVENUE",
        jsonPath: "$.businessInfo.annualRevenue",
        requirementLevel: "REQUIRED",
        userInputDataType: "NUMBER"
      }]
    }.to_json)
  end
  subject(:fetcher) do
    described_class.new(api_client: api_client, request_id_generator: -> { "fields-req-1" })
  end

  it "fetches and validates the field configuration" do
    expect(api_client).to receive(:request).with(
      :get, "application/fields-config/APP-test-123",
      headers: { "x-request-id" => "fields-req-1" }
    ).and_return(response)
    expect(fetcher.call(application_id: "APP-test-123").first["requirementLevel"]).to eq("REQUIRED")
  end

  it "rejects malformed application IDs before making a request" do
    expect { fetcher.call(application_id: "not-an-app") }.to raise_error(ArgumentError)
    expect(api_client).not_to have_received(:request)
  end

  it "rejects invalid configuration entries" do
    invalid = instance_double(Net::HTTPOK, code: "200", body: {
      applicationId: "APP-test-123",
      fieldsConfig: [{ fieldPath: "FIELD", jsonPath: "$.x", requirementLevel: "MANDATORY", userInputDataType: "STRING" }]
    }.to_json)
    allow(api_client).to receive(:request).and_return(invalid)
    expect { fetcher.call(application_id: "APP-test-123") }.to raise_error(described_class::ProviderError)
  end
end
