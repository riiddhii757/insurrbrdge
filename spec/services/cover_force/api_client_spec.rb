require "rails_helper"

RSpec.describe CoverForce::ApiClient do
  let(:token_client) do
    instance_double(
      CoverForce::TokenClient,
      base_url: "https://sandbox.api.coverforce.com",
      authorization_header: "Bearer first-token"
    )
  end
  let(:http) { instance_double(Net::HTTP) }
  let(:success) { instance_double(Net::HTTPOK, code: "200", body: '{"id":"APP-123"}') }
  let(:unauthorized) { instance_double(Net::HTTPUnauthorized, code: "401", body: '{"error":"unauthorized"}') }

  subject(:client) { described_class.new(token_client: token_client) }

  before do
    allow(Net::HTTP).to receive(:start).and_yield(http)
  end

  it "sends bearer authorization to protected resources under /api" do
    expect(http).to receive(:request).with(instance_of(Net::HTTP::Get)).and_return(success)
    response = client.request(:get, "/application/APP-123")

    expect(response).to eq(success)
    expect(Net::HTTP).to have_received(:start).with(
      "sandbox.api.coverforce.com", 443,
      hash_including(use_ssl: true, open_timeout: 5, read_timeout: 30)
    )
    expect(token_client).to have_received(:authorization_header)
  end

  it "fetches a fresh token and retries exactly once after a 401" do
    expect(http).to receive(:request).twice.and_return(unauthorized, success)
    expect(token_client).to receive(:invalidate_token!).once
    expect(token_client).to receive(:authorization_header).twice.and_return(
      "Bearer expired-token", "Bearer fresh-token"
    )

    response = client.request(:get, "application/APP-123")

    expect(response).to eq(success)
  end

  it "does not retry more than once when the refreshed token is rejected" do
    expect(http).to receive(:request).twice.and_return(unauthorized, unauthorized)
    expect(token_client).to receive(:invalidate_token!).once

    response = client.request(:get, "application/APP-123")

    expect(response).to eq(unauthorized)
  end

  it "rejects absolute URLs and path traversal" do
    expect { client.request(:get, "https://example.com/api/application") }
      .to raise_error(ArgumentError)
    expect { client.request(:get, "../auth") }.to raise_error(ArgumentError)
  end

  it "rejects unsupported HTTP methods" do
    expect { client.request(:head, "application/APP-123") }
      .to raise_error(ArgumentError, /Unsupported HTTP method/)
  end
end
