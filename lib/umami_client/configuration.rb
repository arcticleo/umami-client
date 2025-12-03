# frozen_string_literal: true

module UmamiClient
  # Configuration class for storing API credentials and settings
  class Configuration
    # @return [String, nil] the Umami API key
    attr_accessor :api_key

    # @return [String] the base URL for the Umami API
    attr_accessor :base_url

    # @return [Integer] the timeout for HTTP requests in seconds
    attr_accessor :timeout

    def initialize
      @api_key = nil
      @base_url = "https://api.umami.is"
      @timeout = 30
    end
  end
end
