# frozen_string_literal: true

module UmamiClient
  # Users API client for managing Umami users (admin only)
  #
  # These endpoints are only available on self-hosted Umami instances
  # for users with admin privileges. Not available on Umami Cloud.
  class Users
    # @return [Connection] the HTTP connection
    attr_reader :connection

    # Initialize a new Users client
    #
    # @param connection [Connection] HTTP connection instance
    def initialize(connection)
      @connection = connection
    end

    # List all users (admin only)
    #
    # Returns all users with pagination and optional search filtering.
    # Only available on self-hosted instances for admin users.
    #
    # @param search [String, nil] optional search keyword to filter users
    # @param page [Integer, nil] page number for pagination (default: 1)
    # @param page_size [Integer, nil] number of results per page (default: 20)
    #
    # @return [Response] response containing array of users in data field
    #
    # @example List all users
    #   response = client.users.list
    #   response.data['data'].each do |user|
    #     puts "#{user['username']} (#{user['role']})"
    #   end
    #
    # @example Search for users
    #   response = client.users.list(search: "admin")
    #
    # @example Paginate results
    #   response = client.users.list(page: 2, page_size: 50)
    #
    def list(search: nil, page: nil, page_size: nil)
      params = {}
      params[:search] = search if search
      params[:page] = page if page
      params[:pageSize] = page_size if page_size

      connection.get("/api/admin/users", params)
    end

    # Get current user information
    #
    # Returns information about the currently authenticated user based on
    # the auth token, including user details and authentication keys.
    #
    # @return [Response] response containing user object and auth information
    #
    # @example Get current user
    #   response = client.users.me
    #   user = response.data['user']
    #   puts "Logged in as: #{user['username']}"
    #   puts "Role: #{user['role']}"
    #   puts "Admin: #{user['isAdmin']}"
    #
    def me
      connection.get("/api/me")
    end

    # Get a specific user by ID
    #
    # Returns detailed information about a user including their ID, username,
    # role, and creation timestamp.
    #
    # @param user_id [String] the user's UUID
    #
    # @return [Response] response containing user details
    #
    # @example Get user details
    #   response = client.users.get(user_id)
    #   puts "Username: #{response.data['username']}"
    #   puts "Role: #{response.data['role']}"
    #   puts "Created: #{response.data['createdAt']}"
    #
    def get(user_id)
      raise ValidationError, "user_id is required" if user_id.nil? || user_id.empty?

      connection.get("/api/users/#{user_id}")
    end

    # Create a new user (admin only)
    #
    # Creates a new user account with specified credentials and role.
    # Only available on self-hosted instances for admin users.
    #
    # @param username [String] the username for the new user
    # @param password [String] the password for the new user
    # @param role [String] the user's role: "admin", "user", or "view-only"
    # @param id [String, nil] optional custom UUID for the user
    #
    # @return [Response] response containing the created user details
    #
    # @example Create an admin user
    #   response = client.users.create(
    #     "john_admin",
    #     "secure_password",
    #     "admin"
    #   )
    #
    # @example Create a regular user
    #   response = client.users.create(
    #     "jane_user",
    #     "password123",
    #     "user"
    #   )
    #
    # @example Create a view-only user
    #   response = client.users.create(
    #     "viewer",
    #     "view_pass",
    #     "view-only"
    #   )
    #
    def create(username, password, role, id: nil)
      raise ValidationError, "username is required" if username.nil? || username.empty?
      raise ValidationError, "password is required" if password.nil? || password.empty?
      raise ValidationError, "role is required" if role.nil? || role.empty?

      valid_roles = ["admin", "user", "view-only"]
      unless valid_roles.include?(role)
        raise ValidationError, "role must be one of: #{valid_roles.join(', ')}"
      end

      body = {
        username: username,
        password: password,
        role: role
      }
      body[:id] = id if id

      connection.post("/api/users", body)
    end

    # Update a user (admin only)
    #
    # Updates a user's username, password, or role. All parameters are optional,
    # but at least one must be provided.
    #
    # @param user_id [String] the user's UUID
    # @param username [String, nil] new username (optional)
    # @param password [String, nil] new password (optional)
    # @param role [String, nil] new role: "admin", "user", or "view-only" (optional)
    #
    # @return [Response] response containing the updated user details
    #
    # @example Change username
    #   response = client.users.update(user_id, username: "new_username")
    #
    # @example Change password
    #   response = client.users.update(user_id, password: "new_password")
    #
    # @example Change role
    #   response = client.users.update(user_id, role: "admin")
    #
    # @example Update multiple fields
    #   response = client.users.update(
    #     user_id,
    #     username: "updated_user",
    #     role: "user"
    #   )
    #
    def update(user_id, username: nil, password: nil, role: nil)
      raise ValidationError, "user_id is required" if user_id.nil? || user_id.empty?

      if username.nil? && password.nil? && role.nil?
        raise ValidationError, "at least one of username, password, or role must be provided"
      end

      if role && !["admin", "user", "view-only"].include?(role)
        raise ValidationError, "role must be one of: admin, user, view-only"
      end

      body = {}
      body[:username] = username if username
      body[:password] = password if password
      body[:role] = role if role

      connection.post("/api/users/#{user_id}", body)
    end

    # Delete a user (admin only)
    #
    # Permanently removes a user account. This action cannot be undone.
    #
    # @param user_id [String] the user's UUID
    #
    # @return [Response] response with confirmation status
    #
    # @example Delete a user
    #   response = client.users.delete(user_id)
    #   if response.success?
    #     puts "User deleted successfully"
    #   end
    #
    def delete(user_id)
      raise ValidationError, "user_id is required" if user_id.nil? || user_id.empty?

      connection.delete("/api/users/#{user_id}")
    end

    # Get a user's websites
    #
    # Returns all websites owned by a specific user with pagination and search support.
    # Can optionally include team-owned websites.
    #
    # @param user_id [String] the user's UUID
    # @param search [String, nil] optional search keyword
    # @param page [Integer, nil] page number (default: 1)
    # @param page_size [Integer, nil] results per page (default: 20)
    # @param include_teams [Boolean, nil] include team-owned websites
    #
    # @return [Response] response containing array of websites
    #
    # @example Get user's websites
    #   response = client.users.websites(user_id)
    #   response.data['data'].each do |website|
    #     puts "#{website['name']}: #{website['domain']}"
    #   end
    #
    # @example Include team websites
    #   response = client.users.websites(user_id, include_teams: true)
    #
    def websites(user_id, search: nil, page: nil, page_size: nil, include_teams: nil)
      raise ValidationError, "user_id is required" if user_id.nil? || user_id.empty?

      params = {}
      params[:search] = search if search
      params[:page] = page if page
      params[:pageSize] = page_size if page_size
      params[:includeTeams] = include_teams if include_teams

      connection.get("/api/users/#{user_id}/websites", params)
    end

    # Get a user's teams
    #
    # Returns all teams the user is a member of, with member details and
    # website counts for each team.
    #
    # @param user_id [String] the user's UUID
    # @param page [Integer, nil] page number (default: 1)
    # @param page_size [Integer, nil] results per page (default: 20)
    #
    # @return [Response] response containing array of teams
    #
    # @example Get user's teams
    #   response = client.users.teams(user_id)
    #   response.data['data'].each do |team|
    #     puts "Team: #{team['name']}"
    #     puts "  Members: #{team['teamUser'].length}"
    #   end
    #
    def teams(user_id, page: nil, page_size: nil)
      raise ValidationError, "user_id is required" if user_id.nil? || user_id.empty?

      params = {}
      params[:page] = page if page
      params[:pageSize] = page_size if page_size

      connection.get("/api/users/#{user_id}/teams", params)
    end
  end
end
