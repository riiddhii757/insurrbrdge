module CarrierAdapters
  class DemoAdapter < Base
    SCENARIOS = {
      "demo-preferred-market" => {
        status: "eligible",
        decision: "eligible",
        reason: "The sample risk fits this demo market's configured appetite."
      },
      "demo-referral-market" => {
        status: "referred",
        decision: "refer",
        reason: "The sample risk requires a human underwriter review."
      },
      "demo-outside-appetite" => {
        status: "ineligible",
        decision: "ineligible",
        reason: "The sample risk falls outside this demo market's configured appetite."
      }
    }.freeze

    def submit(_insurance_submission, market_submission:)
      scenario = SCENARIOS.fetch(
        market_submission.carrier.slug,
        {
          status: "needs_information",
          decision: "refer",
          reason: "Demo market requires additional broker information."
        }
      )

      Result.new(
        status: scenario.fetch(:status),
        carrier_reference: "DEMO-#{market_submission.id}",
        environment: "demo",
        appetite_result: {
          "decision" => scenario.fetch(:decision),
          "reason" => scenario.fetch(:reason),
          "simulated" => true
        },
        quote_attributes: nil,
        message: "DEMO / SIMULATED: #{scenario.fetch(:reason)} No quote or premium was produced."
      )
    end
  end
end
