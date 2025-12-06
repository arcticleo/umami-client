# frozen_string_literal: true

module UmamiClient
  module Middleware
    # Rack middleware for automatic page view tracking
    #
    # This middleware automatically tracks page views for every request
    # in your Rails application. It extracts request data (URL, referrer,
    # user agent) and sends it to Umami Analytics.
    #
    # Features:
    # - Automatic page view tracking on every request
    # - Intelligent path filtering (skip assets, health checks, etc.)
    # - Async tracking via background jobs (optional)
    # - Callback hooks for customization (before_track, after_track)
    # - Graceful error handling (tracking failures don't break app)
    #
    # @example Basic usage
    #   # In config/application.rb
    #   config.middleware.use UmamiClient::Middleware::Tracker,
    #     website_id: ENV['UMAMI_WEBSITE_ID'],
    #     skip_assets: true
    #
    # @example With custom configuration
    #   config.middleware.use UmamiClient::Middleware::Tracker,
    #     website_id: ENV['UMAMI_WEBSITE_ID'],
    #     skip_paths: [/^\/admin/, /^\/api/],
    #     async: true,
    #     before_track: ->(env) { puts "Tracking: #{env['PATH_INFO']}" }
    class Tracker
      attr_reader :app, :options, :client

      # Initialize the middleware
      #
      # @param app [#call] The Rack application
      # @param options [Hash] Configuration options
      # @option options [String] :website_id Website ID for tracking (required)
      # @option options [Array, Regexp, Proc] :skip_paths Paths to skip tracking
      # @option options [Boolean] :skip_assets Skip asset requests (default: true)
      # @option options [Boolean] :async Use background jobs (default: true)
      # @option options [Boolean] :enabled Enable middleware (default: true)
      # @option options [Proc] :before_track Callback before tracking
      # @option options [Proc] :after_track Callback after tracking
      def initialize(app, options = {})
        @app = app
        @options = options
        @client = UmamiClient::Client.new
      end

      # Process the request
      #
      # This is the main entry point for Rack middleware. It:
      # 1. Passes the request to the next middleware/app
      # 2. Tracks the page view (if not skipped)
      # 3. Returns the response unchanged
      #
      # @param env [Hash] Rack environment
      # @return [Array] Rack response tuple [status, headers, body]
      def call(env)
        # Call the next middleware/app first
        status, headers, body = @app.call(env)

        # Track the page view after the request completes
        # (Tracking happens in the background, doesn't block the response)
        track_page_view(env) if should_track?(env)

        # Return the response unchanged
        [status, headers, body]
      rescue StandardError => e
        # If tracking fails, log the error but don't break the app
        log_error("Middleware error: #{e.message}")

        # Still try to call the app
        @app.call(env)
      end

      private

      # Check if this request should be tracked
      #
      # @param env [Hash] Rack environment
      # @return [Boolean]
      def should_track?(env)
        # Middleware must be enabled
        return false unless options.fetch(:enabled, true)

        # Must have website_id configured
        return false unless options[:website_id]

        # TODO: Add path filtering logic in next phase
        true
      end

      # Track a page view for this request
      #
      # @param env [Hash] Rack environment
      # @return [void]
      def track_page_view(env)
        # TODO: Implement tracking logic in next phase
        # This will extract request data and send to Umami
      end

      # Log an error message
      #
      # @param message [String] Error message
      # @return [void]
      def log_error(message)
        if defined?(::Rails) && ::Rails.logger
          ::Rails.logger.error "[UmamiClient::Middleware] #{message}"
        else
          warn "[UmamiClient::Middleware] #{message}"
        end
      end
    end
  end
end
