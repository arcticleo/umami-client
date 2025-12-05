# frozen_string_literal: true

require "faraday"
require "faraday/retry"
require "json"

module UmamiClient
  # Handles HTTP connections to the Umami API
  class Connection
    attr_reader :api_key, :username, :password, :base_url, :timeout, :auth_method,
                :max_retries, :retry_delay, :backoff_factor, :retry_statuses

    def initialize(api_key: nil, username: nil, password: nil, base_url:, timeout:,
                   max_retries: 3, retry_delay: 0.5, backoff_factor: 2, retry_statuses: nil)
      @api_key = api_key
      @username = username
      @password = password
      @base_url = base_url
      @timeout = timeout
      @max_retries = max_retries
      @retry_delay = retry_delay
      @backoff_factor = backoff_factor
      @retry_statuses = retry_statuses || [429, 500, 502, 503, 504]
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
    #
    # This uses the interactive login method (POST /api/auth/login) with the same
    # username/password credentials used for the web interface. This is different from
    # the UMAMI_API_CLIENT_USER_ID/SECRET method used by the official JS API client.
    #
    # The bearer token is cached and reused for subsequent requests.
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

        # Set a proper User-Agent header (required by Umami)
        faraday.headers["User-Agent"] = "UmamiClient Ruby Gem/#{UmamiClient::VERSION}"

        # Configure retry middleware with our settings
        faraday.request :retry,
                        max: max_retries,
                        interval: retry_delay,
                        backoff_factor: backoff_factor,
                        methods: %i[get post put delete patch],
                        exceptions: [
                          Faraday::TimeoutError,
                          Faraday::ConnectionFailed,
                          Errno::ETIMEDOUT,
                          Errno::ECONNREFUSED,
                          Errno::ECONNRESET
                        ],
                        retry_statuses: retry_statuses,
                        retry_block: lambda { |env:, options:, retry_count:, exception:, will_retry_in:|
                          # Check for Retry-After header and respect it
                          if env.response_headers&.key?("retry-after")
                            retry_after = env.response_headers["retry-after"]
                            will_retry_in = parse_retry_after(retry_after)
                          end
                        }

        faraday.response :json, content_type: /\bjson$/
        faraday.adapter Faraday.default_adapter
        faraday.options.timeout = timeout
        faraday.options.open_timeout = 10
      end
    end

    # Parses the Retry-After header value
    #
    # @param value [String] the Retry-After header value
    # @return [Float] seconds to wait
    def parse_retry_after(value)
      # Try to parse as integer first (seconds)
      if value.match?(/^\d+$/)
        value.to_i.to_f
      else
        # Try to parse as HTTP date
        begin
          require "time"
          retry_time = Time.httpdate(value)
          [(retry_time - Time.now).to_f, 0].max
        rescue ArgumentError
          # If parsing fails, fall back to default interval
          retry_delay
        end
      end
    end

    def request(method, path, params: {}, body: {}, retry_auth: true)
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
    rescue AuthenticationError => e
      # If we get a 401/403 and haven't retried yet, try re-authenticating
      if retry_auth && auth_method == :self_hosted && @bearer_token
        @bearer_token = nil # Clear the expired token
        authenticate!       # Get a new token
        return request(method, path, params: params, body: body, retry_auth: false)
      end
      raise e
    rescue Faraday::TimeoutError => e
      raise NetworkError, "Request timeout: #{e.message}"
    rescue Faraday::ConnectionFailed => e
      raise NetworkError, "Connection failed: #{e.message}"
    rescue Faraday::Error => e
      raise NetworkError, "Network error: #{e.message}"
    end

    def handle_response(faraday_response)
      # Wrap the Faraday response in our Response model
      response = Response.new(faraday_response)

      case response.status
      when 200..299
        response
      when 400
        raise BadRequestError, response.error_message
      when 401, 403
        raise AuthenticationError, response.error_message
      when 404
        raise NotFoundError, response.error_message
      when 429
        raise RateLimitError, response.error_message
      when 500..599
        raise ServerError, response.error_message
      else
        raise Error, "Unexpected response status: #{response.status}"
      end
    end
  end
end
