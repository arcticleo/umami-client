# frozen_string_literal: true

module UmamiClient
  # Handles website management operations
  #
  # The Websites class provides methods for listing and managing websites
  # in your Umami instance. These operations require authentication.
  class Websites
    attr_reader :connection

    # Creates a new Websites instance
    #
    # @param connection [Connection] the HTTP connection instance
    def initialize(connection:)
      @connection = connection
    end

    # Lists all websites accessible to the authenticated user
    #
    # @param page [Integer] page number for pagination (default: 1)
    # @param page_size [Integer] number of results per page (default: 100)
    #
    # @return [Models::Response] response containing array of websites
    #
    # @raise [AuthenticationError] if not authenticated
    # @raise [APIError] if the API request fails
    #
    # @example List all websites
    #   websites = client.websites.list
    #   websites.body["data"].each do |website|
    #     puts "#{website['name']}: #{website['id']}"
    #   end
    def list(page: 1, page_size: 100)
      connection.get("/api/websites", { page: page, pageSize: page_size })
    end

    # Gets details for a specific website
    #
    # @param website_id [String] the website ID
    #
    # @return [Models::Response] response containing website details
    #
    # @raise [NotFoundError] if website not found
    # @raise [AuthenticationError] if not authenticated
    # @raise [APIError] if the API request fails
    #
    # @example Get website details
    #   website = client.websites.get("abc-123")
    #   puts website.body["name"]
    def get(website_id)
      connection.get("/api/websites/#{website_id}")
    end

    # Alias for list method (matches umami-python API)
    alias all list
  end
end
