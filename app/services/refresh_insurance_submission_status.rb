class RefreshInsuranceSubmissionStatus
  IN_FLIGHT_STATUSES = %w[queued submitting].freeze
  NEEDS_ATTENTION_STATUSES = %w[needs_information referred error].freeze
  DECLINED_STATUSES = %w[ineligible declined].freeze
  RESOLVED_WITHOUT_QUOTE = %w[eligible ineligible declined].freeze

  def self.call(submission)
    submission.with_lock do
      statuses = submission.market_submissions.pluck(:status)
      return if statuses.empty? || (statuses & IN_FLIGHT_STATUSES).any?

      final_status =
        if statuses.include?("quoted") && statuses.all? { |status| (RESOLVED_WITHOUT_QUOTE + ["quoted"]).include?(status) }
          "quoted"
        elsif statuses.include?("quoted")
          "partially_quoted"
        elsif statuses.all? { |status| DECLINED_STATUSES.include?(status) }
          "declined"
        elsif (statuses & NEEDS_ATTENTION_STATUSES).any?
          "needs_information"
        else
          "markets_reviewed"
        end

      submission.update!(status: final_status)
    end
  end
end
