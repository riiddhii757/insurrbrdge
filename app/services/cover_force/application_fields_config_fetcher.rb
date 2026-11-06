require "json"
require "securerandom"

module CoverForce
  class ApplicationFieldsConfigFetcher
    class ProviderError < StandardError
      attr_reader :status, :request_id, :body

      def initialize(message, status:, request_id:, body:)
        super(message)
        @status, @request_id, @body = status, request_id, body
      end
    end

    REQUIREMENT_LEVELS = %w[REQUIRED OPTIONAL NOT_ACCEPTED].freeze
    INPUT_TYPES = %w[STRING NUMBER BOOLEAN].freeze

    def initialize(api_client: ApiClient.new, request_id_generator: -> { SecureRandom.uuid })
      @api_client = api_client
      @request_id_generator = request_id_generator
    end

    def call(application_id:)
      unless application_id.to_s.match?(/\AAPP-[A-Za-z0-9-]+\z/)
        raise ArgumentError, "A valid CoverForce application ID is required"
      end

      response = @api_client.request(
        :get, "application/fields-config/#{URI.encode_www_form_component(application_id)}",
        headers: { "x-request-id" => @request_id_generator.call }
      )
      payload = JSON.parse(response.body)
      fields = payload["fieldsConfig"]
      valid = response.code.to_i == 200 &&
        payload["applicationId"] == application_id &&
        fields.is_a?(Array) && fields.all? do |field|
          field.is_a?(Hash) &&
            field["fieldPath"].is_a?(String) &&
            field["jsonPath"].is_a?(String) &&
            REQUIREMENT_LEVELS.include?(field["requirementLevel"]) &&
            INPUT_TYPES.include?(field["userInputDataType"])
        end

      unless valid
        raise ProviderError.new(
          "CoverForce fields configuration request failed (HTTP #{response.code})",
          status: response.code.to_i, request_id: response["x-request-id"], body: payload
        )
      end
      fields
    rescue JSON::ParserError
      raise ProviderError.new(
        "CoverForce returned an unreadable fields configuration response",
        status: response&.code&.to_i, request_id: response&.[]("x-request-id"),
        body: response&.body
      )
    end
  end
end
