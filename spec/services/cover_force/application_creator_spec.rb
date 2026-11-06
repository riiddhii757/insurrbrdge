require "rails_helper"

RSpec.describe CoverForce::ApplicationCreator do
  let(:api_client) { instance_double(CoverForce::ApiClient) }
  let(:response) do
    instance_double(
      Net::HTTPCreated, code: "201",
      body: { applicationId: "APP-test-123" }.to_json
    )
  end
  subject(:creator) do
    described_class.new(
      api_client: api_client, api_client_id: "test-client",
      request_id_generator: -> { "req-create-1" }
    )
  end

  let(:valid_arguments) do
    {
      policy_type: "BOP", business_name: "Example Manufacturing",
      email: "owner@example.com", phone: "+18886665590",
      carriers: ["CHUBB", "NATIONWIDE"],
      broker_configurations: [
        { carrier_id: "CHUBB", broker_configuration_id: "BC-real-chubb" },
        { carrier_id: "NATIONWIDE", broker_configuration_id: "BC-real-nationwide" }
      ],
      first_name: "Jane", last_name: "Owner", client_reference_id: "IB-123"
    }
  end

  it "creates an application using the documented endpoint and returns its id" do
    expect(api_client).to receive(:request) do |method, path, headers:, body:|
      expect(method).to eq(:post)
      expect(path).to eq("application")
      expect(headers).to include(
        "Content-Type" => "application/json",
        "x-api-client-id" => "test-client",
        "x-request-id" => "req-create-1"
      )
      payload = JSON.parse(body)
      expect(payload).to include(
        "policyType" => "BOP", "businessName" => "Example Manufacturing",
        "email" => "owner@example.com", "phone" => "+18886665590",
        "carriers" => ["CHUBB", "NATIONWIDE"], "clientReferenceId" => "IB-123"
      )
      expect(payload["brokerConfigurations"]).to contain_exactly(
        { "carrierId" => "CHUBB", "brokerConfigurationId" => "BC-real-chubb" },
        { "carrierId" => "NATIONWIDE", "brokerConfigurationId" => "BC-real-nationwide" }
      )
      response
    end

    expect(creator.call(**valid_arguments)["applicationId"]).to eq("APP-test-123")
  end

  it "refuses to create when a carrier lacks its own broker configuration" do
    arguments = valid_arguments.merge(broker_configurations: [
      { carrier_id: "CHUBB", broker_configuration_id: "BC-real-chubb" }
    ])
    expect { creator.call(**arguments) }.to raise_error(
      described_class::InvalidRequest, /one valid broker configuration/
    )
    expect(api_client).not_to have_received(:request)
  end

  it "rejects an unsupported carrier before calling CoverForce" do
    expect {
      creator.call(**valid_arguments.merge(carriers: ["FAKE_CARRIER"]))
    }.to raise_error(described_class::InvalidRequest)
    expect(api_client).not_to have_received(:request)
  end

  it "requires the onboarding API client id" do
    missing_id = described_class.new(api_client: api_client, api_client_id: nil)
    expect { missing_id.call(**valid_arguments) }.to raise_error(
      described_class::InvalidRequest, /API client ID/
    )
  end
end
