class CustomersController < ApplicationController
  before_action :require_authentication
  before_action :require_customer_write_access, only: %i[new create edit update destroy]
  before_action :set_customer, only: %i[show edit update destroy]

  def index
    @customers = current_agency.customers.order(updated_at: :desc)
  end

  def show
    @submissions = current_agency.insurance_submissions.where(customer_id: @customer.id).order(created_at: :desc)
  end

  def new
    @customer = current_agency.customers.new
  end

  def create
    @customer = current_agency.customers.new(customer_params)
    if @customer.save
      record_audit("customer.created", @customer)
      redirect_to customer_path(@customer), notice: "Customer account created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @customer.update(customer_params)
      record_audit("customer.updated", @customer)
      redirect_to customer_path(@customer), notice: "Customer account updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @customer.destroy!
    record_audit("customer.deleted", @customer)
    redirect_to customers_path, notice: "Customer account deleted."
  rescue ActiveRecord::DeleteRestrictionError
    redirect_to customer_path(@customer), alert: "This customer has submissions and cannot be deleted."
  end

  private

  def set_customer
    @customer = current_agency.customers.find(params[:id])
  end

  def customer_params
    params.require(:customer).permit(:legal_name, :dba_name, :entity_type, :industry, :website, :email, :phone, :status)
  end

  def require_customer_write_access
    return unless current_membership&.role == "read_only"

    redirect_to customers_path, alert: "Your role has view-only access."
  end

  def record_audit(action, record)
    AuditEvent.create!(
      agency: current_agency,
      user: current_user,
      action: action,
      record_type: record.class.name,
      record_id: record.id,
      request_id: request.request_id
    )
  end
end
