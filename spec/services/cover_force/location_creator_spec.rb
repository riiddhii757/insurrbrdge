require "rails_helper"

RSpec.describe CoverForce::LocationCreator do
  let(:api_client) { instance_double(CoverForce::ApiClient) }
  let(:response) do
    instance_double(Net::HTTPCreated, code: "201",
      body: { locationId: "LOC-test-123", address: { city: "New York" }, isPrimary: true }.to_json)
  end
  subject(:creator) do
    described_class.new(api_client: api_client, request_id_generator: -> { "loc-req-1" })
  end

  let(:valid_arguments) do
    {
      application_id: "APP-test-123",
      address: { address_line1: "123 Main St", city: "New York", state: "NY", zip: "10001" },
      is_primary: true
    }
  end

  it "posts the location and returns its provider location ID" do
    expect(api_client).to receive(:request).with(
      :post, "location/APP-test-123",
      headers: { "Content-Type" => "application/json", "x-request-id" => "loc-req-1" },
      body: {
        address: { addressLine1: "123 Main St", city: "New York", state: "NY", zip: "10001" },
        isPrimary: true
      }.to_json
    ).and_return(response)

    expect(creator.call(**valid_arguments)["locationId"]).to eq("LOC-test-123")
  end

  it "requires valid address fields and ZIP format before sending" do
    expect {
      creator.call(**valid_arguments.merge(address: { address_line1: "1 Main", city: "NY", state: "XX", zip: "10001" }))
    }.to raise_error(described_class::InvalidRequest, /state/)
    expect {
      creator.call(**valid_arguments.merge(address: { address_line1: "1 Main", city: "NY", state: "NY", zip: "bad" }))
    }.to raise_error(described_class::InvalidRequest, /ZIP/)
    expect(api_client).not_to have_received(:request)
  end

  it "validates employee payroll records and job code IDs" do
    employee = {
      num_part_time_employees: 2, num_full_time_employees: 5,
      total_employee_payroll: 250000, job_code_id: "job-code-ny"
    }
    expect(api_client).to receive(:request).and_return(response)
    creator.call(**valid_arguments, employee_infos: [employee])
  end

  it "rejects incomplete employee records" do
    expect {
      creator.call(**valid_arguments, employee_infos: [{ num_full_time_employees: 3 }])
    }.to raise_error(described_class::InvalidRequest, /Employee info requires/)
    expect(api_client).not_to have_received(:request)
  end
end
