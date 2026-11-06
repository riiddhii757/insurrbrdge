module CarrierAdapters
  class Base
    Result = Data.define(
      :status,
      :carrier_reference,
      :environment,
      :appetite_result,
      :quote_attributes,
      :message
    )

    def submit(_insurance_submission, _market_submission:)
      raise NotImplementedError, "#{self.class} must implement #submit"
    end

    private

    def result(**attributes)
      Result.new(**attributes)
    end
  end
end
