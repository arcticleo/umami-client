# frozen_string_literal: true

module UmamiClient
  # Teams API client for managing Umami teams
  #
  # Teams allow multiple users to collaborate on websites and share access.
  # Team members can have different roles (owner, manager, member) with varying permissions.
  class Teams
    # @return [Connection] the HTTP connection
    attr_reader :connection

    # Initialize a new Teams client
    #
    # @param connection [Connection] HTTP connection instance
    def initialize(connection)
      @connection = connection
    end

    # List all teams for the authenticated user
    #
    # Returns all teams the authenticated user belongs to, with pagination support.
    #
    # Note: Due to a known issue with the /api/teams endpoint returning 405,
    # this method uses /api/users/:userId/teams as a workaround.
    #
    # @param page [Integer, nil] page number for pagination (default: 1)
    # @param page_size [Integer, nil] number of results per page (default: 20)
    #
    # @return [Response] response containing array of teams in data field
    #
    # @example List all teams
    #   response = client.teams.list
    #   response.data['data'].each do |team|
    #     puts "#{team['name']} (Access Code: #{team['accessCode']})"
    #   end
    #
    # @example Paginate results
    #   response = client.teams.list(page: 2, page_size: 50)
    #
    def list(page: nil, page_size: nil)
      params = {}
      params[:page] = page if page
      params[:pageSize] = page_size if page_size

      # Workaround: /api/teams returns 405, use user-specific endpoint instead
      # See: https://github.com/umami-software/umami/issues/3195
      user_id = current_user_id
      connection.get("/api/users/#{user_id}/teams", params)
    end

    # Get a specific team by ID
    #
    # Returns detailed information about a team including its members.
    # Requires view permission for the team.
    #
    # @param team_id [String] the team's UUID
    #
    # @return [Response] response containing team details with members
    #
    # @example Get team details
    #   response = client.teams.get(team_id)
    #   team = response.data
    #   puts "Team: #{team['name']}"
    #   puts "Members: #{team['teamUser'].length}"
    #
    def get(team_id)
      raise ValidationError, "team_id is required" if team_id.nil? || team_id.empty?

      connection.get("/api/teams/#{team_id}")
    end

    # Create a new team
    #
    # Creates a new team for the authenticated user. The user becomes the team owner.
    # A unique access code is automatically generated for inviting members.
    #
    # @param name [String] the team name (max 50 characters)
    #
    # @return [Response] response containing the created team details with access code
    #
    # @example Create a team
    #   response = client.teams.create("Marketing Team")
    #   puts "Team created with access code: #{response.data['accessCode']}"
    #
    def create(name)
      raise ValidationError, "name is required" if name.nil? || name.empty?
      raise ValidationError, "name must be 50 characters or less" if name.length > 50

      body = { name: name }
      connection.post("/api/teams", body)
    end

    # Update a team
    #
    # Updates a team's name or regenerates its access code.
    # Requires owner or manager role. At least one parameter must be provided.
    #
    # @param team_id [String] the team's UUID
    # @param name [String, nil] new team name (max 50 characters, optional)
    # @param access_code [String, nil] new access code (max 50 characters, optional)
    #
    # @return [Response] response containing the updated team details
    #
    # @example Change team name
    #   response = client.teams.update(team_id, name: "New Team Name")
    #
    # @example Regenerate access code
    #   new_code = "team_" + SecureRandom.hex(8)
    #   response = client.teams.update(team_id, access_code: new_code)
    #
    # @example Update both
    #   response = client.teams.update(
    #     team_id,
    #     name: "Updated Team",
    #     access_code: "team_newcode123"
    #   )
    #
    def update(team_id, name: nil, access_code: nil)
      raise ValidationError, "team_id is required" if team_id.nil? || team_id.empty?

      if name.nil? && access_code.nil?
        raise ValidationError, "at least one of name or access_code must be provided"
      end

      if name && name.length > 50
        raise ValidationError, "name must be 50 characters or less"
      end

      if access_code && access_code.length > 50
        raise ValidationError, "access_code must be 50 characters or less"
      end

      body = {}
      body[:name] = name if name
      body[:accessCode] = access_code if access_code

      connection.post("/api/teams/#{team_id}", body)
    end

    # Delete a team
    #
    # Permanently removes a team. This action cannot be undone.
    # Requires owner or manager role.
    #
    # @param team_id [String] the team's UUID
    #
    # @return [Response] response with confirmation status
    #
    # @example Delete a team
    #   response = client.teams.delete(team_id)
    #   if response.success?
    #     puts "Team deleted successfully"
    #   end
    #
    def delete(team_id)
      raise ValidationError, "team_id is required" if team_id.nil? || team_id.empty?

      connection.delete("/api/teams/#{team_id}")
    end

    # Join a team using an access code
    #
    # Allows the authenticated user to join a team by providing its access code.
    # The user will be added as a team member.
    #
    # @param access_code [String] the team's access code (max 50 characters)
    #
    # @return [Response] response containing the team user record
    #
    # @example Join a team
    #   response = client.teams.join("team_abc123def456")
    #   puts "Joined team successfully"
    #
    def join(access_code)
      raise ValidationError, "access_code is required" if access_code.nil? || access_code.empty?
      raise ValidationError, "access_code must be 50 characters or less" if access_code.length > 50

      body = { accessCode: access_code }
      connection.post("/api/teams/join", body)
    end

    # List team members
    #
    # Returns all members of a team with their roles and details.
    # Requires team membership.
    #
    # @param team_id [String] the team's UUID
    # @param page [Integer, nil] page number (default: 1)
    # @param page_size [Integer, nil] results per page (default: 20)
    #
    # @return [Response] response containing array of team members
    #
    # @example List team members
    #   response = client.teams.list_members(team_id)
    #   response.data['data'].each do |member|
    #     puts "#{member['user']['username']} - #{member['role']}"
    #   end
    #
    def list_members(team_id, page: nil, page_size: nil)
      raise ValidationError, "team_id is required" if team_id.nil? || team_id.empty?

      params = {}
      params[:page] = page if page
      params[:pageSize] = page_size if page_size

      connection.get("/api/teams/#{team_id}/users", params)
    end

    # Add a user to a team
    #
    # Adds a user to the team with a specified role.
    # Requires owner or manager role. User must not already be a team member.
    #
    # @param team_id [String] the team's UUID
    # @param user_id [String] the user's UUID to add
    # @param role [String] the team role: "team-owner", "team-manager", "team-member", or "team-view-only"
    #
    # @return [Response] response containing the created team user record
    #
    # @example Add a member
    #   response = client.teams.add_member(team_id, user_id, "team-member")
    #
    # @example Add a manager
    #   response = client.teams.add_member(team_id, user_id, "team-manager")
    #
    def add_member(team_id, user_id, role)
      raise ValidationError, "team_id is required" if team_id.nil? || team_id.empty?
      raise ValidationError, "user_id is required" if user_id.nil? || user_id.empty?
      raise ValidationError, "role is required" if role.nil? || role.empty?

      valid_roles = ["team-owner", "team-manager", "team-member", "team-view-only"]
      unless valid_roles.include?(role)
        raise ValidationError, "role must be one of: #{valid_roles.join(', ')}"
      end

      body = {
        userId: user_id,
        role: role
      }

      connection.post("/api/teams/#{team_id}/users", body)
    end

    # Get a specific team member
    #
    # Returns details about a specific team member including their role.
    # Requires owner or manager role.
    #
    # @param team_id [String] the team's UUID
    # @param user_id [String] the team member's user UUID
    #
    # @return [Response] response containing team member details
    #
    # @example Get member details
    #   response = client.teams.get_member(team_id, user_id)
    #   puts "Role: #{response.data['role']}"
    #
    def get_member(team_id, user_id)
      raise ValidationError, "team_id is required" if team_id.nil? || team_id.empty?
      raise ValidationError, "user_id is required" if user_id.nil? || user_id.empty?

      connection.get("/api/teams/#{team_id}/users/#{user_id}")
    end

    # Update a team member's role
    #
    # Changes a team member's role.
    # Requires owner or manager role.
    #
    # @param team_id [String] the team's UUID
    # @param user_id [String] the team member's user UUID
    # @param role [String] the new role: "team-owner", "team-manager", "team-member", or "team-view-only"
    #
    # @return [Response] response containing the updated team member details
    #
    # @example Promote to manager
    #   response = client.teams.update_member(team_id, user_id, "team-manager")
    #
    # @example Demote to member
    #   response = client.teams.update_member(team_id, user_id, "team-member")
    #
    def update_member(team_id, user_id, role)
      raise ValidationError, "team_id is required" if team_id.nil? || team_id.empty?
      raise ValidationError, "user_id is required" if user_id.nil? || user_id.empty?
      raise ValidationError, "role is required" if role.nil? || role.empty?

      valid_roles = ["team-owner", "team-manager", "team-member", "team-view-only"]
      unless valid_roles.include?(role)
        raise ValidationError, "role must be one of: #{valid_roles.join(', ')}"
      end

      body = { role: role }
      connection.post("/api/teams/#{team_id}/users/#{user_id}", body)
    end

    # Remove a user from a team
    #
    # Removes a user from the team. This action cannot be undone.
    # Requires appropriate permissions to remove the specific member.
    #
    # @param team_id [String] the team's UUID
    # @param user_id [String] the team member's user UUID to remove
    #
    # @return [Response] response with confirmation status
    #
    # @example Remove a team member
    #   response = client.teams.remove_member(team_id, user_id)
    #   if response.success?
    #     puts "Member removed successfully"
    #   end
    #
    def remove_member(team_id, user_id)
      raise ValidationError, "team_id is required" if team_id.nil? || team_id.empty?
      raise ValidationError, "user_id is required" if user_id.nil? || user_id.empty?

      connection.delete("/api/teams/#{team_id}/users/#{user_id}")
    end

    private

    # Get the current authenticated user's ID
    #
    # Caches the user ID to avoid repeated API calls.
    #
    # @return [String] the current user's UUID
    #
    def current_user_id
      @current_user_id ||= begin
        response = connection.get("/api/me")
        response.data["user"]["id"]
      end
    end
  end
end
