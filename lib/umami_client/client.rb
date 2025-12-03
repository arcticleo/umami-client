# frozen_string_literal: true

require_relative "connection"

module UmamiClient
  # Main client class for interacting with the Umami API
  class Client
    attr_reader :api_key, :username, :password, :base_url, :timeout, :connection

    # Creates a new client instance
    #
    # @param api_key [String, nil] API key for Umami Cloud (defaults to global config)
    # @param username [String, nil] Username for self-hosted (defaults to global config)
    # @param password [String, nil] Password for self-hosted (defaults to global config)
    # @param base_url [String, nil] Base URL (defaults to global config)
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
        timeout: @timeout
      )
    end
  end
end
