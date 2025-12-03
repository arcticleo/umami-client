# frozen_string_literal: true

module UmamiClient
  # Main client class for interacting with the Umami API
  class Client
    attr_reader :api_key, :base_url, :timeout

    # Creates a new client instance
    #
    # @param api_key [String, nil] API key (defaults to global config)
    # @param base_url [String, nil] Base URL (defaults to global config)
    def initialize(api_key: nil, base_url: nil)
      @api_key = api_key || UmamiClient.configuration.api_key
      @base_url = base_url || UmamiClient.configuration.base_url
      @timeout = UmamiClient.configuration.timeout

      raise AuthenticationError, "API key is required" if @api_key.nil? || @api_key.empty?
    end
  end
end
