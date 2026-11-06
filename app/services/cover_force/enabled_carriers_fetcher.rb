require "json"
require "securerandom"

module CoverForce
  class EnabledCarriersFetcher
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
                   network_headers: {}, request_id_generator: -> { SecureRandom.uuid })
      @api_client = api_client
      @api_client_id = api_client_id
      @network_headers = network_headers
      @request_id_generator = request_id_generator
    end

    def call
      headers = { "x-request-id" => @request_id_generator.call }
      headers["x-api-client-id"] = @api_client_id if @api_client_id.present?
      @network_headers.each { |key, value| headers[key.to_s] = value if value.present? }

      response = @api_client.request(:get, "enabled-carriers", headers: headers)
      payload = JSON.parse(response.body)
      infos = payload.fetch("enabledCarriersInfos")
      valid = payload["agencyOrNetworkId"].is_a?(String) &&
        infos.is_a?(Array) && infos.all? do |info|
          info.is_a?(Hash) &&
            POLICY_TYPES.include?(info["policyTypeId"]) &&
            info["enabledCarriers"].is_a?(Array) &&
            (info["enabledCarriers"] - CARRIERS).empty?
        end

      unless response.code.to_i.between?(200, 299) && valid
        raise ProviderError.new(
          "CoverForce enabled-carriers request failed (HTTP #{response.code})",
          status: response.code.to_i, request_id: response["x-request-id"], body: payload
        )
      end

      payload
    rescue JSON::ParserError, KeyError
      raise ProviderError.new(
        "CoverForce returned an invalid enabled-carriers response",
        status: response&.code&.to_i, request_id: response&.[]("x-request-id"),
        body: response&.body
      )
    end
  end
end
