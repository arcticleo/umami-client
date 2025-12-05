# frozen_string_literal: true

require "time"

module UmamiClient
  # User model representing an Umami user account
  #
  # Provides a structured representation of user data with
  # convenient access methods and type conversions.
  class User
    # @return [String] the user's UUID
    attr_reader :id

    # @return [String] the user's username
    attr_reader :username

    # @return [String] the user's role (admin, user, view-only)
    attr_reader :role

    # @return [Time] when the user account was created
    attr_reader :created_at

    # @return [Integer, nil] number of websites owned by this user
    attr_reader :website_count

    # Initialize a new User instance
    #
    # @param data [Hash] user data from API response
    # @option data [String] :id user's UUID
    # @option data [String] :username username
    # @option data [String] :role user role
    # @option data [String, Integer] :createdAt creation timestamp
    # @option data [Integer] :_count website count data
    #
    def initialize(data)
      @id = data["id"]
      @username = data["username"]
      @role = data["role"]
      @created_at = parse_timestamp(data["createdAt"])
      @website_count = data.dig("_count", "website")
    end

    # Check if user is an admin
    #
    # @return [Boolean] true if user has admin role
    #
    # @example Check admin status
    #   if user.admin?
    #     puts "User has admin privileges"
    #   end
    #
    def admin?
      role == "admin"
    end

    # Check if user is a regular user
    #
    # @return [Boolean] true if user has user role
    #
    def user?
      role == "user"
    end

    # Check if user is view-only
    #
    # @return [Boolean] true if user has view-only role
    #
    def view_only?
      role == "view-only"
    end

    # Convert user to hash representation
    #
    # @return [Hash] user data as hash
    #
    # @example Get user as hash
    #   user_hash = user.to_h
    #   puts user_hash[:username]
    #
    def to_h
      {
        id: id,
        username: username,
        role: role,
        created_at: created_at,
        website_count: website_count
      }
    end

    # String representation of user
    #
    # @return [String] user summary
    #
    def to_s
      "#<UmamiClient::User id=#{id} username=#{username} role=#{role}>"
    end

    # Detailed inspection
    #
    # @return [String] detailed user information
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
