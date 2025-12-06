# frozen_string_literal: true

module UmamiClient
  # Pixels API client for managing Umami tracking pixels
  #
  # Pixels allow you to track page views via embedded images, useful for
  # email campaigns and external sites. Available in Umami v3.0+.
  class Pixels
    # @return [Connection] the HTTP connection
    attr_reader :connection

    # Initialize a new Pixels client
    #
    # @param connection [Connection] HTTP connection instance
    def initialize(connection)
      @connection = connection
    end

    # List all pixels for the authenticated user
    #
    # Returns all tracking pixels with optional filtering and pagination support.
    #
    # @param search [String, nil] optional search keyword to filter pixels
    # @param page [Integer, nil] page number for pagination (default: 1)
    # @param page_size [Integer, nil] number of results per page
    #
    # @return [Response] response containing array of pixels in data field
    #
    # @example List all pixels
    #   response = client.pixels.list
    #   response.data['data'].each do |pixel|
    #     puts "#{pixel['name']}: #{pixel['slug']}"
    #   end
    #
    # @example Search for pixels
    #   response = client.pixels.list(search: "newsletter")
    #
    # @example Paginate results
    #   response = client.pixels.list(page: 2, page_size: 20)
    #
    def list(search: nil, page: nil, page_size: nil)
      params = {}
      params[:search] = search if search
      params[:page] = page if page
      params[:pageSize] = page_size if page_size

      connection.get("/api/pixels", params)
    end

    # Get a specific pixel by ID
    #
    # Returns detailed information about a tracking pixel including its metadata.
    #
    # @param pixel_id [String] the pixel's UUID
    #
    # @return [Response] response containing pixel details
    #
    # @example Get pixel details
    #   response = client.pixels.get(pixel_id)
    #   pixel = response.data
    #   puts "Name: #{pixel['name']}"
    #   puts "Slug: #{pixel['slug']}"
    #   puts "Pixel URL: https://your-domain.com/p/#{pixel['slug']}"
    #
    def get(pixel_id)
      raise ValidationError, "pixel_id is required" if pixel_id.nil? || pixel_id.empty?

      connection.get("/api/pixels/#{pixel_id}")
    end

    # Create a new tracking pixel
    #
    # Creates a tracking pixel with a unique slug for embedding.
    #
    # @param name [String] the display name for the pixel
    # @param slug [String] the URL slug (min 8 characters, must be unique)
    #
    # @return [Response] response containing the created pixel details
    #
    # @example Create a pixel
    #   response = client.pixels.create(
    #     "Newsletter Pixel",
    #     "newsletter2024"
    #   )
    #   pixel = response.data
    #   puts "Pixel URL: https://your-domain.com/p/#{pixel['slug']}"
    #   puts "Embed: <img src='https://your-domain.com/p/#{pixel['slug']}' />"
    #
    def create(name, slug)
      raise ValidationError, "name is required" if name.nil? || name.empty?
      raise ValidationError, "slug is required" if slug.nil? || slug.empty?
      raise ValidationError, "slug must be at least 8 characters" if slug.length < 8

      body = {
        name: name,
        slug: slug
      }

      connection.post("/api/pixels", body)
    end

    # Update an existing pixel
    #
    # Updates a pixel's name or slug. At least one parameter must be provided.
    #
    # @param pixel_id [String] the pixel's UUID
    # @param name [String, nil] new display name (optional)
    # @param slug [String, nil] new URL slug (min 8 characters, optional)
    #
    # @return [Response] response containing the updated pixel details
    #
    # @example Update pixel name
    #   response = client.pixels.update(pixel_id, name: "Updated Pixel Name")
    #
    # @example Update pixel slug
    #   response = client.pixels.update(pixel_id, slug: "newslug1")
    #
    # @example Update both fields
    #   response = client.pixels.update(
    #     pixel_id,
    #     name: "New Name",
    #     slug: "newslug2"
    #   )
    #
    def update(pixel_id, name: nil, slug: nil)
      raise ValidationError, "pixel_id is required" if pixel_id.nil? || pixel_id.empty?

      if name.nil? && slug.nil?
        raise ValidationError, "at least one of name or slug must be provided"
      end

      if slug && slug.length < 8
        raise ValidationError, "slug must be at least 8 characters"
      end

      body = {}
      body[:name] = name if name
      body[:slug] = slug if slug

      connection.post("/api/pixels/#{pixel_id}", body)
    end

    # Delete a pixel
    #
    # Permanently removes a tracking pixel. This action cannot be undone.
    #
    # @param pixel_id [String] the pixel's UUID
    #
    # @return [Response] response with confirmation status
    #
    # @example Delete a pixel
    #   response = client.pixels.delete(pixel_id)
    #   if response.success?
    #     puts "Pixel deleted successfully"
    #   end
    #
    def delete(pixel_id)
      raise ValidationError, "pixel_id is required" if pixel_id.nil? || pixel_id.empty?

      connection.delete("/api/pixels/#{pixel_id}")
    end
  end
end
