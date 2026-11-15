class InsuranceSubmissionsController < ApplicationController
  before_action :require_authentication
  before_action :require_submission_write_access, only: %i[new create edit update submit]
  before_action :set_submission, only: %i[show edit update submit]
  before_action :ensure_editable_submission, only: %i[edit update]

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

  def edit
  end

  def update
    if @submission.update(submission_params)
      record_audit("insurance_submission.updated", @submission)
      redirect_to insurance_submission_path(@submission), notice: "Insurance application updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def show
    @market_submissions = current_agency.market_submissions.includes(:carrier, :quotes)
      .where(insurance_submission: @submission).order(created_at: :asc)
    @quotes = @market_submissions.flat_map(&:quotes)
  end

  def submit
    unless @submission.effective_date.present? && @submission.state.present?
      redirect_to insurance_submission_path(@submission), alert: "Add an effective date and state before submitting to markets."
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

  def ensure_editable_submission
    return if %w[draft ready].include?(@submission.status)
    redirect_to insurance_submission_path(@submission),
      alert: "This application can no longer be edited after market submission."
  end

  def submission_params
    params.require(:insurance_submission).permit(
      :line_of_business, :effective_date, :expiration_date, :state, :underwriter_notes,
      business_details: %i[industry entity_type website annual_revenue employee_count],
      exposures: %i[annual_payroll annual_sales subcontractor_costs locations_count square_footage],
      requested_coverages: %i[each_occurrence general_aggregate products_completed_operations personal_advertising_injury property_limit property_deductible]
    )
  end

  def require_submission_write_access
    return unless current_membership&.role == "read_only"
    redirect_to insurance_submissions_path, alert: "Your role has view-only access."
  end

  def record_audit(action, record, metadata = {})
    AuditEvent.create!(
      agency: current_agency, user: current_user, action: action,
      record_type: record.class.name, record_id: record.id,
      request_id: request.request_id, metadata: metadata
    )
  end
end
