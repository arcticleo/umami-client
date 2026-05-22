# frozen_string_literal: true

module UmamiClient
  # Handles session retrieval and querying
  #
  # The Sessions class provides methods for retrieving session data, including
  # session lists, session details, activity logs, and custom properties (including distinct IDs).
  class Sessions
    attr_reader :connection

    # Creates a new Sessions instance
    #
    # @param connection [Connection] the HTTP connection instance
    def initialize(connection:)
      @connection = connection
    end

    # Gets website session details within a given time range
    #
    # Returns a list of sessions with browser, OS, device, location, and visit data.
    # Use the `search` parameter to find sessions by distinct ID.
    #
    # @param website_id [String] the website ID
    # @param start_at [Integer, Time] start timestamp (milliseconds or Time object)
    # @param end_at [Integer, Time] end timestamp (milliseconds or Time object)
    # @param search [String, nil] optional search text (searches distinct ID and other fields)
    # @param page [Integer, nil] page number (default: 1)
    # @param page_size [Integer, nil] results per page (default: 20)
    # @param filters [Hash, nil] optional filters
    #
    # @return [Response] response containing paginated array of session objects
    #
    # @raise [ValidationError] if required parameters are missing
    # @raise [AuthenticationError] if not authenticated
    # @raise [APIError] if the API request fails
    #
    # @example List recent sessions
    #   response = client.sessions.list(
    #     "website-id",
    #     Time.now - 7.days,
    #     Time.now,
    #     page_size: 50
    #   )
    #   response.body['data'].each do |session|
    #     puts "Session: #{session['id']}, Visits: #{session['visits']}"
    #   end
    #
    # @example Find sessions by distinct ID
    #   response = client.sessions.list(
    #     "website-id",
    #     Time.now - 30.days,
    #     Time.now,
    #     search: "user@example.com"
    #   )
    def list(website_id, start_at, end_at, search: nil, page: nil, page_size: nil, filters: nil)
      raise ValidationError, "website_id is required" if website_id.nil? || website_id.empty?
      raise ValidationError, "start_at is required" if start_at.nil?
      raise ValidationError, "end_at is required" if end_at.nil?

      params = {
        startAt: to_timestamp(start_at),
        endAt: to_timestamp(end_at)
      }
      params[:search] = search if search
      params[:page] = page if page
      params[:pageSize] = page_size if page_size
      params.merge!(filters) if filters.is_a?(Hash) && !filters.empty?

      connection.get("/api/websites/#{website_id}/sessions", params)
    end

    # Gets aggregated session statistics
    #
    # Returns metrics including pageviews, visitors, visits, countries, and events.
    #
    # @param website_id [String] the website ID
    # @param start_at [Integer, Time] start timestamp (milliseconds or Time object)
    # @param end_at [Integer, Time] end timestamp (milliseconds or Time object)
    # @param filters [Hash, nil] optional filters
    #
    # @return [Response] response containing session statistics
    #
    # @raise [ValidationError] if required parameters are missing
    # @raise [AuthenticationError] if not authenticated
    # @raise [APIError] if the API request fails
    #
    # @example Get session stats
    #   response = client.sessions.stats(
    #     "website-id",
    #     Time.now - 30.days,
    #     Time.now
    #   )
    #   puts "Pageviews: #{response.body['pageviews']}"
    #   puts "Visitors: #{response.body['visitors']}"
    def stats(website_id, start_at, end_at, filters: nil)
      raise ValidationError, "website_id is required" if website_id.nil? || website_id.empty?
      raise ValidationError, "start_at is required" if start_at.nil?
      raise ValidationError, "end_at is required" if end_at.nil?

      params = {
        startAt: to_timestamp(start_at),
        endAt: to_timestamp(end_at)
      }
      params.merge!(filters) if filters.is_a?(Hash) && !filters.empty?

      connection.get("/api/websites/#{website_id}/sessions/stats", params)
    end

    # Gets session count by hour of weekday
    #
    # Returns a 7x24 matrix showing session counts for each hour of each day of the week.
    #
    # @param website_id [String] the website ID
    # @param start_at [Integer, Time] start timestamp (milliseconds or Time object)
    # @param end_at [Integer, Time] end timestamp (milliseconds or Time object)
    # @param timezone [String, nil] timezone (e.g., 'America/New_York', defaults to UTC)
    # @param filters [Hash, nil] optional filters
    #
    # @return [Response] response containing 7-row array with 24 hourly values each
    #
    # @raise [ValidationError] if required parameters are missing
    # @raise [AuthenticationError] if not authenticated
    # @raise [APIError] if the API request fails
    #
    # @example Get weekly session pattern
    #   response = client.sessions.weekly(
    #     "website-id",
    #     Time.now - 30.days,
    #     Time.now,
    #     timezone: 'America/Los_Angeles'
    #   )
    #   response.body.each_with_index do |day, idx|
    #     weekday = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'][idx]
    #     puts "#{weekday}: #{day.sum} sessions"
    #   end
    def weekly(website_id, start_at, end_at, timezone: nil, filters: nil)
      raise ValidationError, "website_id is required" if website_id.nil? || website_id.empty?
      raise ValidationError, "start_at is required" if start_at.nil?
      raise ValidationError, "end_at is required" if end_at.nil?

      tz = timezone || "UTC"

      params = {
        startAt: to_timestamp(start_at),
        endAt: to_timestamp(end_at),
        timezone: tz
      }
      params.merge!(filters) if filters.is_a?(Hash) && !filters.empty?

      connection.get("/api/websites/#{website_id}/sessions/weekly", params)
    end

    # Gets individual session details
    #
    # Returns session information including browser, OS, device, location, and counts.
    #
    # @param website_id [String] the website ID
    # @param session_id [String] the session ID
    #
    # @return [Response] response containing session details
    #
    # @raise [ValidationError] if required parameters are missing
    # @raise [AuthenticationError] if not authenticated
    # @raise [APIError] if the API request fails
    #
    # @example Get session details
    #   response = client.sessions.get("website-id", "session-id")
    #   puts "Browser: #{response.body['browser']}"
    #   puts "Country: #{response.body['country']}"
    #   puts "Pageviews: #{response.body['pageviews']}"
    def get(website_id, session_id)
      raise ValidationError, "website_id is required" if website_id.nil? || website_id.empty?
      raise ValidationError, "session_id is required" if session_id.nil? || session_id.empty?

      connection.get("/api/websites/#{website_id}/sessions/#{session_id}")
    end

    # Gets session activity log
    #
    # Returns all pageviews and events for a session with timestamps, URLs, and referrers.
    #
    # @param website_id [String] the website ID
    # @param session_id [String] the session ID
    # @param start_at [Integer, Time] start timestamp (milliseconds or Time object)
    # @param end_at [Integer, Time] end timestamp (milliseconds or Time object)
    #
    # @return [Response] response containing activity log array
    #
    # @raise [ValidationError] if required parameters are missing
    # @raise [AuthenticationError] if not authenticated
    # @raise [APIError] if the API request fails
    #
    # @example Get session activity
    #   response = client.sessions.activity(
    #     "website-id",
    #     "session-id",
    #     Time.now - 30.days,
    #     Time.now
    #   )
    #   response.body.each do |activity|
    #     puts "#{activity['createdAt']}: #{activity['urlPath']}"
    #   end
    def activity(website_id, session_id, start_at, end_at)
      raise ValidationError, "website_id is required" if website_id.nil? || website_id.empty?
      raise ValidationError, "session_id is required" if session_id.nil? || session_id.empty?
      raise ValidationError, "start_at is required" if start_at.nil?
      raise ValidationError, "end_at is required" if end_at.nil?

      params = {
        startAt: to_timestamp(start_at),
        endAt: to_timestamp(end_at)
      }

      connection.get("/api/websites/#{website_id}/sessions/#{session_id}/activity", params)
    end

    # Gets session properties (including distinct ID)
    #
    # Returns custom properties associated with a session, such as email, name, plan, etc.
    # This is where the distinct ID set by `identify()` is stored.
    #
    # @param website_id [String] the website ID
    # @param session_id [String] the session ID
    #
    # @return [Response] response containing session properties hash
    #
    # @raise [ValidationError] if required parameters are missing
    # @raise [AuthenticationError] if not authenticated
    # @raise [APIError] if the API request fails
    #
    # @example Get session properties
    #   response = client.sessions.properties("website-id", "session-id")
    #   puts "Email: #{response.body['email']}"
    #   puts "Name: #{response.body['name']}"
    #   puts "Plan: #{response.body['plan']}"
    def properties(website_id, session_id)
      raise ValidationError, "website_id is required" if website_id.nil? || website_id.empty?
      raise ValidationError, "session_id is required" if session_id.nil? || session_id.empty?

      connection.get("/api/websites/#{website_id}/sessions/#{session_id}/properties")
    end

    # Gets session property names with occurrence counts
    #
    # Returns a list of all property names that have been set on sessions.
    #
    # @param website_id [String] the website ID
    # @param start_at [Integer, Time] start timestamp (milliseconds or Time object)
    # @param end_at [Integer, Time] end timestamp (milliseconds or Time object)
    # @param filters [Hash, nil] optional filters
    #
    # @return [Response] response containing array of property names with counts
    #
    # @raise [ValidationError] if required parameters are missing
    # @raise [AuthenticationError] if not authenticated
    # @raise [APIError] if the API request fails
    #
    # @example Get property names
    #   response = client.sessions.property_names(
    #     "website-id",
    #     Time.now - 30.days,
    #     Time.now
    #   )
    #   response.body.each do |prop|
    #     puts "#{prop['propertyName']}: #{prop['total']} sessions"
    #   end
    def property_names(website_id, start_at, end_at, filters: nil)
      raise ValidationError, "website_id is required" if website_id.nil? || website_id.empty?
      raise ValidationError, "start_at is required" if start_at.nil?
      raise ValidationError, "end_at is required" if end_at.nil?

      params = {
        startAt: to_timestamp(start_at),
        endAt: to_timestamp(end_at)
      }
      params.merge!(filters) if filters.is_a?(Hash) && !filters.empty?

      connection.get("/api/websites/#{website_id}/session-data/properties", params)
    end

    # Gets values for a specific session property
    #
    # Returns all unique values for a property with their occurrence counts.
    #
    # @param website_id [String] the website ID
    # @param property_name [String] the property name to query
    # @param start_at [Integer, Time, nil] optional start timestamp
    # @param end_at [Integer, Time, nil] optional end timestamp
    # @param filters [Hash, nil] optional filters
    #
    # @return [Response] response containing array of value/count pairs
    #
    # @raise [ValidationError] if required parameters are missing
    # @raise [AuthenticationError] if not authenticated
    # @raise [APIError] if the API request fails
    #
    # @example Get values for 'plan' property
    #   response = client.sessions.property_values(
    #     "website-id",
    #     "plan"
    #   )
    #   response.body.each do |item|
    #     puts "#{item['value']}: #{item['total']} sessions"
    #   end
    #
    # @example With date range
    #   response = client.sessions.property_values(
    #     "website-id",
    #     "plan",
    #     start_at: Time.now - 30.days,
    #     end_at: Time.now
    #   )
    def property_values(website_id, property_name, start_at: nil, end_at: nil, filters: nil)
      raise ValidationError, "website_id is required" if website_id.nil? || website_id.empty?
      raise ValidationError, "property_name is required" if property_name.nil? || property_name.empty?

      params = {
        propertyName: property_name
      }
      if start_at && end_at
        params[:startAt] = to_timestamp(start_at)
        params[:endAt] = to_timestamp(end_at)
      end
      params.merge!(filters) if filters.is_a?(Hash) && !filters.empty?

      connection.get("/api/websites/#{website_id}/session-data/values", params)
    end

    private

    # Converts a Time object or timestamp to milliseconds
    #
    # @param time [Integer, Time] timestamp in milliseconds or Time object
    # @return [Integer] timestamp in milliseconds
    def to_timestamp(time)
      return time if time.is_a?(Integer)
      return (time.to_f * 1000).to_i if time.respond_to?(:to_f)

      raise ValidationError, "Invalid time format: #{time.inspect}"
    end
  end
end
