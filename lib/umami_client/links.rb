# frozen_string_literal: true

module UmamiClient
  # Links API client for managing Umami short links
  #
  # Links allow you to create shortened URLs that track clicks and analytics.
  # Available in Umami v3.0+.
  class Links
    # @return [Connection] the HTTP connection
    attr_reader :connection

    # Initialize a new Links client
    #
    # @param connection [Connection] HTTP connection instance
    def initialize(connection)
      @connection = connection
    end

    # List all links for the authenticated user
    #
    # Returns all links with optional filtering and pagination support.
    #
    # @param search [String, nil] optional search keyword to filter links
    # @param page [Integer, nil] page number for pagination (default: 1)
    # @param page_size [Integer, nil] number of results per page
    #
    # @return [Response] response containing array of links in data field
    #
    # @example List all links
    #   response = client.links.list
    #   response.data['data'].each do |link|
    #     puts "#{link['name']}: #{link['url']}"
    #   end
    #
    # @example Search for links
    #   response = client.links.list(search: "blog")
    #
    # @example Paginate results
    #   response = client.links.list(page: 2, page_size: 20)
    #
    def list(search: nil, page: nil, page_size: nil)
      params = {}
      params[:search] = search if search
      params[:page] = page if page
      params[:pageSize] = page_size if page_size

      connection.get("/api/links", params)
    end

    # Get a specific link by ID
    #
    # Returns detailed information about a link including its metadata.
    #
    # @param link_id [String] the link's UUID
    #
    # @return [Response] response containing link details
    #
    # @example Get link details
    #   response = client.links.get(link_id)
    #   link = response.data
    #   puts "Name: #{link['name']}"
    #   puts "URL: #{link['url']}"
    #   puts "Slug: #{link['slug']}"
    #
    def get(link_id)
      raise ValidationError, "link_id is required" if link_id.nil? || link_id.empty?

      connection.get("/api/links/#{link_id}")
    end

    # Create a new short link
    #
    # Creates a shortened URL with a custom slug for tracking.
    #
    # @param name [String] the display name for the link
    # @param url [String] the destination URL
    # @param slug [String] the URL slug (min 8 characters, must be unique)
    #
    # @return [Response] response containing the created link details
    #
    # @example Create a link
    #   response = client.links.create(
    #     "Blog Post",
    #     "https://example.com/blog/my-post",
    #     "blogpost"
    #   )
    #   link = response.data
    #   puts "Short URL: https://your-domain.com/l/#{link['slug']}"
    #
    def create(name, url, slug)
      raise ValidationError, "name is required" if name.nil? || name.empty?
      raise ValidationError, "url is required" if url.nil? || url.empty?
      raise ValidationError, "slug is required" if slug.nil? || slug.empty?
      raise ValidationError, "slug must be at least 8 characters" if slug.length < 8

      body = {
        name: name,
        url: url,
        slug: slug
      }

      connection.post("/api/links", body)
    end

    # Update an existing link
    #
    # Updates a link's name, URL, or slug. At least one parameter must be provided.
    #
    # @param link_id [String] the link's UUID
    # @param name [String, nil] new display name (optional)
    # @param url [String, nil] new destination URL (optional)
    # @param slug [String, nil] new URL slug (min 8 characters, optional)
    #
    # @return [Response] response containing the updated link details
    #
    # @example Update link name
    #   response = client.links.update(link_id, name: "Updated Name")
    #
    # @example Update link URL
    #   response = client.links.update(link_id, url: "https://new-url.com")
    #
    # @example Update link slug
    #   response = client.links.update(link_id, slug: "newslug1")
    #
    # @example Update multiple fields
    #   response = client.links.update(
    #     link_id,
    #     name: "New Name",
    #     url: "https://new-url.com",
    #     slug: "newslug2"
    #   )
    #
    def update(link_id, name: nil, url: nil, slug: nil)
      raise ValidationError, "link_id is required" if link_id.nil? || link_id.empty?

      if name.nil? && url.nil? && slug.nil?
        raise ValidationError, "at least one of name, url, or slug must be provided"
      end

      if slug && slug.length < 8
        raise ValidationError, "slug must be at least 8 characters"
      end

      body = {}
      body[:name] = name if name
      body[:url] = url if url
      body[:slug] = slug if slug

      connection.post("/api/links/#{link_id}", body)
    end

    # Delete a link
    #
    # Permanently removes a link. This action cannot be undone.
    #
    # @param link_id [String] the link's UUID
    #
    # @return [Response] response with confirmation status
    #
    # @example Delete a link
    #   response = client.links.delete(link_id)
    #   if response.success?
    #     puts "Link deleted successfully"
    #   end
    #
    def delete(link_id)
      raise ValidationError, "link_id is required" if link_id.nil? || link_id.empty?

      connection.delete("/api/links/#{link_id}")
    end
  end
end
