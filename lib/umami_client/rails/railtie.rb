# frozen_string_literal: true

module UmamiClient
  module Rails
    # Railtie for automatic Rails integration
    #
    # This Railtie hooks into Rails initialization to:
    # - Set up configuration from Rails.application.config
    # - Automatically register middleware for page view tracking
    # - Load rake tasks for reports generation
    # - Make view helpers and controller concerns available
    #
    # The Railtie is automatically loaded when Rails is present.
    # No manual setup is required.
    #
    # @example Configuration in Rails
    #   # config/application.rb or config/environments/production.rb
    #   config.umami_client.api_key = ENV['UMAMI_API_KEY']
    #   config.umami_client.base_url = ENV['UMAMI_BASE_URL']
    #   config.umami_client.website_id = ENV['UMAMI_WEBSITE_ID']
    class Railtie < ::Rails::Railtie
      # Configure the gem name for Rails
      railtie_name :umami_client

      # Add configuration namespace to Rails
      config.umami_client = ActiveSupport::OrderedOptions.new

      # Initialize UmamiClient configuration from Rails config
      initializer "umami_client.configure" do |app|
        # Copy Rails config to UmamiClient configuration
        if app.config.umami_client.present?
          UmamiClient.configure do |umami_config|
            # Authentication
            umami_config.api_key = app.config.umami_client.api_key if app.config.umami_client.api_key
            umami_config.username = app.config.umami_client.username if app.config.umami_client.username
            umami_config.password = app.config.umami_client.password if app.config.umami_client.password
            umami_config.base_url = app.config.umami_client.base_url if app.config.umami_client.base_url

            # Tracking configuration
            umami_config.website_id = app.config.umami_client.website_id if app.config.umami_client.website_id
            umami_config.default_hostname = app.config.umami_client.default_hostname if app.config.umami_client.default_hostname
            umami_config.user_agent = app.config.umami_client.user_agent if app.config.umami_client.user_agent

            # Behavior
            umami_config.disabled = app.config.umami_client.disabled if app.config.umami_client.key?(:disabled)
            umami_config.logger = app.config.umami_client.logger if app.config.umami_client.logger

            # Connection settings
            umami_config.timeout = app.config.umami_client.timeout if app.config.umami_client.timeout
            umami_config.max_retries = app.config.umami_client.max_retries if app.config.umami_client.max_retries
            umami_config.retry_delay = app.config.umami_client.retry_delay if app.config.umami_client.retry_delay
            umami_config.backoff_factor = app.config.umami_client.backoff_factor if app.config.umami_client.backoff_factor
          end

          # Validate configuration if not disabled
          unless UmamiClient.configuration.disabled
            validate_configuration!(app.config.umami_client)
          end
        end
      end

      # Validate required configuration
      def self.validate_configuration!(config)
        errors = []

        # Check authentication credentials
        has_api_key = config.api_key.present?
        has_username_password = config.username.present? && config.password.present?

        unless has_api_key || has_username_password
          errors << "Either api_key or username/password must be configured"
        end

        # Check base_url is present
        unless config.base_url.present?
          errors << "base_url must be configured"
        end

        # Warn if website_id is missing (not required for all operations, but needed for tracking)
        if config.website_id.blank? && config.middleware_enabled
          ::Rails.logger.warn "[UmamiClient] website_id is not configured but middleware is enabled. " \
                              "Tracking may not work correctly."
        end

        # Raise error if there are validation errors
        if errors.any?
          raise UmamiClient::ConfigurationError, "UmamiClient configuration errors:\n  - #{errors.join("\n  - ")}"
        end
      end

      # Register Rack middleware for automatic page view tracking
      initializer "umami_client.middleware", after: :load_config_initializers do |app|
        # Only add middleware if explicitly enabled
        if app.config.umami_client.middleware_enabled
          require_relative "../middleware/tracker"

          middleware_options = {
            website_id: app.config.umami_client.website_id,
            skip_paths: app.config.umami_client.skip_paths || [],
            skip_assets: app.config.umami_client.fetch(:skip_assets, true),
            async: app.config.umami_client.fetch(:async, true),
            enabled: app.config.umami_client.fetch(:middleware_enabled, false)
          }

          app.middleware.use UmamiClient::Middleware::Tracker, middleware_options
        end
      end

      # Load rake tasks
      rake_tasks do
        load "tasks/umami.rake" if File.exist?(File.join(root, "lib/tasks/umami.rake"))
      end

      # Add generator paths
      generators do
        require_relative "../generators/install/install_generator"
        require_relative "../generators/config/config_generator"
        require_relative "../generators/views/views_generator"
      end
    end
  end
end
