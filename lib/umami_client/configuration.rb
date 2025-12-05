# frozen_string_literal: true

module UmamiClient
  # Configuration class for storing API credentials and settings
  class Configuration
    # @return [String, nil] the Umami Cloud API key
    attr_accessor :api_key

    # @return [String, nil] the username for self-hosted authentication (same as web login)
    attr_accessor :username

    # @return [String, nil] the password for self-hosted authentication (same as web login)
    attr_accessor :password

    # @return [String] the base URL for the Umami API
    attr_accessor :base_url

    # @return [String, nil] default website ID for event tracking
    attr_accessor :website_id

    # @return [String, nil] default hostname for events
    attr_accessor :default_hostname

    # @return [Integer] the timeout for HTTP requests in seconds
    attr_accessor :timeout

    # @return [String] the User-Agent string to use for tracking requests
    attr_accessor :user_agent

    # @return [Integer] the maximum number of retry attempts for failed requests
    attr_accessor :max_retries

    # @return [Float] the initial retry delay in seconds
    attr_accessor :retry_delay

    # @return [Integer] the exponential backoff factor for retries
    attr_accessor :backoff_factor

    # @return [Array<Integer>] HTTP status codes that should trigger a retry
    attr_accessor :retry_statuses

    # @return [Boolean] whether tracking is disabled (useful for testing)
    attr_accessor :disabled

    # @return [Logger, nil] optional logger for debugging
    attr_accessor :logger

    def initialize
      @api_key = nil
      @username = nil
      @password = nil
      @base_url = "https://api.umami.is"
      @website_id = nil
      @default_hostname = nil
      @timeout = 30
      @user_agent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.1 Safari/605.1.15"
      @max_retries = 3
      @retry_delay = 0.5
      @backoff_factor = 2
      @retry_statuses = [429, 500, 502, 503, 504]
      @disabled = false
      @logger = nil
    end

    # Determines which authentication method to use
    #
    # @return [Symbol] :cloud or :self_hosted
    def auth_method
      if api_key
        :cloud
      elsif username && password
        :self_hosted
      else
        raise ConfigurationError, "Either api_key or username/password must be configured"
      end
    end

    # Validates that the configuration has required credentials
    #
    # @return [Boolean] true if valid
    # @raise [ConfigurationError] if configuration is invalid
    def valid?
      auth_method # This will raise if invalid
      true
    end
  end
end
