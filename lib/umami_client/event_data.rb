# frozen_string_literal: true

module UmamiClient
  # Handles event data retrieval and querying
  #
  # The EventData class provides methods for retrieving detailed event data,
  # including event lists, event properties, field values, and aggregated statistics.
  class EventData
    attr_reader :connection

    # Creates a new EventData instance
    #
    # @param connection [Connection] the HTTP connection instance
    def initialize(connection:)
      @connection = connection
    end

    # Gets website event details within a given time range
    #
    # Returns a list of all events with detailed information including
    # session IDs, device info, location, and event properties.
    #
    # @param website_id [String] the website ID
    # @param start_at [Integer, Time] start timestamp (milliseconds or Time object)
    # @param end_at [Integer, Time] end timestamp (milliseconds or Time object)
    # @param search [String, nil] optional search text filter
    # @param page [Integer, nil] page number (default: 1)
    # @param page_size [Integer, nil] results per page (default: 20)
    # @param filters [Hash, nil] optional filters
    #
    # @return [Response] response containing array of event objects
    #
    # @raise [ValidationError] if required parameters are missing
    # @raise [AuthenticationError] if not authenticated
    # @raise [APIError] if the API request fails
    #
    # @example List recent events
    #   response = client.event_data.events(
    #     "website-id",
    #     Time.now - 7.days,
    #     Time.now,
    #     page: 1,
    #     page_size: 50
    #   )
    #   response.body.each do |event|
    #     puts "#{event['eventName']}: #{event['urlPath']}"
    #   end
    def events(website_id, start_at, end_at, search: nil, page: nil, page_size: nil, filters: nil)
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

      connection.get("/api/websites/#{website_id}/events", params)
    end

    # Gets event-specific data for an individual event
    #
    # Retrieves all custom data properties associated with a specific event occurrence.
    #
    # @param website_id [String] the website ID
    # @param event_id [String] the event ID
    #
    # @return [Response] response containing array of event data objects
    #
    # @raise [ValidationError] if required parameters are missing
    # @raise [AuthenticationError] if not authenticated
    # @raise [APIError] if the API request fails
    #
    # @example Get event data
    #   response = client.event_data.get_event("website-id", "event-id")
    #   response.body.each do |data|
    #     puts "#{data['dataKey']}: #{data['stringValue'] || data['numberValue']}"
    #   end
    def get_event(website_id, event_id)
      raise ValidationError, "website_id is required" if website_id.nil? || website_id.empty?
      raise ValidationError, "event_id is required" if event_id.nil? || event_id.empty?

      connection.get("/api/websites/#{website_id}/event-data/#{event_id}")
    end

    # Gets event data names, properties, and counts
    #
    # Returns a list of event names with their properties and occurrence counts.
    #
    # @param website_id [String] the website ID
    # @param start_at [Integer, Time] start timestamp (milliseconds or Time object)
    # @param end_at [Integer, Time] end timestamp (milliseconds or Time object)
    # @param event [String, nil] optional event name filter
    # @param filters [Hash, nil] optional filters
    #
    # @return [Response] response containing array of event summary objects
    #
    # @raise [ValidationError] if required parameters are missing
    # @raise [AuthenticationError] if not authenticated
    # @raise [APIError] if the API request fails
    #
    # @example Get all event names and properties
    #   response = client.event_data.event_names(
    #     "website-id",
    #     Time.now - 30.days,
    #     Time.now
    #   )
    #   response.body.each do |event|
    #     puts "#{event['eventName']}.#{event['propertyName']}: #{event['total']}"
    #   end
    #
    # @example Filter by event name
    #   response = client.event_data.event_names(
    #     "website-id",
    #     Time.now - 30.days,
    #     Time.now,
    #     event: "purchase"
    #   )
    def event_names(website_id, start_at, end_at, event: nil, filters: nil)
      raise ValidationError, "website_id is required" if website_id.nil? || website_id.empty?
      raise ValidationError, "start_at is required" if start_at.nil?
      raise ValidationError, "end_at is required" if end_at.nil?

      params = {
        startAt: to_timestamp(start_at),
        endAt: to_timestamp(end_at)
      }
      params[:event] = event if event
      params.merge!(filters) if filters.is_a?(Hash) && !filters.empty?

      connection.get("/api/websites/#{website_id}/event-data/events", params)
    end

    # Gets event data property and value counts within a given time range
    #
    # Returns property names, data types, values, and their occurrence counts.
    #
    # @param website_id [String] the website ID
    # @param start_at [Integer, Time] start timestamp (milliseconds or Time object)
    # @param end_at [Integer, Time] end timestamp (milliseconds or Time object)
    # @param filters [Hash, nil] optional filters
    #
    # @return [Response] response containing array of field objects
    #
    # @raise [ValidationError] if required parameters are missing
    # @raise [AuthenticationError] if not authenticated
    # @raise [APIError] if the API request fails
    #
    # @example Get event fields
    #   response = client.event_data.fields(
    #     "website-id",
    #     Time.now - 30.days,
    #     Time.now
    #   )
    #   response.body.each do |field|
    #     puts "#{field['propertyName']} (#{field['dataType']}): #{field['value']} (#{field['total']}x)"
    #   end
    def fields(website_id, start_at, end_at, filters: nil)
      raise ValidationError, "website_id is required" if website_id.nil? || website_id.empty?
      raise ValidationError, "start_at is required" if start_at.nil?
      raise ValidationError, "end_at is required" if end_at.nil?

      params = {
        startAt: to_timestamp(start_at),
        endAt: to_timestamp(end_at)
      }
      params.merge!(filters) if filters.is_a?(Hash) && !filters.empty?

      connection.get("/api/websites/#{website_id}/event-data/fields", params)
    end

    # Gets event name and property counts for a website
    #
    # Returns all event names with their properties and total occurrence counts.
    #
    # @param website_id [String] the website ID
    # @param start_at [Integer, Time] start timestamp (milliseconds or Time object)
    # @param end_at [Integer, Time] end timestamp (milliseconds or Time object)
    # @param filters [Hash, nil] optional filters
    #
    # @return [Response] response containing array of property objects
    #
    # @raise [ValidationError] if required parameters are missing
    # @raise [AuthenticationError] if not authenticated
    # @raise [APIError] if the API request fails
    #
    # @example Get all event properties
    #   response = client.event_data.properties(
    #     "website-id",
    #     Time.now - 30.days,
    #     Time.now
    #   )
    #   response.body.each do |prop|
    #     puts "Event: #{prop['eventName']}, Property: #{prop['propertyName']}, Count: #{prop['total']}"
    #   end
    def properties(website_id, start_at, end_at, filters: nil)
      raise ValidationError, "website_id is required" if website_id.nil? || website_id.empty?
      raise ValidationError, "start_at is required" if start_at.nil?
      raise ValidationError, "end_at is required" if end_at.nil?

      params = {
        startAt: to_timestamp(start_at),
        endAt: to_timestamp(end_at)
      }
      params.merge!(filters) if filters.is_a?(Hash) && !filters.empty?

      connection.get("/api/websites/#{website_id}/event-data/properties", params)
    end

    # Gets event data counts for a given event and property
    #
    # Returns all unique values for a specific event property with their counts.
    #
    # @param website_id [String] the website ID
    # @param start_at [Integer, Time] start timestamp (milliseconds or Time object)
    # @param end_at [Integer, Time] end timestamp (milliseconds or Time object)
    # @param event [String] the event name
    # @param property_name [String] the property name
    # @param filters [Hash, nil] optional filters
    #
    # @return [Response] response containing array of value/count pairs
    #
    # @raise [ValidationError] if required parameters are missing
    # @raise [AuthenticationError] if not authenticated
    # @raise [APIError] if the API request fails
    #
    # @example Get values for a specific property
    #   response = client.event_data.values(
    #     "website-id",
    #     Time.now - 30.days,
    #     Time.now,
    #     "purchase",
    #     "product_id"
    #   )
    #   response.body.each do |item|
    #     puts "#{item['value']}: #{item['total']} purchases"
    #   end
    def values(website_id, start_at, end_at, event, property_name, filters: nil)
      raise ValidationError, "website_id is required" if website_id.nil? || website_id.empty?
      raise ValidationError, "start_at is required" if start_at.nil?
      raise ValidationError, "end_at is required" if end_at.nil?
      raise ValidationError, "event is required" if event.nil? || event.empty?
      raise ValidationError, "property_name is required" if property_name.nil? || property_name.empty?

      params = {
        startAt: to_timestamp(start_at),
        endAt: to_timestamp(end_at),
        event: event,
        propertyName: property_name
      }
      params.merge!(filters) if filters.is_a?(Hash) && !filters.empty?

      connection.get("/api/websites/#{website_id}/event-data/values", params)
    end

    # Gets aggregated website events, properties, and records within a given time range
    #
    # Returns summary statistics showing total counts of events, properties, and records.
    #
    # @param website_id [String] the website ID
    # @param start_at [Integer, Time] start timestamp (milliseconds or Time object)
    # @param end_at [Integer, Time] end timestamp (milliseconds or Time object)
    # @param filters [Hash, nil] optional filters
    #
    # @return [Response] response containing stats object with events, properties, and records counts
    #
    # @raise [ValidationError] if required parameters are missing
    # @raise [AuthenticationError] if not authenticated
    # @raise [APIError] if the API request fails
    #
    # @example Get event data stats
    #   response = client.event_data.stats(
    #     "website-id",
    #     Time.now - 30.days,
    #     Time.now
    #   )
    #   puts "Events: #{response.body['events']}"
    #   puts "Properties: #{response.body['properties']}"
    #   puts "Records: #{response.body['records']}"
    def stats(website_id, start_at, end_at, filters: nil)
      raise ValidationError, "website_id is required" if website_id.nil? || website_id.empty?
      raise ValidationError, "start_at is required" if start_at.nil?
      raise ValidationError, "end_at is required" if end_at.nil?

      params = {
        startAt: to_timestamp(start_at),
        endAt: to_timestamp(end_at)
      }
      params.merge!(filters) if filters.is_a?(Hash) && !filters.empty?

      connection.get("/api/websites/#{website_id}/event-data/stats", params)
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
