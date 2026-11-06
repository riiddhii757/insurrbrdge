module CarrierAdapters
  class DemoAdapter < Base
    def submit(insurance_submission, market_submission:)
      Result.new(
        status: "needs_information",
        carrier_reference: "DEMO-#{market_submission.id}",
        environment: "demo",
        appetite_result: {
          "decision" => "refer",
          "reason" => "Demo adapter requires broker review",
          "simulated" => true
        },
        quote_attributes: nil,
        message: "DEMO / SIMULATED: no carrier quote was requested or produced."
      )
    end
  end
end
