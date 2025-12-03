# frozen_string_literal: true

require "faraday"
require "faraday/retry"
require "json"

module UmamiClient
  # Handles HTTP connections to the Umami API
  class Connection
    attr_reader :api_key, :username, :password, :base_url, :timeout, :auth_method

    def initialize(api_key: nil, username: nil, password: nil, base_url:, timeout:)
      @api_key = api_key
      @username = username
      @password = password
      @base_url = base_url
      @timeout = timeout
      @auth_method = determine_auth_method
      @bearer_token = nil
    end

    # Performs a GET request
    #
    # @param path [String] the API endpoint path
    # @param params [Hash] query parameters
    # @return [Hash] parsed JSON response
    def get(path, params = {})
      request(:get, path, params: params)
    end

    # Performs a POST request
    #
    # @param path [String] the API endpoint path
    # @param body [Hash] request body
    # @return [Hash] parsed JSON response
    def post(path, body = {})
      request(:post, path, body: body)
    end

    # Performs a PUT request
    #
    # @param path [String] the API endpoint path
    # @param body [Hash] request body
    # @return [Hash] parsed JSON response
    def put(path, body = {})
      request(:put, path, body: body)
    end

    # Performs a DELETE request
    #
    # @param path [String] the API endpoint path
    # @return [Hash] parsed JSON response
    def delete(path)
      request(:delete, path)
    end

    private

    def determine_auth_method
      if api_key
        :cloud
      elsif username && password
        :self_hosted
      else
        raise ConfigurationError, "Either api_key or username/password must be provided"
      end
    end

    # Authenticates with self-hosted Umami instance and obtains bearer token
    def authenticate!
      return if @bearer_token # Already authenticated
      return unless auth_method == :self_hosted

      response = connection.post("/api/auth/login") do |req|
        req.headers["Content-Type"] = "application/json"
        req.body = { username: username, password: password }.to_json
      end

      if response.status == 200
        @bearer_token = response.body["token"]
      else
        raise AuthenticationError, "Failed to authenticate: #{error_message(response)}"
      end
    rescue Faraday::Error => e
      raise NetworkError, "Authentication failed: #{e.message}"
    end

    def connection
      @connection ||= Faraday.new(url: base_url) do |faraday|
        faraday.request :json
        faraday.request :retry, max: 3, interval: 0.5, backoff_factor: 2
        faraday.response :json, content_type: /\bjson$/
        faraday.adapter Faraday.default_adapter
        faraday.options.timeout = timeout
        faraday.options.open_timeout = 10
      end
    end

    def request(method, path, params: {}, body: {})
      # Authenticate for self-hosted if not already done
      authenticate! if auth_method == :self_hosted

      response = connection.public_send(method) do |req|
        req.url path

        # Set appropriate authentication header based on method
        case auth_method
        when :cloud
          req.headers["x-umami-api-key"] = api_key
        when :self_hosted
          req.headers["Authorization"] = "Bearer #{@bearer_token}"
        end

        req.headers["Content-Type"] = "application/json"
        req.params = params if params.any?
        req.body = body if body.any? && %i[post put].include?(method)
      end

      handle_response(response)
    rescue Faraday::TimeoutError => e
      raise NetworkError, "Request timeout: #{e.message}"
    rescue Faraday::ConnectionFailed => e
      raise NetworkError, "Connection failed: #{e.message}"
    rescue Faraday::Error => e
      raise NetworkError, "Network error: #{e.message}"
    end

    def handle_response(response)
      case response.status
      when 200..299
        response.body
      when 400
        raise BadRequestError, error_message(response)
      when 401, 403
        raise AuthenticationError, error_message(response)
      when 404
        raise NotFoundError, error_message(response)
      when 429
        raise RateLimitError, error_message(response)
      when 500..599
        raise ServerError, error_message(response)
      else
        raise Error, "Unexpected response status: #{response.status}"
      end
    end

    def error_message(response)
      if response.body.is_a?(Hash)
        response.body["message"] || response.body["error"] || "HTTP #{response.status}"
      else
        "HTTP #{response.status}"
      end
    end
  end
end
