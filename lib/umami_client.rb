# frozen_string_literal: true

require_relative "umami_client/version"
require_relative "umami_client/configuration"
require_relative "umami_client/error"
require_relative "umami_client/response"
require_relative "umami_client/website"
require_relative "umami_client/connection"
require_relative "umami_client/events"
require_relative "umami_client/websites"
require_relative "umami_client/stats"
require_relative "umami_client/client"

module UmamiClient
  class << self
    # Returns the global configuration object
    #
    # @return [Configuration]
    def configuration
      @configuration ||= Configuration.new
    end

    # Yields the global configuration object for setup
    #
    # @yield [Configuration]
    # @example
    #   UmamiClient.configure do |config|
    #     config.api_key = "your-api-key"
    #     config.base_url = "https://analytics.umami.is"
    #   end
    def configure
      yield(configuration)
    end

    # Creates a new client with custom configuration
    #
    # @param api_key [String] optional API key override
    # @param base_url [String] optional base URL override
    # @return [Client]
    def new(api_key: nil, base_url: nil)
      Client.new(api_key: api_key, base_url: base_url)
    end

    # Disables tracking (useful for testing)
    #
    # When disabled, all tracking methods will skip HTTP requests and return
    # mock responses instead.
    #
    # @return [void]
    # @example
    #   UmamiClient.disable!
    def disable!
      configuration.disabled = true
    end

    # Enables tracking
    #
    # @return [void]
    # @example
    #   UmamiClient.enable!
    def enable!
      configuration.disabled = false
    end

    # Returns whether tracking is currently disabled
    #
    # @return [Boolean]
    # @example
    #   UmamiClient.disabled? # => false
    def disabled?
      configuration.disabled
    end
  end
end
