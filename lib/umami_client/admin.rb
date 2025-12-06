# frozen_string_literal: true

module UmamiClient
  # Handles admin-only endpoints for self-hosted Umami instances
  #
  # @note These endpoints are ONLY available for self-hosted Umami instances
  #   with admin user authentication. They are NOT available on Umami Cloud.
  #
  # @note Admin endpoints provide global views across all resources in the instance,
  #   unlike regular endpoints which are scoped to the current user's permissions.
  class Admin
    attr_reader :connection

    # @param connection [Connection] The connection object
    def initialize(connection)
      @connection = connection
    end

    # Lists all users across the entire Umami instance (admin-only)
    #
    # @param page [Integer, nil] Page number for pagination (default: 1)
    # @param page_size [Integer, nil] Number of results per page (default: 20)
    # @param search [String, nil] Search text to filter users
    #
    # @return [Response] Response containing array of user objects
    #
    # @raise [Error] if the API request fails
    # @raise [AuthenticationError] if not authenticated as admin
    #
    # @example List all users
    #   response = client.admin.users
    #   response.data.each do |user|
    #     puts "#{user['username']} - #{user['role']}"
    #   end
    #
    # @example Search for users
    #   response = client.admin.users(search: "john")
    #
    # @example Paginate results
    #   response = client.admin.users(page: 2, page_size: 50)
    #
    # @note Response includes: id, username, role, createdAt, websiteCount
    # @note Only available for self-hosted instances with admin authentication
    def users(page: nil, page_size: nil, search: nil)
      params = {}
      params[:page] = page if page
      params[:pageSize] = page_size if page_size
      params[:search] = search if search

      connection.get("/api/admin/users", params)
    end

    # Lists all websites across the entire Umami instance (admin-only)
    #
    # @param page [Integer, nil] Page number for pagination (default: 1)
    # @param page_size [Integer, nil] Number of results per page (default: 20)
    # @param search [String, nil] Search text to filter websites
    #
    # @return [Response] Response containing array of website objects
    #
    # @raise [Error] if the API request fails
    # @raise [AuthenticationError] if not authenticated as admin
    #
    # @example List all websites
    #   response = client.admin.websites
    #   response.data.each do |website|
    #     puts "#{website['name']} - #{website['domain']} (#{website['user']['username']})"
    #   end
    #
    # @example Search for websites
    #   response = client.admin.websites(search: "example.com")
    #
    # @example Paginate results
    #   response = client.admin.websites(page: 2, page_size: 50)
    #
    # @note Response includes: id, name, domain, userId, teamId, createdAt, user details
    # @note Only available for self-hosted instances with admin authentication
    def websites(page: nil, page_size: nil, search: nil)
      params = {}
      params[:page] = page if page
      params[:pageSize] = page_size if page_size
      params[:search] = search if search

      connection.get("/api/admin/websites", params)
    end

    # Lists all teams across the entire Umami instance (admin-only)
    #
    # @param page [Integer, nil] Page number for pagination (default: 1)
    # @param page_size [Integer, nil] Number of results per page (default: 20)
    # @param search [String, nil] Search text to filter teams
    #
    # @return [Response] Response containing array of team objects
    #
    # @raise [Error] if the API request fails
    # @raise [AuthenticationError] if not authenticated as admin
    #
    # @example List all teams
    #   response = client.admin.teams
    #   response.data.each do |team|
    #     puts "#{team['name']} - #{team['teamUser'].length} members"
    #   end
    #
    # @example Search for teams
    #   response = client.admin.teams(search: "engineering")
    #
    # @example Paginate results
    #   response = client.admin.teams(page: 2, page_size: 50)
    #
    # @note Response includes: id, name, accessCode, createdAt, teamUser (members), websiteCount
    # @note Only available for self-hosted instances with admin authentication
    def teams(page: nil, page_size: nil, search: nil)
      params = {}
      params[:page] = page if page
      params[:pageSize] = page_size if page_size
      params[:search] = search if search

      connection.get("/api/admin/teams", params)
    end
  end
end
