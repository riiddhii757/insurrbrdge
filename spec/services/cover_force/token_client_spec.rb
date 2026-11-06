require "rails_helper"

RSpec.describe CoverForce::TokenClient do
  let(:current_time) { [Time.utc(2026, 11, 5, 15, 0, 0)] }
  let(:clock) { -> { current_time.first } }
  let(:http) { instance_double(Net::HTTP) }
  let(:response) do
    instance_double(
      Net::HTTPOK,
      code: "200",
      body: {
        access_token: "sandbox-token-example",
        expires_in: 3600,
        token_type: "Bearer"
      }.to_json
    )
  end

  subject(:client) do
    described_class.new(
      environment: "sandbox",
      client_id: "client-id",
      client_secret: "client-secret",
      clock: clock,
      request_id_generator: -> { "insurrbrdge-test-request" }
    )
  end

  before do
    allow(response).to receive(:[]).with("x-request-id").and_return("coverforce-request-123")
    allow(http).to receive(:request).and_return(response)
    allow(Net::HTTP).to receive(:start).and_yield(http)
  end

  it "posts client credentials to the root auth endpoint using HTTP Basic" do
    expect(Net::HTTP).to receive(:start).with(
      "sandbox.api.coverforce.com",
      443,
      hash_including(use_ssl: true, open_timeout: 5, read_timeout: 15)
    ).and_yield(http)

    expect(client.access_token).to eq("sandbox-token-example")

    expect(http).to have_received(:request) do |request|
      expect(request.method).to eq("POST")
      expect(request.path).to eq("/auth")
      expect(request["Authorization"]).to eq(
        "Basic #{Base64.strict_encode64("client-id:client-secret")}"
      )
      expect(request["Accept"]).to eq("application/json")
      expect(request["Content-Type"]).to eq("application/x-www-form-urlencoded")
      expect(request["x-request-id"]).to eq("insurrbrdge-test-request")
      expect(request.body).to eq("grant_type=client_credentials")
    end
  end

  it "returns a bearer authorization header" do
    expect(client.authorization_header).to eq("Bearer sandbox-token-example")
  end

  it "caches the token and refreshes before expires_in elapses" do
    second_response = instance_double(
      Net::HTTPOK,
      code: "200",
      body: { access_token: "refreshed-token", expires_in: 3600, token_type: "Bearer" }.to_json
    )
    allow(second_response).to receive(:[]).with("x-request-id").and_return("coverforce-request-456")
    expect(http).to receive(:request).twice.and_return(response, second_response)

    expect(client.access_token).to eq("sandbox-token-example")
    expect(client.access_token).to eq("sandbox-token-example")

    # 60 seconds before expiry is the refresh boundary for a one-hour token.
    current_time[0] += 3541
    expect(client.access_token).to eq("refreshed-token")
  end

  it "fails closed when credentials are missing" do
    unconfigured = described_class.new(environment: "sandbox", client_id: "", client_secret: "")
    expect { unconfigured.access_token }
      .to raise_error(described_class::AuthenticationError, /credentials are not configured/)
  end

  it "rejects unsupported environments" do
    expect { described_class.new(environment: "staging") }
      .to raise_error(ArgumentError, /sandbox or production/)
  end
end
