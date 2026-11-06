class SubmitMarketJob < ApplicationJob
  queue_as :default

  def perform(market_submission_id)
    market_submission = MarketSubmission.includes(:carrier, :insurance_submission).find(market_submission_id)
    return if %w[submitted quoted declined bound].include?(market_submission.status)

    market_submission.update!(status: "submitting")
    response = CarrierAdapters::Registry.fetch(market_submission.carrier)
      .submit(market_submission.insurance_submission, market_submission: market_submission)

    market_submission.update!(
      status: response.status,
      carrier_reference: response.carrier_reference,
      environment: response.environment,
      appetite_result: response.appetite_result || {},
      response_metadata: { "message" => response.message },
      responded_at: Time.current
    )
    record_response_audit(market_submission)
    RefreshInsuranceSubmissionStatus.call(market_submission.insurance_submission)
  rescue CarrierAdapters::Registry::AdapterNotConfigured => error
    mark_market_error(market_submission, "Integration not configured: #{error.message}")
  rescue StandardError => error
    mark_market_error(market_submission, "Adapter error: #{error.class.name}")
    raise
  end

  private

  def record_response_audit(market_submission)
    AuditEvent.create!(
      agency: market_submission.agency,
      action: "market_submission.responded",
      record_type: "MarketSubmission",
      record_id: market_submission.id,
      metadata: {
        "carrier_id" => market_submission.carrier_id,
        "status" => market_submission.status,
        "environment" => market_submission.environment
      }
    )
  end

  def mark_market_error(market_submission, reason)
    return unless market_submission

    market_submission.update!(
      status: "error",
      failure_reason: reason,
      responded_at: Time.current
    )
    record_response_audit(market_submission)
    RefreshInsuranceSubmissionStatus.call(market_submission.insurance_submission)
  end
end
