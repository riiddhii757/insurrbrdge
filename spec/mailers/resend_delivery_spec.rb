require "rails_helper"

RSpec.describe ResendDelivery do
  let(:mail) do
    Mail.new do
      from "InsurrBrdge <verified@example.com>"
      to "producer@example.com"
      subject "Verify your email"
      body "Please verify your account."
    end
  end

  it "sends a text email through the Resend HTTPS API" do
    response = Net::HTTPOK.new("1.1", "200", "OK")
    http = double("http")
    allow(Net::HTTP).to receive(:start).and_yield(http)
    expect(http).to receive(:request) do |request|
      expect(request).to be_a(Net::HTTP::Post)
      expect(request["Authorization"]).to eq("Bearer re_test_key")
      payload = JSON.parse(request.body)
      expect(payload).to include(
        "from" => "InsurrBrdge <verified@example.com>",
        "to" => ["producer@example.com"],
        "subject" => "Verify your email",
        "text" => "Please verify your account."
      )
      response
    end

    described_class.new(api_key: "re_test_key").deliver!(mail)
  end

  it "fails closed when the API key is missing" do
    expect {
      described_class.new(api_key: nil).deliver!(mail)
    }.to raise_error(ResendDelivery::DeliveryError, "RESEND_API_KEY is not configured")
  end

  it "raises a sanitized error when Resend rejects the message" do
    response = Net::HTTPUnprocessableEntity.new("1.1", "422", "Unprocessable Entity")
    http = double("http")
    allow(Net::HTTP).to receive(:start).and_yield(http)
    allow(http).to receive(:request).and_return(response)

    expect {
      described_class.new(api_key: "re_test_key").deliver!(mail)
    }.to raise_error(ResendDelivery::DeliveryError, "Resend email request failed (HTTP 422)")
  end
end
