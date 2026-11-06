class WorkspaceController < ApplicationController
  before_action :require_authentication

  def show
    @customers = current_agency.customers.order(created_at: :desc).limit(5)
    @submissions = current_agency.insurance_submissions.includes(:customer).order(created_at: :desc).limit(8)
    @customer_count = current_agency.customers.count
    @submission_count = current_agency.insurance_submissions.count
    @quote_count = current_agency.quotes.count
    @carrier_count = Carrier.where(integration_status: %w[live sandbox_ready]).count
  end
end
