# frozen_string_literal: true

module UmamiClient
  # Handles event tracking to Umami Analytics
  #
  # The Events class provides methods for tracking custom events and pageviews
  # to your Umami instance. Events are sent to the /api/send endpoint which
  # does not require authentication.
  class Events
    attr_reader :connection, :website_id, :default_hostname, :user_agent, :disabled, :logger
    attr_accessor :user_id

    # Creates a new Events instance
    #
    # @param connection [Connection] the HTTP connection instance
    # @param website_id [String, nil] default website ID for tracking
    # @param default_hostname [String, nil] default hostname for events
    # @param user_agent [String] User-Agent string for tracking requests
    # @param disabled [Boolean] whether tracking is disabled
    # @param logger [Logger, nil] optional logger for debugging
    def initialize(connection:, website_id: nil, default_hostname: nil, user_agent:, disabled: false, logger: nil)
      @connection = connection
      @website_id = website_id
      @default_hostname = default_hostname
      @user_agent = user_agent
      @user_id = nil
      @disabled = disabled
      @logger = logger
    end

    # Tracks a pageview to Umami Analytics
    #
    # This sends a pageview event (without a custom event name) which is the standard
    # way to track page visits in Umami.
    #
    # @param url [String] the URL path (default: "/")
    # @param website_id [String, nil] website ID (uses default if not provided)
    # @param hostname [String, nil] domain name (uses default if not provided)
    # @param referrer [String, nil] the referrer URL
    # @param title [String, nil] page title
    # @param screen [String] screen resolution (default: "1920x1080")
    # @param language [String] language code (default: "en-US")
    #
    # @return [Response] response containing cache, sessionId, visitId
    #
    # @raise [ValidationError] if required parameters are missing
    # @raise [APIError] if the API request fails
    #
    # @example Track a simple pageview
    #   events.track_pageview("/")
    #
    # @example Track pageview with title
    #   events.track_pageview("/products", title: "Products Page")
    #
    # @example Track pageview with referrer
    #   events.track_pageview("/blog/post-1",
    #     title: "Blog Post",
    #     referrer: "https://google.com"
    #   )
    def track_pageview(url, website_id: nil, hostname: nil, referrer: nil,
                       title: nil, screen: "1920x1080", language: "en-US")
      # Validate required parameters
      raise ValidationError, "url is required" if url.nil? || url.empty?

      # Use provided website_id or fall back to default
      site_id = website_id || @website_id
      raise ValidationError, "website_id is required" if site_id.nil? || site_id.empty?

      # Use provided hostname or fall back to default
      host = hostname || @default_hostname
      raise ValidationError, "hostname is required" if host.nil? || host.empty?

      # Build the payload (NO name field for pageviews)
      payload = {
        type: "event",
        payload: {
          website: site_id,
          hostname: host,
          url: url,
          screen: screen,
          language: language
        }
      }

      # Add optional fields
      payload[:payload][:referrer] = referrer if referrer
      payload[:payload][:title] = title if title
      payload[:payload][:id] = @user_id if @user_id

      # Send the request
      send_event(payload)
    end

    # Tracks a custom event to Umami Analytics
    #
    # Note: Custom events with the 'name' field may not show up in some Umami versions.
    # For reliable tracking, use track_pageview instead.
    #
    # @param event_name [String] the name of the event to track
    # @param website_id [String, nil] website ID (uses default if not provided)
    # @param hostname [String, nil] domain name (uses default if not provided)
    # @param url [String] the URL where the event occurred (default: "/")
    # @param referrer [String, nil] the referrer URL
    # @param title [String, nil] page title
    # @param data [Hash] custom event properties
    #
    # @return [Response] response containing sessionId, visitId
    #
    # @raise [ValidationError] if required parameters are missing or invalid
    # @raise [APIError] if the API request fails
    #
    # @example Track a simple event
    #   events.track_event("button_click")
    #
    # @example Track an event with custom data
    #   events.track_event("purchase",
    #     url: "/checkout/complete",
    #     data: { amount: 99.99, currency: "USD", product_id: "prod_123" }
    #   )
    def track_event(event_name, website_id: nil, hostname: nil, url: "/",
                    referrer: nil, title: nil, data: {})
      # Validate required parameters
      raise ValidationError, "event_name is required" if event_name.nil? || event_name.empty?

      # Use provided website_id or fall back to default
      site_id = website_id || @website_id
      raise ValidationError, "website_id is required" if site_id.nil? || site_id.empty?

      # Use provided hostname or fall back to default
      host = hostname || @default_hostname
      raise ValidationError, "hostname is required" if host.nil? || host.empty?

      # Validate and sanitize event data
      validated_data = validate_event_data(data)

      # Build the payload with required fields
      payload = {
        type: "event",
        payload: {
          website: site_id,
          hostname: host,
          url: url,
          name: event_name,
          # Required fields per Umami API documentation
          screen: "1920x1080",  # Default screen resolution
          language: "en-US"     # Default language
        }
      }

      # Add optional fields
      payload[:payload][:referrer] = referrer if referrer
      payload[:payload][:title] = title || ""
      payload[:payload][:data] = validated_data unless validated_data.empty?
      payload[:payload][:id] = @user_id if @user_id

      # Send the request
      send_event(payload)
    end

    # Identifies a user and associates them with the current session
    #
    # This method sends an event with a distinct ID to identify a specific user,
    # allowing you to track their activity across sessions and devices. The ID
    # can be any unique identifier such as a user ID, email, or customer ID.
    #
    # @param unique_id [String] unique identifier for the user (max 50 characters)
    # @param website_id [String, nil] website ID (uses default if not provided)
    # @param hostname [String, nil] domain name (uses default if not provided)
    # @param url [String] the URL where identification occurs (default: "/")
    # @param data [Hash] custom user properties to attach
    #
    # @return [Response] response containing sessionId and visitId
    #
    # @raise [ValidationError] if required parameters are missing or invalid
    # @raise [APIError] if the API request fails
    #
    # @example Identify a user by ID
    #   events.identify("user_12345")
    #
    # @example Identify with custom user properties
    #   events.identify("user_12345",
    #     data: {
    #       email: "john@example.com",
    #       name: "John Doe",
    #       plan: "premium",
    #       signup_date: "2024-01-15"
    #     }
    #   )
    #
    # @example Identify with specific website
    #   events.identify("customer_789",
    #     website_id: "different-site-id",
    #     data: { subscription: "annual" }
    #   )
    def identify(unique_id, website_id: nil, hostname: nil, url: "/", data: {})
      # Validate required parameters
      raise ValidationError, "unique_id is required" if unique_id.nil? || unique_id.empty?
      raise ValidationError, "unique_id cannot exceed 50 characters" if unique_id.length > 50

      # Store the user ID so it persists across subsequent events
      @user_id = unique_id

      # Use provided website_id or fall back to default
      site_id = website_id || @website_id
      raise ValidationError, "website_id is required" if site_id.nil? || site_id.empty?

      # Use provided hostname or fall back to default
      host = hostname || @default_hostname
      raise ValidationError, "hostname is required" if host.nil? || host.empty?

      # Validate and sanitize user data
      validated_data = validate_event_data(data)

      # Build the payload for user identification
      # Use type: "identify" to store user properties (not type: "event")
      # The payload needs BOTH the id field AND the data field
      payload = {
        type: "identify",
        payload: {
          website: site_id,
          hostname: host,
          url: url,
          id: unique_id,        # The user identifier
          # Required fields per Umami API documentation
          screen: "1920x1080",  # Default screen resolution
          language: "en-US",    # Default language
          data: validated_data  # User properties go in the data field
        }
      }

      # Send the request
      send_event(payload)
    end

    # Clears the current user identification
    #
    # After calling this method, subsequent events will not include a user ID
    # until identify is called again.
    #
    # @return [nil]
    #
    # @example Clear user identification (e.g., after logout)
    #   events.reset_user
    def reset_user
      @user_id = nil
    end

    private

    # Sends an event payload to Umami
    #
    # @param payload [Hash] the event payload
    # @return [Response] the response
    def send_event(payload)
      # Check if tracking is disabled
      if disabled
        log_disabled_event(payload) if logger
        return mock_response
      end

      # /api/send is a public endpoint that doesn't require authentication
      # In fact, sending auth headers causes it to return {"beep": "boop"}
      # So we always send without authentication
      send_without_auth(payload)
    end

    # Sends event without authentication (public endpoint)
    #
    # @param payload [Hash] the event payload
    # @return [Response] the response
    def send_without_auth(payload)
      require 'faraday'

      conn = Faraday.new(url: connection.base_url) do |f|
        f.request :json
        f.response :json
        f.adapter Faraday.default_adapter
        # Use the configured User-Agent (defaults to realistic browser UA)
        f.headers["User-Agent"] = user_agent
      end

      response = conn.post("/api/send") do |req|
        req.headers["Content-Type"] = "application/json"
        req.body = payload
      end

      # Wrap in our Response model
      Response.new(response)
    end

    # Validates and sanitizes event data according to Umami constraints
    #
    # @param data [Hash] the event data to validate
    # @return [Hash] validated and sanitized data
    # @raise [ValidationError] if data exceeds constraints
    def validate_event_data(data)
      return {} if data.nil? || data.empty?

      raise ValidationError, "data must be a Hash" unless data.is_a?(Hash)

      # Check object property limit (50 max)
      if data.size > 50
        raise ValidationError, "Event data cannot have more than 50 properties (got #{data.size})"
      end

      validated = {}

      data.each do |key, value|
        validated_key = key.to_s

        validated[validated_key] = case value
                                   when Numeric
                                     # Numbers: max 4 decimal precision
                                     (value * 10_000).round / 10_000.0
                                   when String
                                     # Strings: 500 char limit
                                     truncate_string(value, 500)
                                   when Array
                                     # Arrays: convert to string with 500 char max
                                     truncate_string(value.join(", "), 500)
                                   when Hash
                                     # Nested objects: convert to JSON string with 500 char max
                                     truncate_string(value.to_json, 500)
                                   when TrueClass, FalseClass
                                     value
                                   when NilClass
                                     nil
                                   else
                                     # Other types: convert to string
                                     truncate_string(value.to_s, 500)
                                   end
      end

      validated
    end

    # Truncates a string to a maximum length
    #
    # @param str [String] the string to truncate
    # @param max_length [Integer] maximum length
    # @return [String] truncated string
    def truncate_string(str, max_length)
      return str if str.length <= max_length

      "#{str[0...max_length - 3]}..."
    end

    # Logs an event that would have been tracked if tracking wasn't disabled
    #
    # @param payload [Hash] the event payload
    # @return [void]
    def log_disabled_event(payload)
      event_type = payload[:type]
      event_payload = payload[:payload]

      log_message = "[Umami Disabled] Would have tracked #{event_type}: "
      log_message += "url=#{event_payload[:url]}"
      log_message += ", name=#{event_payload[:name]}" if event_payload[:name]
      log_message += ", id=#{event_payload[:id]}" if event_payload[:id]
      log_message += ", data=#{event_payload[:data]}" if event_payload[:data]

      logger.info(log_message)
    end

    # Creates a mock response for disabled mode
    #
    # @return [Response] a mock response
    def mock_response
      require 'securerandom'

      # Create a mock Faraday response-like object
      mock_faraday_response = Struct.new(:status, :body, :headers).new(
        200,
        {
          "cache" => "mock_cache_token",
          "sessionId" => SecureRandom.uuid,
          "visitId" => SecureRandom.uuid
        },
        {}
      )

      Response.new(mock_faraday_response)
    end
  end
end
