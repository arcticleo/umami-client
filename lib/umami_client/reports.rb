# frozen_string_literal: true

module UmamiClient
  # Handles report management and retrieval
  #
  # The Reports class provides methods for creating, reading, updating, and deleting reports.
  # Reports are saved analytics queries that can be executed repeatedly with consistent parameters.
  class Reports
    attr_reader :connection

    # Creates a new Reports instance
    #
    # @param connection [Connection] the HTTP connection instance
    def initialize(connection:)
      @connection = connection
    end

    # Lists all reports for a website
    #
    # Returns a paginated list of reports with optional type filtering.
    #
    # @param website_id [String] the website ID
    # @param type [String, nil] optional report type filter (attribution, breakdown, funnel, goal, journey, retention, revenue, utm)
    # @param page [Integer, nil] page number (default: 1)
    # @param page_size [Integer, nil] results per page (default: 20)
    #
    # @return [Response] response containing paginated array of report objects
    #
    # @raise [ValidationError] if required parameters are missing
    # @raise [AuthenticationError] if not authenticated
    # @raise [APIError] if the API request fails
    #
    # @example List all reports for a website
    #   response = client.reports.list("website-id")
    #   response.body['data'].each do |report|
    #     puts "Report: #{report['name']} (#{report['type']})"
    #   end
    #
    # @example Filter by report type
    #   response = client.reports.list("website-id", type: "funnel")
    #
    # @example With pagination
    #   response = client.reports.list("website-id", page: 2, page_size: 50)
    def list(website_id, type: nil, page: nil, page_size: nil)
      raise ValidationError, "website_id is required" if website_id.nil? || website_id.empty?

      params = { websiteId: website_id }
      params[:type] = type if type
      params[:page] = page if page
      params[:pageSize] = page_size if page_size

      connection.get("/api/reports", params)
    end

    # Creates a new report
    #
    # Creates a saved report with specified parameters that can be executed repeatedly.
    #
    # @param website_id [String] the website ID
    # @param name [String] the report name
    # @param type [String] the report type (attribution, breakdown, funnel, goal, journey, retention, revenue, utm)
    # @param parameters [Hash] the report configuration parameters (type-specific)
    # @param description [String, nil] optional report description
    #
    # @return [Response] response containing the created report object
    #
    # @raise [ValidationError] if required parameters are missing
    # @raise [AuthenticationError] if not authenticated
    # @raise [APIError] if the API request fails
    #
    # @example Create a funnel report
    #   response = client.reports.create(
    #     "website-id",
    #     "Signup Funnel",
    #     "funnel",
    #     {
    #       window: 30,
    #       steps: [
    #         { url: "/signup" },
    #         { url: "/confirm-email" },
    #         { url: "/welcome" }
    #       ]
    #     },
    #     description: "User signup completion flow"
    #   )
    #   puts "Created report: #{response.body['id']}"
    def create(website_id, name, type, parameters, description: nil)
      raise ValidationError, "website_id is required" if website_id.nil? || website_id.empty?
      raise ValidationError, "name is required" if name.nil? || name.empty?
      raise ValidationError, "type is required" if type.nil? || type.empty?
      raise ValidationError, "parameters is required" if parameters.nil?

      body = {
        websiteId: website_id,
        name: name,
        type: type,
        parameters: parameters
      }
      body[:description] = description if description

      connection.post("/api/reports", body)
    end

    # Gets a specific report by ID
    #
    # Returns full details of a single report including all configuration parameters.
    #
    # @param report_id [String] the report ID
    #
    # @return [Response] response containing the report object
    #
    # @raise [ValidationError] if required parameters are missing
    # @raise [AuthenticationError] if not authenticated
    # @raise [APIError] if the API request fails
    #
    # @example Get report details
    #   response = client.reports.get("report-id")
    #   puts "Report: #{response.body['name']}"
    #   puts "Type: #{response.body['type']}"
    #   puts "Parameters: #{response.body['parameters']}"
    def get(report_id)
      raise ValidationError, "report_id is required" if report_id.nil? || report_id.empty?

      connection.get("/api/reports/#{report_id}")
    end

    # Updates an existing report
    #
    # Updates report name, description, or parameters. All original creation parameters are required.
    #
    # @param report_id [String] the report ID
    # @param name [String] the report name
    # @param type [String] the report type
    # @param parameters [Hash] the report configuration parameters
    # @param description [String, nil] optional report description
    #
    # @return [Response] response containing the updated report object
    #
    # @raise [ValidationError] if required parameters are missing
    # @raise [AuthenticationError] if not authenticated
    # @raise [APIError] if the API request fails
    #
    # @example Update report name and description
    #   response = client.reports.update(
    #     "report-id",
    #     "Updated Signup Funnel",
    #     "funnel",
    #     { window: 30, steps: [...] },
    #     description: "Updated description"
    #   )
    def update(report_id, name, type, parameters, description: nil)
      raise ValidationError, "report_id is required" if report_id.nil? || report_id.empty?
      raise ValidationError, "name is required" if name.nil? || name.empty?
      raise ValidationError, "type is required" if type.nil? || type.empty?
      raise ValidationError, "parameters is required" if parameters.nil?

      body = {
        name: name,
        type: type,
        parameters: parameters
      }
      body[:description] = description if description

      connection.post("/api/reports/#{report_id}", body)
    end

    # Deletes a report
    #
    # Permanently removes a report. This action cannot be undone.
    #
    # @param report_id [String] the report ID
    #
    # @return [Response] response containing deletion confirmation
    #
    # @raise [ValidationError] if required parameters are missing
    # @raise [AuthenticationError] if not authenticated
    # @raise [APIError] if the API request fails
    #
    # @example Delete a report
    #   response = client.reports.delete("report-id")
    #   puts "Deleted: #{response.body['ok']}"  # => true
    def delete(report_id)
      raise ValidationError, "report_id is required" if report_id.nil? || report_id.empty?

      connection.delete("/api/reports/#{report_id}")
    end

    # Executes a funnel report to analyze conversion and drop-off rates
    #
    # Analyzes user progression through a series of steps to identify conversion rates
    # and drop-off points. Useful for understanding where users abandon a process.
    #
    # @param website_id [String] the website ID
    # @param start_date [Time, String] start date (Time object or ISO 8601 string)
    # @param end_date [Time, String] end date (Time object or ISO 8601 string)
    # @param steps [Array<Hash>] array of funnel steps (minimum 2 steps)
    #   Each step must have:
    #   - type [String]: "path" for URL paths or "event" for custom events
    #   - value [String]: the URL path or event name
    # @param window [Integer] conversion window in days (default: 30)
    # @param filters [Hash, nil] optional filters (country, device, browser, os, etc.)
    #
    # @return [Response] response containing funnel analysis with conversion rates
    #
    # @raise [ValidationError] if required parameters are missing or invalid
    # @raise [AuthenticationError] if not authenticated
    # @raise [APIError] if the API request fails
    #
    # @example Basic signup funnel
    #   response = client.reports.funnel(
    #     "website-id",
    #     Time.now - 30.days,
    #     Time.now,
    #     [
    #       { type: "path", value: "/signup" },
    #       { type: "path", value: "/confirm-email" },
    #       { type: "path", value: "/welcome" }
    #     ],
    #     30
    #   )
    #
    #   response.body.each_with_index do |step, index|
    #     puts "Step #{index + 1}: #{step['visitors']} visitors (#{step['conversionRate']}% conversion)"
    #   end
    #
    # @example E-commerce checkout funnel with events
    #   response = client.reports.funnel(
    #     "website-id",
    #     Time.now - 7.days,
    #     Time.now,
    #     [
    #       { type: "path", value: "/cart" },
    #       { type: "event", value: "begin-checkout" },
    #       { type: "event", value: "add-payment-info" },
    #       { type: "event", value: "purchase" }
    #     ],
    #     7,
    #     filters: { country: "US" }
    #   )
    #
    # @example Using ISO date strings
    #   response = client.reports.funnel(
    #     "website-id",
    #     "2025-01-01T00:00:00.000Z",
    #     "2025-01-31T23:59:59.999Z",
    #     [
    #       { type: "path", value: "/landing" },
    #       { type: "path", value: "/pricing" },
    #       { type: "path", value: "/checkout" }
    #     ]
    #   )
    def funnel(website_id, start_date, end_date, steps, window = 30, filters: nil)
      raise ValidationError, "website_id is required" if website_id.nil? || website_id.empty?
      raise ValidationError, "start_date is required" if start_date.nil?
      raise ValidationError, "end_date is required" if end_date.nil?
      raise ValidationError, "steps is required" if steps.nil?
      raise ValidationError, "steps must be an array" unless steps.is_a?(Array)
      raise ValidationError, "steps must contain at least 2 steps" if steps.length < 2

      # Validate each step
      steps.each_with_index do |step, index|
        raise ValidationError, "step #{index + 1} must be a Hash" unless step.is_a?(Hash)
        raise ValidationError, "step #{index + 1} must have a 'type' key" unless step.key?(:type) || step.key?("type")
        raise ValidationError, "step #{index + 1} must have a 'value' key" unless step.key?(:value) || step.key?("value")

        step_type = step[:type] || step["type"]
        raise ValidationError, "step #{index + 1} type must be 'path' or 'event'" unless %w[path event].include?(step_type)
      end

      body = {
        websiteId: website_id,
        type: "funnel",
        parameters: {
          startDate: format_date(start_date),
          endDate: format_date(end_date),
          steps: steps,
          window: window
        }
      }
      body[:filters] = filters if filters

      connection.post("/api/reports/funnel", body)
    end

    # Executes a journey report to analyze user navigation paths
    #
    # Analyzes actual paths users take through your website, revealing common navigation
    # patterns and unexpected routes. Unlike funnels (which track predefined sequential steps),
    # journey reports discover all possible paths users take between points.
    #
    # @param website_id [String] the website ID
    # @param start_date [Time, String] start date (Time object or ISO 8601 string)
    # @param end_date [Time, String] end date (Time object or ISO 8601 string)
    # @param start_step [String] entry point URL path or event name
    # @param steps [Integer] number of steps to track (3-7, default: 5)
    # @param end_step [String, nil] optional exit point to filter paths that reach this destination
    # @param filters [Hash, nil] optional filters (country, device, browser, os, etc.)
    #
    # @return [Response] response containing array of paths with frequency data
    #   Each path contains:
    #   - items: array of URLs/events in sequence
    #   - count: number of users who followed this path
    #
    # @raise [ValidationError] if required parameters are missing or invalid
    # @raise [AuthenticationError] if not authenticated
    # @raise [APIError] if the API request fails
    #
    # @example Discover paths from homepage
    #   response = client.reports.journey(
    #     "website-id",
    #     Time.now - 30.days,
    #     Time.now,
    #     "/",
    #     5
    #   )
    #
    #   puts "Top navigation paths from homepage:"
    #   response.body.first(10).each do |path|
    #     puts "#{path['count']} users: #{path['items'].join(' → ')}"
    #   end
    #
    # @example Find paths from homepage to pricing
    #   response = client.reports.journey(
    #     "website-id",
    #     Time.now - 30.days,
    #     Time.now,
    #     "/",
    #     5,
    #     end_step: "/pricing"
    #   )
    #
    #   puts "Most common routes to pricing page:"
    #   response.body.each do |path|
    #     intermediate = path['items'][1..-2].join(' → ')
    #     puts "#{path['count']} users via: #{intermediate}"
    #   end
    #
    # @example Track event-based journeys
    #   response = client.reports.journey(
    #     "website-id",
    #     Time.now - 7.days,
    #     Time.now,
    #     "signup",
    #     4,
    #     end_step: "first_purchase"
    #   )
    #
    # @example With filters
    #   response = client.reports.journey(
    #     "website-id",
    #     Time.now - 30.days,
    #     Time.now,
    #     "/landing",
    #     5,
    #     filters: { country: "US", device: "mobile" }
    #   )
    def journey(website_id, start_date, end_date, start_step, steps = 5, end_step: nil, filters: nil)
      raise ValidationError, "website_id is required" if website_id.nil? || website_id.empty?
      raise ValidationError, "start_date is required" if start_date.nil?
      raise ValidationError, "end_date is required" if end_date.nil?
      raise ValidationError, "start_step is required" if start_step.nil? || start_step.empty?
      raise ValidationError, "steps must be between 3 and 7" unless steps.between?(3, 7)

      body = {
        websiteId: website_id,
        type: "journey",
        parameters: {
          startDate: format_date(start_date),
          endDate: format_date(end_date),
          startStep: start_step,
          steps: steps
        }
      }
      body[:parameters][:endStep] = end_step if end_step
      body[:filters] = filters if filters

      connection.post("/api/reports/journey", body)
    end

    # Executes a retention report to analyze user return frequency
    #
    # Measures website stickiness by tracking how often users return over time.
    # Uses cohort analysis to show return rates for users who first visited on
    # specific dates, helping identify engagement trends and user loyalty.
    #
    # @param website_id [String] the website ID
    # @param start_date [Time, String] cohort period start (Time object or ISO 8601 string)
    # @param end_date [Time, String] cohort period end (Time object or ISO 8601 string)
    # @param timezone [String] timezone for cohort calculation (e.g., 'America/New_York', 'UTC')
    # @param filters [Hash, nil] optional filters (country, device, browser, os, etc.)
    #
    # @return [Response] response containing cohort retention data
    #   Each cohort entry contains:
    #   - date: cohort start date
    #   - day: days elapsed since cohort formation
    #   - visitors: initial cohort size
    #   - returnVisitors: count of users who returned
    #   - percentage: return rate as a percentage
    #
    # @raise [ValidationError] if required parameters are missing or invalid
    # @raise [AuthenticationError] if not authenticated
    # @raise [APIError] if the API request fails
    #
    # @example Basic retention analysis
    #   response = client.reports.retention(
    #     "website-id",
    #     Time.now - 30.days,
    #     Time.now,
    #     "America/New_York"
    #   )
    #
    #   puts "Retention Analysis:"
    #   response.body.each do |cohort|
    #     puts "Day #{cohort['day']}: #{cohort['percentage']}% returned"
    #   end
    #
    # @example Monthly retention cohorts
    #   response = client.reports.retention(
    #     "website-id",
    #     Time.now - 90.days,
    #     Time.now,
    #     "UTC"
    #   )
    #
    #   # Group by cohort date
    #   cohorts = response.body.group_by { |c| c['date'] }
    #   cohorts.each do |date, data|
    #     initial = data.first['visitors']
    #     day_30 = data.find { |d| d['day'] == 30 }&.fetch('percentage', 0)
    #     puts "#{date}: #{initial} users, #{day_30}% retained at day 30"
    #   end
    #
    # @example Retention by segment
    #   # Mobile users
    #   mobile = client.reports.retention(
    #     "website-id",
    #     Time.now - 30.days,
    #     Time.now,
    #     "UTC",
    #     filters: { device: "mobile" }
    #   )
    #
    #   # Desktop users
    #   desktop = client.reports.retention(
    #     "website-id",
    #     Time.now - 30.days,
    #     Time.now,
    #     "UTC",
    #     filters: { device: "desktop" }
    #   )
    #
    #   puts "Mobile day-7 retention: #{mobile.body.find { |d| d['day'] == 7 }['percentage']}%"
    #   puts "Desktop day-7 retention: #{desktop.body.find { |d| d['day'] == 7 }['percentage']}%"
    def retention(website_id, start_date, end_date, timezone, filters: nil)
      raise ValidationError, "website_id is required" if website_id.nil? || website_id.empty?
      raise ValidationError, "start_date is required" if start_date.nil?
      raise ValidationError, "end_date is required" if end_date.nil?
      raise ValidationError, "timezone is required" if timezone.nil? || timezone.empty?

      body = {
        websiteId: website_id,
        type: "retention",
        parameters: {
          startDate: format_date(start_date),
          endDate: format_date(end_date),
          timezone: timezone
        }
      }
      body[:filters] = filters if filters

      connection.post("/api/reports/retention", body)
    end

    # Executes a goal report to track single conversion points
    #
    # Monitors specific conversion actions like newsletter signups, demo requests,
    # or important page visits. Unlike funnels (which track multi-step journeys),
    # goals measure completion of a single action independently.
    #
    # @param website_id [String] the website ID
    # @param start_date [Time, String] start date (Time object or ISO 8601 string)
    # @param end_date [Time, String] end date (Time object or ISO 8601 string)
    # @param goal_type [String] goal type: "path" for URL paths or "event" for custom events
    # @param goal_value [String] the URL path or event name to track
    # @param filters [Hash, nil] optional filters (country, device, browser, os, etc.)
    #
    # @return [Response] response containing goal completion metrics
    #   - num: number of goal completions
    #   - total: total tracked events/pageviews
    #   - conversion rate: num / total * 100
    #
    # @raise [ValidationError] if required parameters are missing or invalid
    # @raise [AuthenticationError] if not authenticated
    # @raise [APIError] if the API request fails
    #
    # @example Track newsletter signup completions
    #   response = client.reports.goals(
    #     "website-id",
    #     Time.now - 30.days,
    #     Time.now,
    #     "event",
    #     "newsletter_signup"
    #   )
    #
    #   completions = response.body['num']
    #   total = response.body['total']
    #   rate = (completions.to_f / total * 100).round(2)
    #   puts "Newsletter signups: #{completions} / #{total} (#{rate}%)"
    #
    # @example Track thank you page visits
    #   response = client.reports.goals(
    #     "website-id",
    #     Time.now - 7.days,
    #     Time.now,
    #     "path",
    #     "/thank-you"
    #   )
    #
    #   puts "Conversions: #{response.body['num']}"
    #   puts "Conversion rate: #{(response.body['num'].to_f / response.body['total'] * 100).round(2)}%"
    #
    # @example Goal with filters (US visitors only)
    #   response = client.reports.goals(
    #     "website-id",
    #     Time.now - 30.days,
    #     Time.now,
    #     "event",
    #     "purchase",
    #     filters: { country: "US" }
    #   )
    def goals(website_id, start_date, end_date, goal_type, goal_value, filters: nil)
      raise ValidationError, "website_id is required" if website_id.nil? || website_id.empty?
      raise ValidationError, "start_date is required" if start_date.nil?
      raise ValidationError, "end_date is required" if end_date.nil?
      raise ValidationError, "goal_type is required" if goal_type.nil? || goal_type.empty?
      raise ValidationError, "goal_type must be 'path' or 'event'" unless %w[path event].include?(goal_type)
      raise ValidationError, "goal_value is required" if goal_value.nil? || goal_value.empty?

      body = {
        websiteId: website_id,
        type: "goal",
        parameters: {
          startDate: format_date(start_date),
          endDate: format_date(end_date),
          type: goal_type,
          value: goal_value
        }
      }
      body[:filters] = filters if filters

      connection.post("/api/reports/goals", body)
    end

    # Executes an attribution report to analyze marketing channel performance
    #
    # Shows how users engage with your marketing and what drives conversions.
    # Uses attribution models (first-click or last-click) to credit conversion
    # sources, revealing which channels bring traffic that converts.
    #
    # @param website_id [String] the website ID
    # @param start_date [Time, String] start date (Time object or ISO 8601 string)
    # @param end_date [Time, String] end date (Time object or ISO 8601 string)
    # @param attribution_model [String] attribution model: "firstClick" or "lastClick"
    # @param conversion_type [String] conversion type: "path" or "event"
    # @param conversion_step [String] the conversion URL path or event name to track
    # @param filters [Hash, nil] optional filters (country, device, browser, os, etc.)
    #
    # @return [Response] response containing attribution data by channel
    #   - referrer: top traffic sources
    #   - paidAds: paid advertising performance
    #   - utm_source, utm_medium, utm_campaign, utm_content, utm_term: UTM breakdowns
    #   - total: aggregate metrics (pageviews, visitors, visits)
    #
    # @raise [ValidationError] if required parameters are missing or invalid
    # @raise [AuthenticationError] if not authenticated
    # @raise [APIError] if the API request fails
    #
    # @example First-click attribution for purchases
    #   response = client.reports.attribution(
    #     "website-id",
    #     Time.now - 30.days,
    #     Time.now,
    #     "firstClick",
    #     "event",
    #     "purchase"
    #   )
    #
    #   # Show top referrers that lead to purchases
    #   response.body['referrer']&.each do |source|
    #     puts "#{source['name']}: #{source['value']} conversions"
    #   end
    #
    # @example Last-click attribution for signup page
    #   response = client.reports.attribution(
    #     "website-id",
    #     Time.now - 30.days,
    #     Time.now,
    #     "lastClick",
    #     "path",
    #     "/signup"
    #   )
    #
    #   # Analyze UTM sources
    #   response.body['utm_source']&.each do |source|
    #     puts "#{source['name']}: #{source['value']} conversions"
    #   end
    #
    # @example Attribution with filters (mobile only)
    #   response = client.reports.attribution(
    #     "website-id",
    #     Time.now - 30.days,
    #     Time.now,
    #     "firstClick",
    #     "event",
    #     "signup",
    #     filters: { device: "mobile" }
    #   )
    def attribution(website_id, start_date, end_date, attribution_model, conversion_type, conversion_step, filters: nil)
      raise ValidationError, "website_id is required" if website_id.nil? || website_id.empty?
      raise ValidationError, "start_date is required" if start_date.nil?
      raise ValidationError, "end_date is required" if end_date.nil?
      raise ValidationError, "attribution_model is required" if attribution_model.nil? || attribution_model.empty?
      raise ValidationError, "attribution_model must be 'firstClick' or 'lastClick'" unless %w[firstClick lastClick].include?(attribution_model)
      raise ValidationError, "conversion_type is required" if conversion_type.nil? || conversion_type.empty?
      raise ValidationError, "conversion_type must be 'path' or 'event'" unless %w[path event].include?(conversion_type)
      raise ValidationError, "conversion_step is required" if conversion_step.nil? || conversion_step.empty?

      body = {
        websiteId: website_id,
        type: "attribution",
        parameters: {
          startDate: format_date(start_date),
          endDate: format_date(end_date),
          model: attribution_model,
          type: conversion_type,
          step: conversion_step
        }
      }
      body[:filters] = filters if filters

      connection.post("/api/reports/attribution", body)
    end

    # Executes a breakdown report to segment data by dimensions
    #
    # Analyzes data across multiple dimensions to identify patterns in user behavior.
    # Break down metrics by operating system, country, device, browser, and more to
    # understand how different segments interact with your site.
    #
    # @param website_id [String] the website ID
    # @param start_date [Time, String] start date (Time object or ISO 8601 string)
    # @param end_date [Time, String] end date (Time object or ISO 8601 string)
    # @param fields [Array<String>] dimension fields to segment by
    #   Available fields: path, title, query, referrer, browser, os, device,
    #   country, region, city, hostname, tag, event
    # @param filters [Hash, nil] optional filters (country, device, browser, os, etc.)
    #
    # @return [Response] response containing breakdown data with metrics by dimension
    #   Each record includes: views, visitors, visits, bounces, totaltime
    #   Plus dimension values for selected fields
    #
    # @raise [ValidationError] if required parameters are missing or invalid
    # @raise [AuthenticationError] if not authenticated
    # @raise [APIError] if the API request fails
    #
    # @example Breakdown by operating system
    #   response = client.reports.breakdown(
    #     "website-id",
    #     Time.now - 30.days,
    #     Time.now,
    #     ["os"]
    #   )
    #
    #   response.body.each do |record|
    #     puts "#{record['os']}: #{record['visitors']} visitors, #{record['views']} views"
    #   end
    #
    # @example Breakdown by country and device
    #   response = client.reports.breakdown(
    #     "website-id",
    #     Time.now - 30.days,
    #     Time.now,
    #     ["country", "device"]
    #   )
    #
    #   response.body.each do |record|
    #     puts "#{record['country']} on #{record['device']}: #{record['visitors']} visitors"
    #   end
    #
    # @example Breakdown by browser with filters
    #   response = client.reports.breakdown(
    #     "website-id",
    #     Time.now - 7.days,
    #     Time.now,
    #     ["browser"],
    #     filters: { country: "US" }
    #   )
    def breakdown(website_id, start_date, end_date, fields, filters: nil)
      raise ValidationError, "website_id is required" if website_id.nil? || website_id.empty?
      raise ValidationError, "start_date is required" if start_date.nil?
      raise ValidationError, "end_date is required" if end_date.nil?
      raise ValidationError, "fields is required" if fields.nil?
      raise ValidationError, "fields must be an array" unless fields.is_a?(Array)
      raise ValidationError, "fields must not be empty" if fields.empty?

      # Available fields
      valid_fields = %w[path title query referrer browser os device country region city hostname tag event]

      # Validate each field
      fields.each do |field|
        unless valid_fields.include?(field.to_s)
          raise ValidationError, "Invalid field '#{field}'. Valid fields: #{valid_fields.join(', ')}"
        end
      end

      body = {
        websiteId: website_id,
        type: "breakdown",
        parameters: {
          startDate: format_date(start_date),
          endDate: format_date(end_date),
          fields: fields.map(&:to_s)
        }
      }
      body[:filters] = filters if filters

      connection.post("/api/reports/breakdown", body)
    end

    # Execute a revenue report
    #
    # Revenue reports enable tracking and analysis of financial data associated with user
    # conversions and transactions. Returns time-series data, geographic distribution,
    # and aggregate statistics including sum, count, unique visitors, and average transaction value.
    #
    # @param website_id [String] website ID
    # @param start_date [Time, String] start date (ISO 8601 or Time object)
    # @param end_date [Time, String] end date (ISO 8601 or Time object)
    # @param timezone [String] timezone (e.g., "America/Los_Angeles", "Europe/London")
    # @param currency [String] ISO 4217 currency code (e.g., "USD", "EUR", "GBP")
    # @param filters [Array<Hash>, nil] optional filters
    #
    # @return [Response] response with revenue data
    #
    # @example Basic revenue report
    #   response = client.reports.revenue(
    #     website_id,
    #     start_date,
    #     end_date,
    #     "America/New_York",
    #     "USD"
    #   )
    #
    #   # Time-series revenue data
    #   response.data['chart'].each do |point|
    #     puts "#{point['t']}: $#{point['y']}"
    #   end
    #
    #   # Revenue by country
    #   response.data['country'].each do |country|
    #     puts "#{country['name']}: $#{country['value']}"
    #   end
    #
    #   # Aggregate totals
    #   totals = response.data['total']
    #   puts "Total Revenue: $#{totals['sum']}"
    #   puts "Transactions: #{totals['count']}"
    #   puts "Unique Customers: #{totals['unique_count']}"
    #   puts "Average Order Value: $#{totals['average'].round(2)}"
    #
    # @example Revenue with filters
    #   response = client.reports.revenue(
    #     website_id,
    #     start_date,
    #     end_date,
    #     "America/Los_Angeles",
    #     "USD",
    #     filters: [
    #       { type: 'device', value: 'mobile' }
    #     ]
    #   )
    #
    # @example Revenue by country analysis
    #   response = client.reports.revenue(
    #     website_id,
    #     start_date,
    #     end_date,
    #     "UTC",
    #     "EUR"
    #   )
    #
    #   total_revenue = response.data['total']['sum']
    #   response.data['country'].each do |country|
    #     percentage = (country['value'].to_f / total_revenue * 100).round(1)
    #     puts "#{country['name']}: €#{country['value']} (#{percentage}%)"
    #   end
    #
    def revenue(website_id, start_date, end_date, timezone, currency, filters: nil)
      raise ValidationError, "website_id is required" if website_id.nil? || website_id.empty?
      raise ValidationError, "start_date is required" if start_date.nil?
      raise ValidationError, "end_date is required" if end_date.nil?
      raise ValidationError, "timezone is required" if timezone.nil? || timezone.empty?
      raise ValidationError, "currency is required" if currency.nil? || currency.empty?

      body = {
        websiteId: website_id,
        type: "revenue",
        parameters: {
          startDate: format_date(start_date),
          endDate: format_date(end_date),
          timezone: timezone,
          currency: currency.upcase
        }
      }
      body[:filters] = filters if filters

      connection.post("/api/reports/revenue", body)
    end

    # Execute a UTM report
    #
    # UTM reports track marketing campaigns through UTM parameters, analyzing campaign
    # performance across five dimensions: source, medium, campaign, content, and term.
    # Returns pageview counts for each UTM parameter value.
    #
    # @param website_id [String] website ID
    # @param start_date [Time, String] start date (ISO 8601 or Time object)
    # @param end_date [Time, String] end date (ISO 8601 or Time object)
    # @param filters [Array<Hash>, nil] optional filters
    #
    # @return [Response] response with UTM campaign data
    #
    # @example Basic UTM report
    #   response = client.reports.utm(
    #     website_id,
    #     start_date,
    #     end_date
    #   )
    #
    #   # Analyze by source
    #   response.data['utm_source'].each do |item|
    #     puts "#{item['utm']}: #{item['views']} views"
    #   end
    #
    #   # Analyze by medium
    #   response.data['utm_medium'].each do |item|
    #     puts "#{item['utm']}: #{item['views']} views"
    #   end
    #
    #   # Analyze by campaign
    #   response.data['utm_campaign'].each do |item|
    #     puts "#{item['utm']}: #{item['views']} views"
    #   end
    #
    # @example Campaign performance analysis
    #   response = client.reports.utm(website_id, start_date, end_date)
    #
    #   # Find top traffic sources
    #   top_sources = response.data['utm_source']
    #     .sort_by { |s| -s['views'] }
    #     .take(5)
    #
    #   puts "Top 5 Traffic Sources:"
    #   top_sources.each do |source|
    #     puts "  #{source['utm']}: #{source['views']} views"
    #   end
    #
    # @example Filtered UTM report
    #   response = client.reports.utm(
    #     website_id,
    #     start_date,
    #     end_date,
    #     filters: [
    #       { type: 'device', value: 'mobile' }
    #     ]
    #   )
    #
    def utm(website_id, start_date, end_date, filters: nil)
      raise ValidationError, "website_id is required" if website_id.nil? || website_id.empty?
      raise ValidationError, "start_date is required" if start_date.nil?
      raise ValidationError, "end_date is required" if end_date.nil?

      body = {
        websiteId: website_id,
        type: "utm",
        parameters: {
          startDate: format_date(start_date),
          endDate: format_date(end_date)
        }
      }
      body[:filters] = filters if filters

      connection.post("/api/reports/utm", body)
    end

    private

    # Formats a date for API consumption
    #
    # @param date [Time, String] date to format
    # @return [String] ISO 8601 formatted date string
    def format_date(date)
      return date if date.is_a?(String)
      return date.utc.iso8601(3) if date.respond_to?(:utc)

      raise ValidationError, "Invalid date format: #{date.inspect}"
    end
  end
end
