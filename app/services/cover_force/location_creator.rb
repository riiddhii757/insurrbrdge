require "json"
require "securerandom"

module CoverForce
  class LocationCreator
    class InvalidRequest < StandardError; end
    class ProviderError < StandardError
      attr_reader :status, :request_id, :body

      def initialize(message, status:, request_id:, body:)
        super(message)
        @status, @request_id, @body = status, request_id, body
      end
    end

    STATES = AppetiteChecker::STATES.freeze
    ZIP_PATTERN = /\A\d{5}(?:[-\s]\d{4})?\z/
    EMPLOYEE_FIELDS = %i[numPartTimeEmployees numFullTimeEmployees totalEmployeePayroll jobCodeId].freeze
    UW_FIELDS = %i[questionId answer].freeze
    BUILDING_FIELDS = %i[
      businessPersonalPropertyCoverage buildingCoverage buildingAndBusinessCoverageDetails
      areaOfConstructionProject totalConstructionProjectValue
    ].freeze
    BUILDING_DETAIL_FIELDS = %i[
      totalArea areaOccupied areaOccupiedByOthers constructionTypeCode annualSales yearBuilt
      totalStories isOwner burglarAlarmTypeCode sprinkleredPercentage roofType roofUpdateYear
      electricalWiringUpdateYear heatingUpdateYear plumbingUpdateYear buildingValuationType
      buildingCoinsurancePercent bppValuationType bppCoinsurancePercent
    ].freeze

    def initialize(api_client: ApiClient.new, request_id_generator: -> { SecureRandom.uuid })
      @api_client = api_client
      @request_id_generator = request_id_generator
    end

    def call(application_id:, address:, is_primary:, employee_infos: [],
             location_uw_information: [], building_info: nil)
      payload = {
        address: normalize_hash(address, %i[addressLine1 addressLine2 city state zip]),
        isPrimary: is_primary,
        employeeInfos: Array(employee_infos).map { |item| normalize_hash(item, EMPLOYEE_FIELDS) },
        locationUWInformation: Array(location_uw_information).map { |item| normalize_hash(item, UW_FIELDS) }
      }
      payload.delete(:employeeInfos) if payload[:employeeInfos].empty?
      payload.delete(:locationUWInformation) if payload[:locationUWInformation].empty?
      if building_info.present?
        building = normalize_hash(building_info, BUILDING_FIELDS)
        if building[:buildingAndBusinessCoverageDetails]
          building[:buildingAndBusinessCoverageDetails] =
            Array(building[:buildingAndBusinessCoverageDetails]).map do |item|
              normalize_hash(item, BUILDING_DETAIL_FIELDS)
            end
        end
        payload[:buildingInfo] = building
      end
      validate!(application_id, payload)

      response = @api_client.request(
        :post, "location/#{URI.encode_www_form_component(application_id)}",
        headers: {
          "Content-Type" => "application/json",
          "x-request-id" => @request_id_generator.call
        },
        body: JSON.generate(payload)
      )
      parsed = JSON.parse(response.body)
      unless response.code.to_i == 201 && parsed["locationId"].is_a?(String) &&
             parsed["locationId"].start_with?("LOC-")
        raise ProviderError.new(
          "CoverForce location creation failed (HTTP #{response.code})",
          status: response.code.to_i, request_id: response["x-request-id"], body: parsed
        )
      end
      parsed
    rescue JSON::ParserError
      raise ProviderError.new(
        "CoverForce returned an unreadable location response",
        status: response&.code&.to_i, request_id: response&.[]("x-request-id"),
        body: response&.body
      )
    end

    private

    def normalize_hash(value, allowed_fields)
      values = value.to_h.transform_keys { |key| key.to_s.camelize(:lower).to_sym }
      values.slice(*allowed_fields).compact
    end

    def validate!(application_id, payload)
      raise InvalidRequest, "CoverForce application ID is required" if application_id.to_s !~ /\AAPP-[A-Za-z0-9-]+\z/
      address = payload[:address]
      %i[addressLine1 city state zip].each do |field|
        raise InvalidRequest, "Location address #{field} is required" if address[field].to_s.strip.empty?
      end
      raise InvalidRequest, "Unsupported location state" unless STATES.include?(address[:state].to_s.upcase)
      address[:state] = address[:state].to_s.upcase
      raise InvalidRequest, "Location ZIP code is invalid" unless address[:zip].to_s.match?(ZIP_PATTERN)
      raise InvalidRequest, "is_primary must be true or false" unless [true, false].include?(payload[:isPrimary])

      payload.fetch(:employeeInfos, []).each do |employee|
        missing = EMPLOYEE_FIELDS.select { |field| employee[field].nil? || employee[field].to_s.strip.empty? }
        raise InvalidRequest, "Employee info requires #{missing.join(', ')}" if missing.any?
        %i[numPartTimeEmployees numFullTimeEmployees totalEmployeePayroll].each do |field|
          value = employee[field]
          raise InvalidRequest, "#{field} must be a non-negative number" unless value.is_a?(Numeric) && value >= 0
        end
      end
      payload.fetch(:locationUWInformation, []).each do |answer|
        missing = UW_FIELDS.select { |field| answer[field].to_s.strip.empty? }
        raise InvalidRequest, "Location underwriting answer requires #{missing.join(', ')}" if missing.any?
      end
    end
  end
end
