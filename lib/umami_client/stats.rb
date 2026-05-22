# frozen_string_literal: true

module UmamiClient
  # Handles website statistics and analytics retrieval
  #
  # The Stats class provides methods for retrieving analytics data including
  # summary statistics, time-series pageviews, metrics, and real-time data.
  class Stats
    attr_reader :connection

    # Creates a new Stats instance
    #
    # @param connection [Connection] the HTTP connection instance
    def initialize(connection:)
      @connection = connection
    end

    # Gets the number of active visitors in the last 5 minutes
    #
    # @param website_id [String] the website ID
    #
    # @return [Response] response containing {"visitors": number}
    #
    # @raise [ValidationError] if website_id is missing
    # @raise [AuthenticationError] if not authenticated
    # @raise [APIError] if the API request fails
    #
    # @example Get active visitors
    #   response = client.stats.active("website-id")
    #   puts "Active visitors: #{response.body['visitors']}"
    def active(website_id)
      raise ValidationError, "website_id is required" if website_id.nil? || website_id.empty?

      connection.get("/api/websites/#{website_id}/active")
    end

    # Gets summary statistics for a website
    #
    # Returns aggregated metrics including pageviews, visitors, visits,
    # bounces, and time spent.
    #
    # @param website_id [String] the website ID
    # @param start_at [Integer, Time] start timestamp (milliseconds or Time object)
    # @param end_at [Integer, Time] end timestamp (milliseconds or Time object)
    # @param unit [String, nil] time unit: 'minute', 'hour', 'day', 'month', 'year'
    # @param timezone [String, nil] timezone (e.g., 'America/New_York')
    # @param filters [Hash, nil] optional filters (url, referrer, title, etc.)
    #
    # @return [Response] response containing summary statistics
    #
    # @raise [ValidationError] if required parameters are missing
    # @raise [AuthenticationError] if not authenticated
    # @raise [APIError] if the API request fails
    #
    # @example Get today's stats
    #   response = client.stats.summary(
    #     "website-id",
    #     Time.now.beginning_of_day,
    #     Time.now
    #   )
    #   puts "Pageviews: #{response.body['pageviews']['value']}"
    #   puts "Visitors: #{response.body['visitors']['value']}"
    def summary(website_id, start_at, end_at, unit: nil, timezone: nil, filters: nil)
      raise ValidationError, "website_id is required" if website_id.nil? || website_id.empty?
      raise ValidationError, "start_at is required" if start_at.nil?
      raise ValidationError, "end_at is required" if end_at.nil?

      params = {
        startAt: to_timestamp(start_at),
        endAt: to_timestamp(end_at)
      }
      params[:unit] = unit if unit
      params[:timezone] = timezone if timezone
      params.merge!(filters) if filters.is_a?(Hash) && !filters.empty?

      connection.get("/api/websites/#{website_id}/stats", params)
    end

    # Gets pageview time-series data
    #
    # Returns time-bucketed pageview counts and session counts.
    #
    # @param website_id [String] the website ID
    # @param start_at [Integer, Time] start timestamp (milliseconds or Time object)
    # @param end_at [Integer, Time] end timestamp (milliseconds or Time object)
    # @param unit [String, nil] time unit: 'minute', 'hour', 'day', 'month', 'year'
    # @param timezone [String, nil] timezone (e.g., 'America/New_York')
    # @param compare [String, nil] comparison mode: 'prev' (previous period) or 'yoy' (year over year)
    # @param filters [Hash, nil] optional filters
    #
    # @return [Response] response containing time-series data
    #
    # @raise [ValidationError] if required parameters are missing
    # @raise [AuthenticationError] if not authenticated
    # @raise [APIError] if the API request fails
    #
    # @example Get last 7 days pageviews
    #   response = client.stats.pageviews(
    #     "website-id",
    #     Time.now - 7.days,
    #     Time.now,
    #     unit: 'day'
    #   )
    #   response.body['pageviews'].each do |data_point|
    #     puts "#{data_point['x']}: #{data_point['y']} pageviews"
    #   end
    def pageviews(website_id, start_at, end_at, unit: nil, timezone: nil, compare: nil, filters: nil)
      raise ValidationError, "website_id is required" if website_id.nil? || website_id.empty?
      raise ValidationError, "start_at is required" if start_at.nil?
      raise ValidationError, "end_at is required" if end_at.nil?

      tz = timezone || "UTC"

      params = {
        startAt: to_timestamp(start_at),
        endAt: to_timestamp(end_at),
        timezone: tz
      }
      params[:unit] = unit if unit
      params[:compare] = compare if compare
      params.merge!(filters) if filters.is_a?(Hash) && !filters.empty?

      connection.get("/api/websites/#{website_id}/pageviews", params)
    end

    # Gets aggregated metrics
    #
    # Returns metrics like top pages, referrers, countries, browsers, etc.
    #
    # @param website_id [String] the website ID
    # @param start_at [Integer, Time] start timestamp (milliseconds or Time object)
    # @param end_at [Integer, Time] end timestamp (milliseconds or Time object)
    # @param type [String] metric type: 'url', 'referrer', 'browser', 'os', 'device',
    #   'country', 'event', 'title', 'query', 'language', etc.
    # @param unit [String, nil] time unit
    # @param timezone [String, nil] timezone
    # @param filters [Hash, nil] optional filters
    # @param limit [Integer, nil] max results (default: server default)
    # @param offset [Integer, nil] pagination offset
    #
    # @return [Response] response containing array of {name, count} pairs
    #
    # @raise [ValidationError] if required parameters are missing
    # @raise [AuthenticationError] if not authenticated
    # @raise [APIError] if the API request fails
    #
    # @example Get top pages
    #   response = client.stats.metrics(
    #     "website-id",
    #     Time.now - 30.days,
    #     Time.now,
    #     "url",
    #     limit: 10
    #   )
    #   response.body.each do |metric|
    #     puts "#{metric['x']}: #{metric['y']} views"
    #   end
    def metrics(website_id, start_at, end_at, type, unit: nil, timezone: nil, filters: nil, limit: nil, offset: nil)
      raise ValidationError, "website_id is required" if website_id.nil? || website_id.empty?
      raise ValidationError, "start_at is required" if start_at.nil?
      raise ValidationError, "end_at is required" if end_at.nil?
      raise ValidationError, "type is required" if type.nil? || type.empty?

      params = {
        startAt: to_timestamp(start_at),
        endAt: to_timestamp(end_at),
        type: type
      }
      params[:unit] = unit if unit
      params[:timezone] = timezone if timezone
      params.merge!(filters) if filters.is_a?(Hash) && !filters.empty?
      params[:limit] = limit if limit
      params[:offset] = offset if offset

      connection.get("/api/websites/#{website_id}/metrics", params)
    end

    # Gets event time-series data
    #
    # Returns time-bucketed event data with event names and counts.
    #
    # @param website_id [String] the website ID
    # @param start_at [Integer, Time] start timestamp (milliseconds or Time object)
    # @param end_at [Integer, Time] end timestamp (milliseconds or Time object)
    # @param unit [String, nil] time unit: 'minute', 'hour', 'day', 'month', 'year'
    # @param timezone [String, nil] timezone
    # @param filters [Hash, nil] optional filters
    #
    # @return [Response] response containing event series data
    #
    # @raise [ValidationError] if required parameters are missing
    # @raise [AuthenticationError] if not authenticated
    # @raise [APIError] if the API request fails
    #
    # @example Get event series
    #   response = client.stats.events_series(
    #     "website-id",
    #     Time.now - 7.days,
    #     Time.now,
    #     unit: 'day'
    #   )
    def events_series(website_id, start_at, end_at, unit: nil, timezone: nil, filters: nil)
      raise ValidationError, "website_id is required" if website_id.nil? || website_id.empty?
      raise ValidationError, "start_at is required" if start_at.nil?
      raise ValidationError, "end_at is required" if end_at.nil?

      params = {
        startAt: to_timestamp(start_at),
        endAt: to_timestamp(end_at)
      }
      params[:unit] = unit if unit
      params[:timezone] = timezone if timezone
      params.merge!(filters) if filters.is_a?(Hash) && !filters.empty?

      connection.get("/api/websites/#{website_id}/events/series", params)
    end

    # Convenience: Get stats for today
    #
    # @param website_id [String] the website ID
    # @param timezone [String, nil] timezone (defaults to UTC)
    # @return [Response] response containing today's stats
    def today(website_id, timezone: nil)
      tz = timezone || "UTC"
      now = Time.now
      start_of_day = Time.new(now.year, now.month, now.day, 0, 0, 0, tz)

      summary(website_id, start_of_day, now, timezone: tz)
    end

    # Convenience: Get stats for yesterday
    #
    # @param website_id [String] the website ID
    # @param timezone [String, nil] timezone (defaults to UTC)
    # @return [Response] response containing yesterday's stats
    def yesterday(website_id, timezone: nil)
      tz = timezone || "UTC"
      now = Time.now
      yesterday = now - (24 * 60 * 60)
      start_of_yesterday = Time.new(yesterday.year, yesterday.month, yesterday.day, 0, 0, 0, tz)
      end_of_yesterday = Time.new(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59, tz)

      summary(website_id, start_of_yesterday, end_of_yesterday, timezone: tz)
    end

    # Convenience: Get stats for the last 7 days
    #
    # @param website_id [String] the website ID
    # @param timezone [String, nil] timezone (defaults to UTC)
    # @return [Response] response containing last 7 days stats
    def last_7_days(website_id, timezone: nil)
      tz = timezone || "UTC"
      now = Time.now
      seven_days_ago = now - (7 * 24 * 60 * 60)

      summary(website_id, seven_days_ago, now, unit: 'day', timezone: tz)
    end

    # Convenience: Get stats for the last 30 days
    #
    # @param website_id [String] the website ID
    # @param timezone [String, nil] timezone (defaults to UTC)
    # @return [Response] response containing last 30 days stats
    def last_30_days(website_id, timezone: nil)
      tz = timezone || "UTC"
      now = Time.now
      thirty_days_ago = now - (30 * 24 * 60 * 60)

      summary(website_id, thirty_days_ago, now, unit: 'day', timezone: tz)
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
