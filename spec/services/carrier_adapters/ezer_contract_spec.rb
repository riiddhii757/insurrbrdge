require "rails_helper"

RSpec.describe CarrierAdapters::EzerContract do
  let(:customer) { Customer.new(legal_name: "Northstar Coffee LLC") }
  let(:submission) do
    InsuranceSubmission.new(
      customer: customer,
      reference: "IB-TEST12345",
      line_of_business: "general_liability",
      state: "NY",
      effective_date: Date.new(2027, 1, 1),
      expiration_date: Date.new(2028, 1, 1)
    )
  end

  describe "#to_h" do
    it "maps known InsurrBrdge fields into a canonical commercial risk envelope" do
      payload = described_class.new(submission).to_h

      expect(payload.dig("product", "lineOfBusiness")).to eq("COMMERCIAL")
      expect(payload.dig("risk", "business", "legalName")).to eq("Northstar Coffee LLC")
      expect(payload.dig("risk", "location", "state")).to eq("NY")
      expect(payload.dig("policy", "effectiveDate")).to eq("2027-01-01")
      expect(payload.dig("metadata", "submissionReference")).to eq("IB-TEST12345")
    end

    it "does not invent exposure or coverage data that the application does not collect" do
      payload = described_class.new(submission).to_h

      expect(payload.dig("risk", "business")).to eq("legalName" => "Northstar Coffee LLC")
      expect(payload).not_to have_key("premium")
      expect(payload).not_to have_key("coverages")
    end
  end

  describe "validation" do
    it "rejects incomplete applications rather than sending guessed values" do
      submission.state = nil

      expect { described_class.new(submission).to_h }
        .to raise_error(described_class::InvalidRisk, /risk state/)
    end

    it "rejects unsupported lines" do
      submission.line_of_business = "personal_auto"

      expect { described_class.new(submission).to_h }
        .to raise_error(described_class::InvalidRisk, /unsupported commercial line/)
    end

    it "rejects an expiration date that is not after the effective date" do
      submission.expiration_date = submission.effective_date

      expect { described_class.new(submission).to_h }
        .to raise_error(described_class::InvalidRisk, /expiration date must be after effective date/)
    end
  end
end
