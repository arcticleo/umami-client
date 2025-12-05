# frozen_string_literal: true

module UmamiClient
  # Represents a website in Umami Analytics
  #
  # Provides a clean object interface for website data with attribute accessors
  # for all website properties.
  class Website
    attr_reader :id, :name, :domain, :share_id, :created_at, :updated_at,
                :user_id, :team_id, :team

    # Creates a new Website instance from API response data
    #
    # @param attributes [Hash] website attributes from API
    # @option attributes [String] :id website ID (UUID)
    # @option attributes [String] :name website name
    # @option attributes [String] :domain website domain
    # @option attributes [String, nil] :shareId share ID for public access
    # @option attributes [String] :createdAt creation timestamp
    # @option attributes [String, nil] :updatedAt last update timestamp
    # @option attributes [String] :userId owner user ID
    # @option attributes [String, nil] :teamId team ID if assigned to a team
    # @option attributes [Hash, nil] :team team object if included
    #
    # @example Create from API response
    #   website = UmamiClient::Website.new(response.body)
    #   puts website.name
    #   puts website.domain
    def initialize(attributes = {})
      @id = attributes["id"]
      @name = attributes["name"]
      @domain = attributes["domain"]
      @share_id = attributes["shareId"]
      @created_at = parse_timestamp(attributes["createdAt"])
      @updated_at = parse_timestamp(attributes["updatedAt"])
      @user_id = attributes["userId"]
      @team_id = attributes["teamId"]
      @team = attributes["team"]
    end

    # Checks if the website has a share ID (is publicly accessible)
    #
    # @return [Boolean] true if the website has a share ID
    def shared?
      !share_id.nil? && !share_id.empty?
    end

    # Checks if the website is assigned to a team
    #
    # @return [Boolean] true if the website belongs to a team
    def team_website?
      !team_id.nil?
    end

    # Returns the public share URL for the website
    #
    # @param base_url [String] the base Umami URL
    # @return [String, nil] the share URL or nil if not shared
    #
    # @example Get share URL
    #   website.share_url("https://umami.example.com")
    #   # => "https://umami.example.com/share/abc123"
    def share_url(base_url)
      return nil unless shared?

      "#{base_url.sub(%r{/+$}, '')}/share/#{share_id}"
    end

    # Converts the website to a hash
    #
    # @return [Hash] hash representation of the website
    def to_h
      {
        id: id,
        name: name,
        domain: domain,
        share_id: share_id,
        created_at: created_at,
        updated_at: updated_at,
        user_id: user_id,
        team_id: team_id,
        team: team
      }.compact
    end

    # String representation of the website
    #
    # @return [String] formatted website information
    def to_s
      "#<UmamiClient::Website id=#{id} name=#{name.inspect} domain=#{domain.inspect}>"
    end

    alias inspect to_s

    private

    # Parses a timestamp string into a Time object
    #
    # @param timestamp [String, nil] ISO 8601 timestamp
    # @return [Time, nil] parsed Time object or nil
    def parse_timestamp(timestamp)
      return nil if timestamp.nil? || timestamp.empty?

      Time.parse(timestamp)
    rescue ArgumentError
      nil
    end
  end
end
