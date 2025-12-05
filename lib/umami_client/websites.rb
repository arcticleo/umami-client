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
    # @return [Response] response containing array of websites
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
    # @return [Response] response containing website details
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

    # Creates a new website
    #
    # @param name [String] the website name
    # @param domain [String] the website domain
    # @param share_id [String, nil] optional share ID for public access
    # @param team_id [String, nil] optional team ID to assign website to
    #
    # @return [Response] response containing the created website
    #
    # @raise [ValidationError] if required parameters are missing
    # @raise [AuthenticationError] if not authenticated
    # @raise [APIError] if the API request fails
    #
    # @example Create a new website
    #   website = client.websites.create("My Site", "example.com")
    #   puts website.body["id"]
    def create(name, domain, share_id: nil, team_id: nil)
      raise ValidationError, "name is required" if name.nil? || name.empty?
      raise ValidationError, "domain is required" if domain.nil? || domain.empty?

      payload = {
        name: name,
        domain: domain
      }
      payload[:shareId] = share_id if share_id
      payload[:teamId] = team_id if team_id

      connection.post("/api/websites", payload)
    end

    # Updates an existing website
    #
    # **Important:** The Umami API requires both name and domain when updating.
    # If you only provide one, this method will fetch the current website data
    # to get the missing field.
    #
    # @param website_id [String] the website ID
    # @param name [String, nil] new website name (optional, fetched if not provided)
    # @param domain [String, nil] new website domain (optional, fetched if not provided)
    # @param share_id [String, nil] new share ID, or null to unshare (optional)
    #
    # @return [Response] response containing the updated website
    #
    # @raise [ValidationError] if website_id is missing
    # @raise [NotFoundError] if website not found
    # @raise [AuthenticationError] if not authenticated
    # @raise [APIError] if the API request fails
    #
    # @example Update website name (domain fetched automatically)
    #   website = client.websites.update("abc-123", name: "New Name")
    #
    # @example Update both name and domain
    #   website = client.websites.update("abc-123", name: "New Name", domain: "newdomain.com")
    #
    # @example Unshare a website
    #   website = client.websites.update("abc-123", share_id: nil)
    def update(website_id, name: nil, domain: nil, share_id: :not_provided)
      raise ValidationError, "website_id is required" if website_id.nil? || website_id.empty?

      # Umami API requires both name and domain
      # Fetch current website if either is missing
      if name.nil? || domain.nil?
        current = get(website_id)
        name ||= current.body["name"]
        domain ||= current.body["domain"]
      end

      payload = {
        name: name,
        domain: domain
      }
      payload[:shareId] = share_id unless share_id == :not_provided

      connection.post("/api/websites/#{website_id}", payload)
    end

    # Deletes a website
    #
    # @param website_id [String] the website ID
    #
    # @return [Response] response with {"ok": true} on success
    #
    # @raise [ValidationError] if website_id is missing
    # @raise [NotFoundError] if website not found
    # @raise [AuthenticationError] if not authenticated
    # @raise [APIError] if the API request fails
    #
    # @example Delete a website
    #   response = client.websites.delete("abc-123")
    #   puts "Deleted!" if response.body["ok"]
    def delete(website_id)
      raise ValidationError, "website_id is required" if website_id.nil? || website_id.empty?

      connection.delete("/api/websites/#{website_id}")
    end

    # Resets all analytics data for a website
    #
    # This removes all tracking data (pageviews, events, sessions) while
    # preserving the website configuration itself.
    #
    # @param website_id [String] the website ID
    #
    # @return [Response] response confirming reset
    #
    # @raise [ValidationError] if website_id is missing
    # @raise [NotFoundError] if website not found
    # @raise [AuthenticationError] if not authenticated
    # @raise [APIError] if the API request fails
    #
    # @example Reset website data
    #   response = client.websites.reset("abc-123")
    def reset(website_id)
      raise ValidationError, "website_id is required" if website_id.nil? || website_id.empty?

      connection.post("/api/websites/#{website_id}/reset", {})
    end

    # Alias for list method (matches umami-python API)
    alias all list
  end
end
