require "json"
require "securerandom"

module CoverForce
  class ApplicationCreator
    class InvalidRequest < StandardError; end
    class ProviderError < StandardError
      attr_reader :status, :request_id, :body

      def initialize(message, status:, request_id:, body:)
        super(message)
        @status = status
        @request_id = request_id
        @body = body
      end
    end

    CARRIERS = AppetiteChecker::CARRIERS
    POLICY_TYPES = AppetiteChecker::POLICY_TYPES

    def initialize(api_client: ApiClient.new, api_client_id: ENV["COVERFORCE_API_CLIENT_ID"],
                   request_id_generator: -> { SecureRandom.uuid })
      @api_client = api_client
      @api_client_id = api_client_id
      @request_id_generator = request_id_generator
    end

    # broker_configurations must be supplied by the agency's verified appointment
    # setup. This service never invents or defaults broker codes.
    def call(policy_type:, business_name:, email:, phone:, carriers:,
             broker_configurations:, first_name: nil, last_name: nil,
             client_reference_id: nil, is_renewal: false)
      payload = {
        policyType: policy_type.to_s,
        businessName: business_name.to_s.strip,
        email: email.to_s.strip,
        phone: phone.to_s.strip,
        carriers: Array(carriers).map(&:to_s).uniq,
        brokerConfigurations: normalize_broker_configurations(broker_configurations),
        clientReferenceId: client_reference_id,
        isRenewal: !!is_renewal
      }
      payload[:firstName] = first_name.to_s.strip if first_name.present?
      payload[:lastName] = last_name.to_s.strip if last_name.present?
      payload.delete(:clientReferenceId) if client_reference_id.blank?
      validate!(payload)

      headers = {
        "Content-Type" => "application/json",
        "x-request-id" => @request_id_generator.call
      }
      headers["x-api-client-id"] = @api_client_id if @api_client_id.present?

      response = @api_client.request(
        :post, "application", headers: headers, body: JSON.generate(payload)
      )
      parsed = JSON.parse(response.body)
      unless response.code.to_i == 201 && parsed["applicationId"].is_a?(String) &&
             parsed["applicationId"].start_with?("APP-")
        raise ProviderError.new(
          "CoverForce application creation failed (HTTP #{response.code})",
          status: response.code.to_i, request_id: response["x-request-id"], body: parsed
        )
      end
      parsed
    rescue JSON::ParserError
      raise ProviderError.new(
        "CoverForce returned an unreadable application response",
        status: response&.code&.to_i, request_id: response&.[]("x-request-id"),
        body: response&.body
      )
    end

    private

    def normalize_broker_configurations(configurations)
      Array(configurations).map do |configuration|
        values = configuration.to_h.transform_keys(&:to_sym)
        {
          carrierId: values[:carrierId] || values[:carrier_id],
          brokerConfigurationId: values[:brokerConfigurationId] || values[:broker_configuration_id]
        }
      end
    end

    def validate!(payload)
      raise InvalidRequest, "CoverForce API client ID is not configured" if @api_client_id.blank?
      raise InvalidRequest, "Business name is required" if payload[:businessName].blank?
      raise InvalidRequest, "A valid contact email is required" unless payload[:email].match?(/\A[^\s@]+@[^\s@]+\.[^\s@]+\z/)
      raise InvalidRequest, "Contact phone is required" if payload[:phone].blank?
      raise InvalidRequest, "Unsupported CoverForce policy type" unless POLICY_TYPES.include?(payload[:policyType])
      raise InvalidRequest, "Select at least one supported carrier" if payload[:carriers].empty?
      unknown = payload[:carriers] - CARRIERS
      raise InvalidRequest, "Unsupported CoverForce carrier(s): #{unknown.join(', ')}" if unknown.any?

      configs = payload[:brokerConfigurations]
      configured_carriers = configs.map { |item| item[:carrierId] }
      unless configs.length == payload[:carriers].length &&
             configured_carriers.sort == payload[:carriers].sort &&
             configs.all? { |item|
               CARRIERS.include?(item[:carrierId]) &&
                 item[:brokerConfigurationId].is_a?(String) &&
                 !item[:brokerConfigurationId].strip.empty?
             }
        raise InvalidRequest, "Provide exactly one valid broker configuration for every selected carrier"
      end
    end
  end
end
