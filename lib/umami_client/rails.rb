# frozen_string_literal: true

module UmamiClient
  # Rails integration module
  #
  # This module provides Rails-specific functionality including:
  # - Railtie for automatic configuration
  # - Rack middleware for automatic page view tracking
  # - View helpers for client-side and server-side tracking
  # - Controller concerns for tracking page views and custom events
  # - Generators for easy setup and configuration
  # - Background job integration for async tracking
  # - Reports helpers for common analytics patterns
  #
  # @example Basic usage in Rails
  #   # config/initializers/umami_client.rb
  #   UmamiClient.configure do |config|
  #     config.api_key = ENV['UMAMI_API_KEY']
  #     config.base_url = ENV['UMAMI_BASE_URL']
  #     config.website_id = ENV['UMAMI_WEBSITE_ID']
  #   end
  module Rails
  end
end
