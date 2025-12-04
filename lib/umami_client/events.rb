# frozen_string_literal: true

module UmamiClient
  # Handles event tracking to Umami Analytics
  #
  # The Events class provides methods for tracking custom events and pageviews
  # to your Umami instance. Events are sent to the /api/send endpoint which
  # does not require authentication.
  class Events
    attr_reader :connection, :website_id, :default_hostname, :user_agent

    # Creates a new Events instance
    #
    # @param connection [Connection] the HTTP connection instance
    # @param website_id [String, nil] default website ID for tracking
    # @param default_hostname [String, nil] default hostname for events
    # @param user_agent [String] User-Agent string for tracking requests
    def initialize(connection:, website_id: nil, default_hostname: nil, user_agent:)
      @connection = connection
      @website_id = website_id
      @default_hostname = default_hostname
      @user_agent = user_agent
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
    # @return [Models::Response] response containing cache, sessionId, visitId
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
    # @return [Models::Response] response containing sessionId, visitId
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

      # Send the request
      send_event(payload)
    end

    private

    # Sends an event payload to Umami
    #
    # @param payload [Hash] the event payload
    # @return [Models::Response] the response
    def send_event(payload)
      # /api/send is a public endpoint that doesn't require authentication
      # In fact, sending auth headers causes it to return {"beep": "boop"}
      # So we always send without authentication
      send_without_auth(payload)
    end

    # Sends event without authentication (public endpoint)
    #
    # @param payload [Hash] the event payload
    # @return [Models::Response] the response
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
      Models::Response.new(response)
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
  end
end
