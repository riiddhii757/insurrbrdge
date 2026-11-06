# Copyright (c) 2026 Wolf Surety Inc. EZer concepts are used under the MIT License.
# This is an InsurrBrdge-side canonical mapping inspired by EZer; it is not a
# claim of EZer protocol conformance or a carrier-supported endpoint.
module CarrierAdapters
  class EzerContract
    class InvalidRisk < StandardError
      attr_reader :errors

      def initialize(errors)
        @errors = errors
        super("Insurance risk is incomplete: #{errors.join(', ')}")
      end
    end

    COMMERCIAL_LINES = %w[
      general_liability
      commercial_property
      business_owners
      workers_compensation
      commercial_auto
      professional_liability
    ].freeze

    LINE_CODES = {
      "general_liability" => "COMMERCIAL",
      "commercial_property" => "COMMERCIAL",
      "business_owners" => "COMMERCIAL",
      "workers_compensation" => "COMMERCIAL",
      "commercial_auto" => "COMMERCIAL",
      "professional_liability" => "COMMERCIAL"
    }.freeze

    def initialize(insurance_submission)
      @submission = insurance_submission
    end

    def to_h
      validate!

      {
        "product" => {
          "lineOfBusiness" => LINE_CODES.fetch(@submission.line_of_business)
        },
        "risk" => {
          "business" => {
            "legalName" => @submission.customer.legal_name
          },
          "location" => {
            "state" => @submission.state
          }
        },
        "policy" => {
          "effectiveDate" => @submission.effective_date.iso8601,
          "expirationDate" => @submission.expiration_date&.iso8601
        },
        "metadata" => {
          "submissionReference" => @submission.reference,
          "source" => "insurrbrdge"
        }
      }.deep_stringify_keys
    end

    private

    def validate!
      errors = []
      errors << "unsupported commercial line" unless COMMERCIAL_LINES.include?(@submission.line_of_business)
      errors << "business legal name" if @submission.customer&.legal_name.blank?
      errors << "risk state" if @submission.state.blank?
      errors << "effective date" if @submission.effective_date.blank?

      if @submission.effective_date && @submission.expiration_date &&
          @submission.expiration_date <= @submission.effective_date
        errors << "expiration date must be after effective date"
      end

      raise InvalidRisk, errors if errors.any?
    end
  end
end
