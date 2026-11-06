class SubmitMarketJob < ApplicationJob
  queue_as :default

  def perform(market_submission_id)
    market_submission = MarketSubmission.includes(:carrier, :insurance_submission).find(market_submission_id)
    return if %w[submitted quoted declined bound].include?(market_submission.status)

    market_submission.update!(status: "submitting")
    adapter = CarrierAdapters::Registry.fetch(market_submission.carrier)
    response = adapter.submit(market_submission.insurance_submission, market_submission: market_submission)

    market_submission.update!(
      status: response.status,
      carrier_reference: response.carrier_reference,
      environment: response.environment,
      appetite_result: response.appetite_result || {},
      response_metadata: { "message" => response.message },
      responded_at: Time.current
    )
  rescue CarrierAdapters::Registry::AdapterNotConfigured => error
    market_submission&.update!(
      status: "error",
      failure_reason: "Integration not configured: #{error.message}",
      responded_at: Time.current
    )
  end
end
