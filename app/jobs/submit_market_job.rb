class SubmitMarketJob < ApplicationJob
  queue_as :default

  QUOTE_FIELDS = %w[
    currency premium fees taxes effective_date expires_at coverages
    conditions exclusions source_metadata
  ].freeze

  def perform(market_submission_id)
    market_submission = MarketSubmission.includes(:carrier, :insurance_submission).find(market_submission_id)
    return if %w[submitted quoted declined bound].include?(market_submission.status)

    market_submission.update!(status: "submitting", submitted_at: Time.current)
    response = CarrierAdapters::Registry.fetch(market_submission.carrier)
      .submit(market_submission.insurance_submission, market_submission: market_submission)

    persist_quote!(market_submission, response) if response.quote_attributes.present?
    if response.status == "quoted" && response.quote_attributes.blank?
      raise ArgumentError, "Carrier marked the submission quoted without returning quote details"
    end

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

  def persist_quote!(market_submission, response)
    raw = response.quote_attributes
    raise ArgumentError, "Carrier quote details must be a hash" unless raw.is_a?(Hash)

    attributes = raw.stringify_keys
    reference = attributes.delete("carrier_quote_reference").to_s.strip
    raise ArgumentError, "Carrier quote reference is required for idempotent quote storage" if reference.empty?

    source = attributes.delete("source").presence || (response.environment == "demo" ? "demo" : "carrier")
    if (response.environment == "demo") != (source == "demo")
      raise ArgumentError, "Demo quote source and environment must be explicitly labeled"
    end

    quote = market_submission.quotes.find_or_initialize_by(carrier_quote_reference: reference)
    quote.assign_attributes(
      attributes.slice(*QUOTE_FIELDS).merge(
        "agency" => market_submission.agency,
        "source" => source,
        "environment" => response.environment,
        "status" => "received"
      )
    )
    quote.save!
  end

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
