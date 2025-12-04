# frozen_string_literal: true

require_relative "connection"

module UmamiClient
  # Main client class for interacting with the Umami API
  class Client
    attr_reader :api_key, :username, :password, :base_url, :timeout, :connection, :events, :websites

    # Creates a new client instance
    #
    # @param api_key [String, nil] API key for Umami Cloud (defaults to global config)
    # @param username [String, nil] Username for self-hosted login - same as web interface (defaults to global config)
    # @param password [String, nil] Password for self-hosted login - same as web interface (defaults to global config)
    # @param base_url [String, nil] Base URL (defaults to global config)
    #
    # @example Umami Cloud authentication
    #   client = UmamiClient.new(api_key: "your-api-key")
    #
    # @example Self-hosted authentication
    #   client = UmamiClient.new(
    #     username: "admin",
    #     password: "password",
    #     base_url: "https://analytics.example.com"
    #   )
    def initialize(api_key: nil, username: nil, password: nil, base_url: nil)
      config = UmamiClient.configuration

      @api_key = api_key || config.api_key
      @username = username || config.username
      @password = password || config.password
      @base_url = base_url || config.base_url
      @timeout = config.timeout

      # Validate that we have either api_key OR username/password
      if @api_key.nil? && (@username.nil? || @password.nil?)
        raise ConfigurationError, "Either api_key or username/password must be provided"
      end

      @connection = Connection.new(
        api_key: @api_key,
        username: @username,
        password: @password,
        base_url: @base_url,
        timeout: @timeout,
        max_retries: config.max_retries,
        retry_delay: config.retry_delay,
        backoff_factor: config.backoff_factor,
        retry_statuses: config.retry_statuses
      )

      @events = Events.new(
        connection: @connection,
        website_id: config.website_id,
        default_hostname: config.default_hostname,
        user_agent: config.user_agent
      )

      @websites = Websites.new(
        connection: @connection
      )
    end

    # Authenticates with the Umami API
    #
    # For self-hosted instances, this obtains a bearer token using username/password.
    # For Umami Cloud, authentication is handled automatically via API key.
    #
    # @return [String, nil] The bearer token for self-hosted, nil for cloud
    def authenticate
      @connection.send(:authenticate!)
      @connection.instance_variable_get(:@bearer_token)
    end
  end
end
