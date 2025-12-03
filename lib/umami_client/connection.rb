# frozen_string_literal: true

require "faraday"
require "faraday/retry"
require "json"

module UmamiClient
  # Handles HTTP connections to the Umami API
  class Connection
    attr_reader :api_key, :base_url, :timeout

    def initialize(api_key:, base_url:, timeout:)
      @api_key = api_key
      @base_url = base_url
      @timeout = timeout
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
      response = connection.public_send(method) do |req|
        req.url path
        req.headers["x-umami-api-key"] = api_key
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
