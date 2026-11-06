require "rails_helper"

RSpec.describe CoverForce::EnabledCarriersFetcher do
  let(:api_client) { instance_double(CoverForce::ApiClient) }
  let(:response) do
    instance_double(
      Net::HTTPOK, code: "200", body: {
        agencyOrNetworkId: "AGENCY-123",
        enabledCarriersInfos: [
          { policyTypeId: "BOP", enabledCarriers: ["CHUBB", "NATIONWIDE"] },
          { policyTypeId: "WC", enabledCarriers: ["EMPLOYERS"] }
        ]
      }.to_json
    )
  end
  subject(:fetcher) do
    described_class.new(
      api_client: api_client, api_client_id: "client-123",
      request_id_generator: -> { "enabled-req-1" }
    )
  end

  it "retrieves enabled markets and returns the provider response" do
    expect(api_client).to receive(:request).with(
      :get, "enabled-carriers",
      headers: {
        "x-request-id" => "enabled-req-1",
        "x-api-client-id" => "client-123"
      }
    ).and_return(response)

    result = fetcher.call
    expect(result["enabledCarriersInfos"].first["enabledCarriers"]).to eq(["CHUBB", "NATIONWIDE"])
  end

  it "passes network-level headers only when explicitly configured" do
    network_fetcher = described_class.new(
      api_client: api_client, api_client_id: "client-123",
      network_headers: { "x-cf-agency-id" => "CF-AGENCY-1" },
      request_id_generator: -> { "req" }
    )
    expect(api_client).to receive(:request).with(
      :get, "enabled-carriers",
      headers: {
        "x-request-id" => "req", "x-api-client-id" => "client-123",
        "x-cf-agency-id" => "CF-AGENCY-1"
      }
    ).and_return(response)

    network_fetcher.call
  end

  it "rejects unknown carrier identifiers in the provider response" do
    invalid = instance_double(
      Net::HTTPOK, code: "200",
      body: { agencyOrNetworkId: "AGENCY-123",
              enabledCarriersInfos: [{ policyTypeId: "BOP", enabledCarriers: ["FAKE"] }] }.to_json,
      "[]" => "cf-invalid-response"
    )
    allow(api_client).to receive(:request).and_return(invalid)

    expect { fetcher.call }.to raise_error(described_class::ProviderError)
  end
end
