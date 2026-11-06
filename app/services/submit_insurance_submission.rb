class SubmitInsuranceSubmission
  Result = Data.define(:queued_market_submission_ids, :skipped_carrier_names)

  def initialize(insurance_submission)
    @insurance_submission = insurance_submission
  end

  def call
    queued_ids = []
    skipped_names = []

    ActiveRecord::Base.transaction do
      submission = InsuranceSubmission.lock.find(@insurance_submission.id)
      raise ArgumentError, "Submission must be ready before marketing" unless %w[ready marketing partially_quoted quoted].include?(submission.status)

      carriers = Carrier.where(integration_status: %w[sandbox_ready production_pending live])
      carriers.find_each do |carrier|
        unless carrier.supported_lines.include?(submission.line_of_business)
          skipped_names << carrier.name
          next
        end

        market_submission = MarketSubmission.find_or_create_by!(
          agency: submission.agency,
          insurance_submission: submission,
          carrier: carrier
        ) do |record|
          record.status = "queued"
          record.environment = carrier.environment == "demo" ? "demo" : "sandbox"
          record.correlation_id = SecureRandom.uuid
        end
        queued_ids << market_submission.id if market_submission.status == "queued"
      end

      submission.update!(status: "marketing")
    end

    queued_ids.each { |id| SubmitMarketJob.perform_later(id) }
    Result.new(queued_market_submission_ids: queued_ids, skipped_carrier_names: skipped_names)
  end

  private

  attr_reader :insurance_submission
end
