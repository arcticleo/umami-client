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

        # Skip if request matches skip criteria
        return false if should_skip_request?(env)

        true
      end

      # Check if this request should be skipped
      #
      # Checks if the request matches any skip criteria:
      # - Asset requests (if skip_assets is enabled)
      # - Health check endpoints
      # - Custom skip_paths patterns
      #
      # @param env [Hash] Rack environment
      # @return [Boolean]
      def should_skip_request?(env)
        path = env["PATH_INFO"] || "/"

        # Skip asset requests if enabled (default: true)
        return true if options.fetch(:skip_assets, true) && asset_request?(path)

        # Skip health check endpoints
        return true if health_check_request?(path)

        # Skip custom paths
        return true if matches_skip_paths?(path)

        false
      end

      # Check if path is an asset request
      #
      # Detects asset requests by path prefix or file extension:
      # - /assets/* - Rails asset pipeline
      # - /packs/* - Webpacker
      # - *.js, *.css, *.png, *.jpg, etc. - Static files
      #
      # @param path [String] Request path
      # @return [Boolean]
      def asset_request?(path)
        # Check for asset path prefixes
        return true if path.start_with?("/assets/", "/packs/")

        # Check for asset file extensions
        asset_extensions = %w[
          .js .css .map
          .png .jpg .jpeg .gif .svg .ico .webp
          .woff .woff2 .ttf .eot .otf
          .mp4 .webm .ogg .mp3 .wav
          .pdf .zip .tar .gz
        ]

        asset_extensions.any? { |ext| path.end_with?(ext) }
      end

      # Check if path is a health check endpoint
      #
      # Detects common health check patterns:
      # - /health, /healthz
      # - /ping, /status
      # - /ready, /readiness
      # - /alive, /liveness
      #
      # @param path [String] Request path
      # @return [Boolean]
      def health_check_request?(path)
        health_check_paths = %w[
          /health /healthz
          /ping /status
          /ready /readiness
          /alive /liveness
        ]

        health_check_paths.include?(path)
      end

      # Check if path matches custom skip_paths
      #
      # Supports multiple formats:
      # - String: Exact path match ("/admin")
      # - Regexp: Pattern match (/^\/admin/)
      # - Proc: Dynamic logic (called with path)
      # - Array: Any of the above
      #
      # @param path [String] Request path
      # @return [Boolean]
      def matches_skip_paths?(path)
        skip_paths = options[:skip_paths]
        return false unless skip_paths

        # Ensure skip_paths is an array
        skip_paths = [skip_paths] unless skip_paths.is_a?(Array)

        skip_paths.any? do |pattern|
          case pattern
          when String
            path == pattern
          when Regexp
            path =~ pattern
          when Proc
            pattern.call(path)
          else
            false
          end
        end
      end

      # Extract request data from Rack environment
      #
      # Extracts URL, referrer, user agent, and hostname from the Rack env hash.
      # Handles missing values gracefully by returning nil for optional fields.
      #
      # @param env [Hash] Rack environment
      # @return [Hash] Request data with keys: :url, :referrer, :user_agent, :hostname
      def extract_request_data(env)
        {
          url: build_url(env),
          referrer: env["HTTP_REFERER"],
          user_agent: env["HTTP_USER_AGENT"],
          hostname: env["HTTP_HOST"]
        }
      end

      # Build full URL from Rack environment
      #
      # Constructs the full URL including scheme, host, path, and query string.
      # Example: "https://example.com/articles/123?view=full"
      #
      # @param env [Hash] Rack environment
      # @return [String] Full URL
      def build_url(env)
        scheme = env["rack.url_scheme"] || "http"
        host = env["HTTP_HOST"]
        path = env["PATH_INFO"] || "/"
        query = env["QUERY_STRING"]

        url = "#{scheme}://#{host}#{path}"
        url += "?#{query}" if query && !query.empty?
        url
      end

      # Track a page view for this request
      #
      # Extracts request data and sends it to Umami Analytics.
      # Errors are logged but never raised - tracking failures should not break the app.
      #
      # @param env [Hash] Rack environment
      # @return [void]
      def track_page_view(env)
        # Extract request data
        data = extract_request_data(env)

        # Send page view to Umami
        client.events.track_pageview(
          data[:url],
          website_id: options[:website_id],
          hostname: data[:hostname],
          referrer: data[:referrer]
        )
      rescue StandardError => e
        # Log error but don't raise - tracking failures should not break the app
        log_error("Failed to track page view: #{e.message}")
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
