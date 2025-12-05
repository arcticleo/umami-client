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
  end
end
