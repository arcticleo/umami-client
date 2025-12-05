# frozen_string_literal: true

require "time"

module UmamiClient
  # Team model representing an Umami team
  #
  # Provides a structured representation of team data with
  # convenient access methods and type conversions. Teams enable
  # collaboration by allowing multiple users to share website access.
  class Team
    # @return [String] the team's UUID
    attr_reader :id

    # @return [String] the team's name
    attr_reader :name

    # @return [String] the team's access code for invitations
    attr_reader :access_code

    # @return [Time] when the team was created
    attr_reader :created_at

    # @return [Time, nil] when the team was last updated
    attr_reader :updated_at

    # @return [Integer, nil] number of team members
    attr_reader :member_count

    # @return [Integer, nil] number of websites owned by this team
    attr_reader :website_count

    # @return [Array<Hash>, nil] team members with their roles
    attr_reader :members

    # Initialize a new Team instance
    #
    # @param data [Hash] team data from API response
    # @option data [String] :id team's UUID
    # @option data [String] :name team name
    # @option data [String] :accessCode access code for joining
    # @option data [String, Integer] :createdAt creation timestamp
    # @option data [String, Integer] :updatedAt update timestamp
    # @option data [Array<Hash>] :teamUser array of team member objects
    # @option data [Hash] :_count count data (website)
    #
    def initialize(data)
      @id = data["id"]
      @name = data["name"]
      @access_code = data["accessCode"]
      @created_at = parse_timestamp(data["createdAt"])
      @updated_at = parse_timestamp(data["updatedAt"])
      @members = data["teamUser"]
      @member_count = members&.length
      @website_count = data.dig("_count", "website")
    end

    # Check if team has members
    #
    # @return [Boolean] true if team has any members
    #
    # @example Check for members
    #   if team.has_members?
    #     puts "Team has #{team.member_count} members"
    #   end
    #
    def has_members?
      member_count && member_count > 0
    end

    # Check if team has websites
    #
    # @return [Boolean] true if team has any websites
    #
    def has_websites?
      website_count && website_count > 0
    end

    # Get owner member(s)
    #
    # @return [Array<Hash>] array of owner member objects
    #
    # @example Get team owners
    #   team.owners.each do |owner|
    #     puts "Owner: #{owner['user']['username']}"
    #   end
    #
    def owners
      return [] unless members

      members.select { |m| m["role"] == "team-owner" }
    end

    # Get manager member(s)
    #
    # @return [Array<Hash>] array of manager member objects
    #
    def managers
      return [] unless members

      members.select { |m| m["role"] == "team-manager" }
    end

    # Get regular member(s)
    #
    # @return [Array<Hash>] array of regular member objects
    #
    def regular_members
      return [] unless members

      members.select { |m| m["role"] == "team-member" }
    end

    # Get view-only member(s)
    #
    # @return [Array<Hash>] array of view-only member objects
    #
    def view_only_members
      return [] unless members

      members.select { |m| m["role"] == "team-view-only" }
    end

    # Convert team to hash representation
    #
    # @return [Hash] team data as hash
    #
    # @example Get team as hash
    #   team_hash = team.to_h
    #   puts team_hash[:name]
    #
    def to_h
      {
        id: id,
        name: name,
        access_code: access_code,
        created_at: created_at,
        updated_at: updated_at,
        member_count: member_count,
        website_count: website_count,
        members: members
      }
    end

    # String representation of team
    #
    # @return [String] team summary
    #
    def to_s
      "#<UmamiClient::Team id=#{id} name=#{name} members=#{member_count || 0}>"
    end

    # Detailed inspection
    #
    # @return [String] detailed team information
    #
    def inspect
      to_s
    end

    private

    # Parse timestamp from API response
    #
    # @param timestamp [String, Integer, nil] timestamp value
    # @return [Time, nil] parsed Time object or nil
    #
    def parse_timestamp(timestamp)
      return nil if timestamp.nil?

      if timestamp.is_a?(String)
        Time.parse(timestamp)
      elsif timestamp.is_a?(Integer)
        Time.at(timestamp / 1000.0)
      end
    rescue ArgumentError
      nil
    end
  end
end
