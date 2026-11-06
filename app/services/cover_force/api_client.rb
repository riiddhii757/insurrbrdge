require "json"
require "net/http"
require "uri"

module CoverForce
  class ApiClient
    class RequestError < StandardError
      attr_reader :status, :request_id, :response_body

      def initialize(message, status:, request_id:, response_body:)
        super(message)
        @status = status
        @request_id = request_id
        @response_body = response_body
      end
    end

    def initialize(token_client: TokenClient.new, open_timeout: 5, read_timeout: 30)
      @token_client = token_client
      @open_timeout = open_timeout
      @read_timeout = read_timeout
    end

    # All protected resources are rooted under /api. A 401 causes one token
    # refresh and one retry; a second 401 is returned to the caller as an error.
    def request(method, path, headers: {}, body: nil)
      uri = api_uri(path)
      response = perform_request(method, uri, headers, body)

      if response.code.to_i == 401
        @token_client.invalidate_token!
        response = perform_request(method, uri, headers, body)
      end

      response
    end

    private

    def api_uri(path)
      relative_path = path.to_s.sub(%r{\A/+}, "")
      if relative_path.empty? || relative_path.match?(%r{\Ahttps?://}i) || relative_path.split("/").include?("..")
        raise ArgumentError, "CoverForce API path must be a relative /api resource path"
      end

      base_url = TokenClient::ENVIRONMENTS.fetch(@token_client.instance_variable_get(:@environment))
      URI("#{base_url}/api/#{relative_path}")
    end

    def perform_request(method, uri, headers, body)
      request_class = Net::HTTP.const_get(method.to_s.capitalize)
      request = request_class.new(uri)
      request["Accept"] = "application/json"
      headers.each { |key, value| request[key] = value }
      request["Authorization"] = @token_client.authorization_header
      request.body = body if body

      Net::HTTP.start(
        uri.host, uri.port,
        use_ssl: uri.scheme == "https",
        open_timeout: @open_timeout,
        read_timeout: @read_timeout
      ) { |http| http.request(request) }
    rescue NameError
      raise ArgumentError, "Unsupported HTTP method: #{method}"
    end
  end
end
