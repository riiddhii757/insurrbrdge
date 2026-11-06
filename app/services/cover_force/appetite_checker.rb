require "json"
require "securerandom"

module CoverForce
  class AppetiteChecker
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

    CARRIERS = %w[
      ACCIDENTFUND AMTRUST ATLANTIC_CASUALTY BERKLEY_NET BIBERK CHUBB CNA
      COALITION COALITION_SURPLUS COMPWEST COTERIE COWBELL CRUMFORSTER_SURPLUS
      EMPLOYERS GAIG GUARD HISCOX IAT LIBERTYMUTUAL MARKEL MARKEL_SURPLUS
      MERCHANTS NATIONWIDE NATIONWIDE_SURPLUS PENNAMERICA_SURPLUS
      PIE_INSURANCE PROGRESSIVE REPUBLIC_INDEMNITY TRAVELERS USLI
      WESTCHESTER_SURPLUS
    ].freeze
    POLICY_TYPES = %w[CGL WC BOP CAUTO CYBER BR MPL CP CPL].freeze
    STATES = %w[
      AL AK AZ AR CA CO CT DE FL GA HI ID IL IN IA KS KY LA ME MD MA MI MN
      MS MO MT NE NV NH NJ NM NY NC ND OH OK OR PA RI SC SD TN TX UT VT VA
      WA WV WI WY DC
    ].freeze
    APPETITE_RESULTS = %w[IN_APPETITE NOT_IN_APPETITE MAYBE_IN_APPETITE].freeze

    def initialize(api_client: ApiClient.new, request_id_generator: -> { SecureRandom.uuid })
      @api_client = api_client
      @request_id_generator = request_id_generator
    end

    def call(carriers:, naics_code:, policy_type:, state:)
      payload = {
        carriers: Array(carriers).map(&:to_s).uniq,
        naicsCode: naics_code.to_s,
        policyType: policy_type.to_s,
        state: state.to_s.upcase
      }
      validate!(payload)

      response = @api_client.request(
        :post,
        "check-appetite",
        headers: {
          "Content-Type" => "application/json",
          "x-request-id" => @request_id_generator.call
        },
        body: JSON.generate(payload)
      )
      parsed = parse_response(response)
      infos = parsed.fetch("appetiteInfos")
      unless infos.is_a?(Array) && infos.all? { |item|
        item.is_a?(Hash) &&
          CARRIERS.include?(item["carrier"]) &&
          POLICY_TYPES.include?(item["policyType"]) &&
          STATES.include?(item["state"]) &&
          APPETITE_RESULTS.include?(item["hasAppetite"])
      }
        raise ProviderError.new(
          "CoverForce returned an invalid appetite response",
          status: response.code.to_i, request_id: response["x-request-id"], body: response.body
        )
      end
      infos
    end

    private

    def validate!(payload)
      raise InvalidRequest, "Select at least one supported carrier" if payload[:carriers].empty?
      unknown = payload[:carriers] - CARRIERS
      raise InvalidRequest, "Unsupported CoverForce carrier(s): #{unknown.join(', ')}" if unknown.any?
      raise InvalidRequest, "NAICS code must contain exactly 6 digits" unless payload[:naicsCode].match?(/\A\d{6}\z/)
      raise InvalidRequest, "Unsupported CoverForce policy type" unless POLICY_TYPES.include?(payload[:policyType])
      raise InvalidRequest, "Unsupported state" unless STATES.include?(payload[:state])
    end

    def parse_response(response)
      payload = JSON.parse(response.body)
      return payload if response.code.to_i.between?(200, 299)

      raise ProviderError.new(
        "CoverForce appetite check failed (HTTP #{response.code})",
        status: response.code.to_i, request_id: response["x-request-id"], body: payload
      )
    rescue JSON::ParserError
      raise ProviderError.new(
        "CoverForce returned an unreadable appetite response",
        status: response.code.to_i, request_id: response["x-request-id"], body: response.body
      )
    end
  end
end
