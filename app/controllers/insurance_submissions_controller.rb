class InsuranceSubmissionsController < ApplicationController
  before_action :require_authentication
  before_action :require_submission_write_access, only: %i[new create submit]
  before_action :set_submission, only: %i[show submit]

  def index
    @submissions = current_agency.insurance_submissions.includes(:customer).order(created_at: :desc)
  end

  def new
    @customer = current_agency.customers.find(params[:customer_id])
    @submission = current_agency.insurance_submissions.new(customer: @customer)
  end

  def create
    @customer = current_agency.customers.find(params[:customer_id])
    @submission = current_agency.insurance_submissions.new(submission_params)
    @submission.customer = @customer
    @submission.creator = current_user

    if @submission.save
      record_audit("insurance_submission.created", @submission)
      redirect_to insurance_submission_path(@submission), notice: "Insurance application created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @market_submissions = current_agency.market_submissions
      .includes(:carrier)
      .where(insurance_submission: @submission)
      .order(created_at: :asc)
  end

  def submit
    unless @submission.effective_date.present? && @submission.state.present?
      redirect_to insurance_submission_path(@submission),
        alert: "Add an effective date and state before submitting to markets."
      return
    end

    @submission.update!(status: "ready")
    result = SubmitInsuranceSubmission.new(@submission).call
    record_audit("insurance_submission.marketed", @submission, queued_markets: result.queued_market_submission_ids.size)

    redirect_to insurance_submission_path(@submission),
      notice: "Application sent to #{result.queued_market_submission_ids.size} configured market(s). Carrier responses will appear here."
  rescue ArgumentError => error
    redirect_to insurance_submission_path(@submission), alert: error.message
  end

  private

  def set_submission
    @submission = current_agency.insurance_submissions.find(params[:id])
  end

  def submission_params
    params.require(:insurance_submission).permit(
      :line_of_business, :effective_date, :expiration_date, :state
    )
  end

  def require_submission_write_access
    return unless current_membership&.role == "read_only"

    redirect_to insurance_submissions_path, alert: "Your role has view-only access."
  end

  def record_audit(action, record, metadata = {})
    AuditEvent.create!(
      agency: current_agency,
      user: current_user,
      action: action,
      record_type: record.class.name,
      record_id: record.id,
      request_id: request.request_id,
      metadata: metadata
    )
  end
end
