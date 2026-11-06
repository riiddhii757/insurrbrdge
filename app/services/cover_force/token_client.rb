require "base64"
require "json"
require "net/http"
require "securerandom"
require "uri"

module CoverForce
  class TokenClient
    class AuthenticationError < StandardError
      attr_reader :status, :request_id

      def initialize(message, status: nil, request_id: nil)
        super(message)
        @status = status
        @request_id = request_id
      end
    end

    ENVIRONMENTS = {
      "sandbox" => "https://sandbox.api.coverforce.com",
      "production" => "https://production.api.coverforce.com"
    }.freeze

    Token = Data.define(:access_token, :refresh_at, :request_id)

    attr_reader :base_url

    def initialize(environment: ENV.fetch("COVERFORCE_ENV", "sandbox"),
                   client_id: nil, client_secret: nil,
                   clock: -> { Time.now }, request_id_generator: -> { SecureRandom.uuid })
      @environment = environment.to_s
      @base_url = ENVIRONMENTS.fetch(@environment) do
        raise ArgumentError, "COVERFORCE_ENV must be sandbox or production"
      end
      prefix = @environment.upcase
      @client_id = client_id || ENV["COVERFORCE_#{prefix}_CLIENT_ID"]
      @client_secret = client_secret || ENV["COVERFORCE_#{prefix}_CLIENT_SECRET"]
      @clock = clock
      @request_id_generator = request_id_generator
      @token = nil
      @token_mutex = Mutex.new
    end

    # Caches the token and refreshes it before the provider-reported expiry.
    def access_token
      @token_mutex.synchronize do
        return @token.access_token if @token && @clock.call < @token.refresh_at

        @token = request_token
        @token.access_token
      end
    end

    def authorization_header
      "Bearer #{access_token}"
    end

    # Discard a token rejected by the API so the next access_token call fetches
    # a fresh one. Synchronization prevents concurrent callers from racing.
    def invalidate_token!
      @token_mutex.synchronize { @token = nil }
    end

    private

    def request_token
      if @client_id.to_s.empty? || @client_secret.to_s.empty?
        raise AuthenticationError, "CoverForce client credentials are not configured"
      end

      uri = URI("#{@base_url}/auth")
      request_id = @request_id_generator.call
      request = Net::HTTP::Post.new(uri)
      request["Accept"] = "application/json"
      request["Content-Type"] = "application/x-www-form-urlencoded"
      request["Authorization"] = "Basic #{Base64.strict_encode64("#{@client_id}:#{@client_secret}")}"
      request["x-request-id"] = request_id
      request.body = URI.encode_www_form(grant_type: "client_credentials")

      response = Net::HTTP.start(
        uri.host, uri.port,
        use_ssl: uri.scheme == "https",
        open_timeout: 5, read_timeout: 15
      ) { |http| http.request(request) }

      response_request_id = response["x-request-id"]
      unless response.code.to_i == 200
        raise AuthenticationError.new(
          "CoverForce authentication failed (HTTP #{response.code})",
          status: response.code.to_i, request_id: response_request_id
        )
      end

      payload = JSON.parse(response.body)
      token_type = payload["token_type"]
      access_token = payload["access_token"]
      expires_in = Float(payload["expires_in"], exception: false)

      unless token_type == "Bearer" && access_token.is_a?(String) &&
             !access_token.empty? && expires_in&.positive?
        raise AuthenticationError.new(
          "CoverForce returned an invalid token response",
          status: response.code.to_i, request_id: response_request_id
        )
      end

      # Refresh 10% early, capped at 60 seconds, to avoid using an expiring token.
      refresh_skew = [expires_in * 0.1, 60].min
      Token.new(access_token, @clock.call + expires_in - refresh_skew, response_request_id)
    rescue JSON::ParserError
      raise AuthenticationError.new(
        "CoverForce returned an unreadable token response",
        status: response&.code&.to_i, request_id: response&.[]("x-request-id")
      )
    rescue Net::OpenTimeout, Net::ReadTimeout, SocketError, Errno::ECONNREFUSED => error
      raise AuthenticationError, "CoverForce authentication request failed (#{error.class})"
    end
  end
end
