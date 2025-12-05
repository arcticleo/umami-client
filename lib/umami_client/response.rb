# frozen_string_literal: true

module UmamiClient
  # Wrapper class for API responses
  #
  # Provides a consistent interface for handling API responses with
  # metadata like status codes, headers, and parsed body data.
  class Response
    attr_reader :status, :headers, :body, :raw_response

    # Creates a new Response instance
    #
    # @param faraday_response [Faraday::Response] the raw Faraday response object
    def initialize(faraday_response)
      @raw_response = faraday_response
      @status = faraday_response.status
      @headers = faraday_response.headers
      @body = faraday_response.body
    end

    # Checks if the response was successful (2xx status)
    #
    # @return [Boolean] true if status is in 200-299 range
    def success?
      (200..299).cover?(status)
    end

    # Checks if the response indicates a client error (4xx status)
    #
    # @return [Boolean] true if status is in 400-499 range
    def client_error?
      (400..499).cover?(status)
    end

    # Checks if the response indicates a server error (5xx status)
    #
    # @return [Boolean] true if status is in 500-599 range
    def server_error?
      (500..599).cover?(status)
    end

    # Checks if the response indicates an error (4xx or 5xx status)
    #
    # @return [Boolean] true if status is 400 or higher
    def error?
      status >= 400
    end

    # Gets the error message from the response body
    #
    # @return [String, nil] the error message or nil if not found
    def error_message
      return nil unless error?

      if body.is_a?(Hash)
        body["message"] || body["error"] || "HTTP #{status}"
      else
        "HTTP #{status}"
      end
    end

    # Gets a value from the response body
    #
    # @param key [String, Symbol] the key to look up
    # @return [Object, nil] the value or nil if not found
    def [](key)
      return nil unless body.is_a?(Hash)

      body[key.to_s] || body[key.to_sym]
    end

    # Checks if the response body contains a specific key
    #
    # @param key [String, Symbol] the key to check
    # @return [Boolean] true if the key exists in the body
    def key?(key)
      return false unless body.is_a?(Hash)

      body.key?(key.to_s) || body.key?(key.to_sym)
    end

    # Gets pagination information from response headers
    #
    # Many APIs include pagination info in headers like:
    # - X-Total-Count
    # - X-Page
    # - X-Per-Page
    # - Link (RFC 5988)
    #
    # @return [Hash] pagination metadata
    def pagination
      {
        total_count: headers["x-total-count"]&.to_i,
        page: headers["x-page"]&.to_i,
        per_page: headers["x-per-page"]&.to_i,
        link: headers["link"]
      }.compact
    end

    # Checks if the response has pagination information
    #
    # @return [Boolean] true if pagination headers are present
    def paginated?
      headers.key?("x-total-count") || headers.key?("link")
    end

    # Returns the response body data
    #
    # @return [Hash, Array, String, nil] the parsed response body
    def data
      body
    end

    # Converts the response to a hash representation
    #
    # @return [Hash] hash containing status, headers, and body
    def to_h
      {
        status: status,
        headers: headers.to_h,
        body: body
      }
    end

    # String representation of the response
    #
    # @return [String] formatted response information
    def to_s
      "#<UmamiClient::Response status=#{status} body=#{body.inspect[0..100]}>"
    end

    alias inspect to_s
  end
end
