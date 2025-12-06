# Links and Pixels

The Links and Pixels APIs allow you to create shortened URLs and tracking pixels in Umami Analytics. These features are useful for tracking external campaigns, email marketing, and off-site analytics.

**Requirements:**
- Umami v3.0.0 or later
- Self-hosted instance or Umami Cloud

## Table of Contents

- [Overview](#overview)
- [Links API](#links-api)
  - [Creating Short Links](#creating-short-links)
  - [Listing Links](#listing-links)
  - [Getting Link Details](#getting-link-details)
  - [Updating Links](#updating-links)
  - [Deleting Links](#deleting-links)
- [Pixels API](#pixels-api)
  - [Creating Tracking Pixels](#creating-tracking-pixels)
  - [Listing Pixels](#listing-pixels)
  - [Getting Pixel Details](#getting-pixel-details)
  - [Updating Pixels](#updating-pixels)
  - [Deleting Pixels](#deleting-pixels)
- [Complete Examples](#complete-examples)
- [Best Practices](#best-practices)
- [Version Requirements](#version-requirements)

## Overview

### Links

**Links** provide URL shortening capabilities with built-in analytics tracking:
- Create shortened URLs with custom slugs
- Track link clicks and analytics
- Manage multiple short links
- Update destinations without changing short URL

**Use Cases:**
- Social media campaigns
- Email marketing links
- QR code destinations
- Affiliate tracking

### Pixels

**Pixels** are 1x1 tracking images for tracking page views:
- Embed in emails or external pages
- Track views without JavaScript
- Works in email clients
- Invisible to users

**Use Cases:**
- Email open tracking
- Newsletter analytics
- Third-party site tracking
- Cross-domain measurement

## Links API

### Creating Short Links

Create a shortened URL with a custom slug:

```ruby
require 'umami_client'

client = UmamiClient::Client.new(
  username: 'admin',
  password: 'password',
  base_url: 'https://analytics.example.com'
)

# Create a short link
response = client.links.create(
  "Blog Post Link",                      # Name
  "https://example.com/blog/my-article", # Destination URL
  "blogpost"                             # Slug (min 8 characters)
)

if response.success?
  link = response.data

  puts "Link created!"
  puts "Short URL: https://analytics.example.com/l/#{link['slug']}"
  puts "Link ID: #{link['id']}"
  puts "Created: #{link['createdAt']}"
end
```

#### Validation Rules

- **Name**: Required, descriptive label for the link
- **URL**: Required, full destination URL including protocol
- **Slug**: Required, minimum 8 characters, must be unique
  - Only alphanumeric characters and hyphens
  - Case-sensitive
  - Cannot be changed after creation (must delete and recreate)

#### Slug Examples

```ruby
# Valid slugs (8+ characters)
"blogpost"       # Simple slug
"summer2024"     # With numbers
"promo-q4"       # With hyphen
"newsletter1"    # Mixed

# Invalid slugs
"blog"           # Too short (< 8 characters)
"my slug"        # Contains space
"test@link"      # Special characters
```

### Listing Links

Get all your short links:

```ruby
# List all links
response = client.links.list

links = response.data['data']
puts "You have #{links.length} short links:"

links.each do |link|
  puts "\n#{link['name']}"
  puts "  Slug: #{link['slug']}"
  puts "  URL: #{link['url']}"
  puts "  Created: #{link['createdAt']}"
end
```

#### With Pagination

```ruby
# Get specific page
response = client.links.list(page: 2, page_size: 20)

puts "Page #{response.data['page']} of links"
puts "Total: #{response.data['count']}"
```

#### With Search

```ruby
# Search for specific links
response = client.links.list(search: "blog")

links = response.data['data']
puts "Found #{links.length} links matching 'blog'"
```

### Getting Link Details

Retrieve detailed information about a specific link:

```ruby
link_id = "your-link-id"

response = client.links.get(link_id)

if response.success?
  link = response.data

  puts "Link: #{link['name']}"
  puts "Short URL: https://your-domain.com/l/#{link['slug']}"
  puts "Destination: #{link['url']}"
  puts "Created: #{link['createdAt']}"
  puts "Updated: #{link['updatedAt']}"
  puts "User ID: #{link['userId']}"
  puts "Team ID: #{link['teamId']}" if link['teamId']
end
```

### Updating Links

Update a link's name or destination URL:

#### Update Name

```ruby
link_id = "your-link-id"

response = client.links.update(link_id, name: "New Link Name")

if response.success?
  puts "Link renamed to: #{response.data['name']}"
end
```

#### Update Destination URL

```ruby
# Change where the short link redirects
response = client.links.update(
  link_id,
  url: "https://example.com/new-destination"
)

if response.success?
  puts "Link now redirects to: #{response.data['url']}"
  puts "Short URL remains the same"
end
```

#### Update Multiple Fields

```ruby
response = client.links.update(
  link_id,
  name: "Updated Campaign Link",
  url: "https://example.com/updated-page"
)
```

**Note**: You cannot update the slug. To change the slug, delete the link and create a new one.

### Deleting Links

Permanently remove a short link:

```ruby
link_id = "your-link-id"

response = client.links.delete(link_id)

if response.success?
  puts "Link deleted successfully"
  puts "Short URL is now inactive"
else
  puts "Error: #{response.error_message}"
end
```

**⚠️ Warning**: Deletion is permanent. The short URL will stop working immediately.

## Pixels API

### Creating Tracking Pixels

Create a tracking pixel with a unique slug:

```ruby
require 'umami_client'

client = UmamiClient::Client.new(
  username: 'admin',
  password: 'password',
  base_url: 'https://analytics.example.com'
)

# Create a tracking pixel
response = client.pixels.create(
  "Newsletter Pixel",  # Name
  "newsletter2024"     # Slug (min 8 characters)
)

if response.success?
  pixel = response.data
  pixel_url = "https://analytics.example.com/p/#{pixel['slug']}"

  puts "Pixel created!"
  puts "Pixel ID: #{pixel['id']}"
  puts "Slug: #{pixel['slug']}"
  puts "\nEmbed code:"
  puts "<img src='#{pixel_url}' width='1' height='1' style='display:none' />"
end
```

#### Validation Rules

- **Name**: Required, descriptive label for the pixel
- **Slug**: Required, minimum 8 characters, must be unique
  - Same rules as Links slugs
  - Only alphanumeric characters and hyphens

### Listing Pixels

Get all your tracking pixels:

```ruby
# List all pixels
response = client.pixels.list

pixels = response.data['data']
puts "You have #{pixels.length} tracking pixels:"

pixels.each do |pixel|
  puts "\n#{pixel['name']}"
  puts "  Slug: #{pixel['slug']}"
  puts "  URL: https://your-domain.com/p/#{pixel['slug']}"
  puts "  Created: #{pixel['createdAt']}"
end
```

#### With Pagination and Search

```ruby
# Paginate results
response = client.pixels.list(page: 1, page_size: 10)

# Search for pixels
response = client.pixels.list(search: "newsletter")
```

### Getting Pixel Details

Retrieve detailed information about a specific pixel:

```ruby
pixel_id = "your-pixel-id"

response = client.pixels.get(pixel_id)

if response.success?
  pixel = response.data

  puts "Pixel: #{pixel['name']}"
  puts "Slug: #{pixel['slug']}"
  puts "Pixel URL: https://your-domain.com/p/#{pixel['slug']}"
  puts "Created: #{pixel['createdAt']}"
  puts "Updated: #{pixel['updatedAt']}"
end
```

### Updating Pixels

Update a pixel's name or slug:

#### Update Name

```ruby
pixel_id = "your-pixel-id"

response = client.pixels.update(pixel_id, name: "Updated Pixel Name")

if response.success?
  puts "Pixel renamed to: #{response.data['name']}"
end
```

#### Update Slug

```ruby
# Change the pixel URL
response = client.pixels.update(pixel_id, slug: "newsletter2025")

if response.success?
  puts "Pixel slug updated to: #{response.data['slug']}"
  puts "New URL: https://your-domain.com/p/#{response.data['slug']}"
  puts "⚠️  Update all embed codes with new URL!"
end
```

#### Update Both

```ruby
response = client.pixels.update(
  pixel_id,
  name: "Q1 Newsletter Pixel",
  slug: "q1newsletter"
)
```

### Deleting Pixels

Permanently remove a tracking pixel:

```ruby
pixel_id = "your-pixel-id"

response = client.pixels.delete(pixel_id)

if response.success?
  puts "Pixel deleted successfully"
  puts "Tracking will stop for this pixel"
end
```

**⚠️ Warning**: Deletion is permanent. The pixel URL will stop tracking immediately.

## Complete Examples

### Example 1: Campaign Link Management

```ruby
require 'umami_client'

class CampaignManager
  def initialize(client)
    @client = client
  end

  def create_campaign_links(campaign_name, links)
    results = []

    links.each do |link_data|
      slug = "#{campaign_name}-#{link_data[:slug]}"

      response = @client.links.create(
        link_data[:name],
        link_data[:url],
        slug
      )

      if response.success?
        link = response.data
        short_url = "https://analytics.example.com/l/#{link['slug']}"

        results << {
          name: link['name'],
          short_url: short_url,
          destination: link['url'],
          link_id: link['id']
        }

        puts "✓ Created: #{link['name']}"
        puts "  Short URL: #{short_url}"
      else
        puts "✗ Failed: #{link_data[:name]} - #{response.error_message}"
      end
    end

    results
  end

  def update_campaign_destination(link_ids, new_base_url)
    link_ids.each do |link_id|
      response = @client.links.get(link_id)
      next unless response.success?

      link = response.data
      old_url = link['url']

      # Extract path from old URL
      path = URI.parse(old_url).path

      # Build new URL
      new_url = "#{new_base_url}#{path}"

      # Update link
      update_response = @client.links.update(link_id, url: new_url)

      if update_response.success?
        puts "✓ Updated #{link['name']}"
        puts "  From: #{old_url}"
        puts "  To: #{new_url}"
      end
    end
  end
end

# Usage
client = UmamiClient::Client.new(
  username: 'admin',
  password: 'password',
  base_url: 'https://analytics.example.com'
)

manager = CampaignManager.new(client)

# Create campaign links
campaign_links = manager.create_campaign_links('summer2024', [
  { name: 'Summer Sale Homepage', url: 'https://shop.example.com/', slug: 'homepage' },
  { name: 'Summer Sale Products', url: 'https://shop.example.com/products', slug: 'products' },
  { name: 'Summer Sale About', url: 'https://shop.example.com/about', slug: 'aboutus1' }
])

puts "\nCampaign Links:"
campaign_links.each do |link|
  puts "#{link[:name]}: #{link[:short_url]}"
end
```

### Example 2: Email Newsletter Tracking

```ruby
require 'umami_client'

class NewsletterTracker
  def initialize(client, base_url)
    @client = client
    @base_url = base_url
  end

  def create_newsletter_tracking(newsletter_name, editions)
    pixels = []

    editions.each do |edition|
      slug = "nl-#{newsletter_name}-#{edition[:date].gsub('-', '')}"

      response = @client.pixels.create(
        "#{newsletter_name} - #{edition[:name]}",
        slug
      )

      if response.success?
        pixel = response.data
        pixel_url = "#{@base_url}/p/#{pixel['slug']}"

        pixels << {
          edition: edition[:name],
          pixel_id: pixel['id'],
          pixel_url: pixel_url,
          embed_code: "<img src='#{pixel_url}' width='1' height='1' style='display:none' alt='' />"
        }

        puts "✓ Created tracking pixel for: #{edition[:name]}"
      end
    end

    pixels
  end

  def generate_email_html(pixel_url, content)
    <<~HTML
      <!DOCTYPE html>
      <html>
      <head>
        <title>Newsletter</title>
      </head>
      <body>
        #{content}

        <!-- Umami tracking pixel -->
        <img src="#{pixel_url}" width="1" height="1" style="display:none" alt="" />
      </body>
      </html>
    HTML
  end

  def get_newsletter_stats
    response = @client.pixels.list

    if response.success?
      pixels = response.data['data']

      newsletter_pixels = pixels.select do |p|
        p['name'].start_with?('Newsletter')
      end

      puts "Newsletter Tracking Pixels: #{newsletter_pixels.length}"

      newsletter_pixels.each do |pixel|
        puts "\n#{pixel['name']}"
        puts "  Slug: #{pixel['slug']}"
        puts "  Created: #{pixel['createdAt']}"
        # Note: View counts require separate analytics queries
      end
    end
  end
end

# Usage
client = UmamiClient::Client.new(
  username: 'admin',
  password: 'password',
  base_url: 'https://analytics.example.com'
)

tracker = NewsletterTracker.new(client, 'https://analytics.example.com')

# Create tracking pixels for newsletter editions
editions = [
  { name: 'January 2024', date: '2024-01' },
  { name: 'February 2024', date: '2024-02' },
  { name: 'March 2024', date: '2024-03' }
]

pixels = tracker.create_newsletter_tracking('TechNews', editions)

# Generate email HTML with tracking
pixels.each do |pixel|
  email_html = tracker.generate_email_html(
    pixel[:pixel_url],
    "<h1>#{pixel[:edition]} Newsletter</h1><p>Your content here...</p>"
  )

  puts "\nEmail HTML for #{pixel[:edition]}:"
  puts email_html[0..200] + "..."
end

# Get newsletter statistics
tracker.get_newsletter_stats
```

### Example 3: Social Media Campaign Tracker

```ruby
require 'umami_client'
require 'csv'

class SocialCampaignTracker
  def initialize(client, base_url)
    @client = client
    @base_url = base_url
  end

  def create_social_links(campaign, platforms)
    links = []

    platforms.each do |platform, url_data|
      slug = "#{campaign}-#{platform}".downcase.gsub('_', '')

      response = @client.links.create(
        "#{campaign} - #{platform}",
        url_data[:url],
        slug
      )

      if response.success?
        link = response.data
        short_url = "#{@base_url}/l/#{link['slug']}"

        links << {
          platform: platform,
          campaign: campaign,
          short_url: short_url,
          link_id: link['id']
        }

        puts "✓ #{platform}: #{short_url}"
      end
    end

    links
  end

  def export_links_csv(filename)
    response = @client.links.list

    return unless response.success?

    CSV.open(filename, 'w') do |csv|
      csv << ['Name', 'Short URL', 'Destination', 'Created']

      response.data['data'].each do |link|
        csv << [
          link['name'],
          "#{@base_url}/l/#{link['slug']}",
          link['url'],
          link['createdAt']
        ]
      end
    end

    puts "Exported links to #{filename}"
  end

  def bulk_update_destination(campaign, new_url)
    response = @client.links.list(search: campaign)

    return unless response.success?

    links = response.data['data']

    links.each do |link|
      update_response = @client.links.update(link['id'], url: new_url)

      if update_response.success?
        puts "✓ Updated: #{link['name']}"
      else
        puts "✗ Failed: #{link['name']}"
      end
    end
  end
end

# Usage
client = UmamiClient::Client.new(
  username: 'admin',
  password: 'password',
  base_url: 'https://analytics.example.com'
)

tracker = SocialCampaignTracker.new(client, 'https://analytics.example.com')

# Create links for social campaign
platforms = {
  'Twitter' => { url: 'https://example.com/campaign?utm_source=twitter' },
  'Facebook' => { url: 'https://example.com/campaign?utm_source=facebook' },
  'LinkedIn' => { url: 'https://example.com/campaign?utm_source=linkedin' },
  'Instagram' => { url: 'https://example.com/campaign?utm_source=instagram' }
}

links = tracker.create_social_links('SpringSale', platforms)

# Export to CSV for sharing with team
tracker.export_links_csv('spring_sale_links.csv')

# Later: Update all campaign links to new destination
tracker.bulk_update_destination('SpringSale', 'https://example.com/new-landing-page')
```

## Best Practices

### Link Management

#### 1. Use Descriptive Names

```ruby
# Good
client.links.create(
  "Q4 2024 Holiday Sale - Homepage",
  "https://shop.example.com/holiday-sale",
  "q4holiday24"
)

# Bad
client.links.create(
  "Link 1",
  "https://shop.example.com/holiday-sale",
  "link0001"
)
```

#### 2. Consistent Slug Naming

```ruby
# Use a consistent pattern
campaign_slug = "#{campaign_name}-#{platform}-#{date}".downcase

# Examples:
# "springsale-twitter-2024"
# "webinar-linkedin-0315"
# "newsletter-email-jan24"
```

#### 3. Track Campaign Attribution

```ruby
# Include UTM parameters in destination URLs
def create_tracked_link(name, base_url, slug, utm_params)
  url_with_utm = "#{base_url}?#{URI.encode_www_form(utm_params)}"

  client.links.create(name, url_with_utm, slug)
end

create_tracked_link(
  "Twitter Campaign",
  "https://example.com/landing",
  "twittercampaign",
  {
    utm_source: 'twitter',
    utm_medium: 'social',
    utm_campaign: 'spring_sale'
  }
)
```

### Pixel Management

#### 1. Email-Safe Pixel Code

```ruby
def email_pixel_code(pixel_url)
  <<~HTML
    <!-- Umami Analytics Pixel -->
    <img src="#{pixel_url}"
         width="1"
         height="1"
         style="display:none"
         alt=""
         border="0" />
  HTML
end
```

#### 2. Organize by Campaign

```ruby
# Use descriptive names with dates
client.pixels.create(
  "Newsletter - March 2024 - Tech Edition",
  "nl-mar24-tech"
)
```

#### 3. Test Pixels Before Deployment

```ruby
def test_pixel(pixel_id)
  response = client.pixels.get(pixel_id)

  if response.success?
    pixel = response.data
    pixel_url = "https://analytics.example.com/p/#{pixel['slug']}"

    puts "Testing pixel: #{pixel['name']}"
    puts "URL: #{pixel_url}"

    # Test with curl
    system("curl -I #{pixel_url}")

    true
  else
    puts "Pixel not found"
    false
  end
end
```

### Error Handling

```ruby
def safe_create_link(name, url, slug)
  response = client.links.create(name, url, slug)

  if response.success?
    link = response.data
    puts "Created: #{link['slug']}"
    link
  else
    puts "Error: #{response.error_message}"

    # Handle specific errors
    if response.status == 409
      puts "Slug already exists, trying with timestamp..."
      new_slug = "#{slug}#{Time.now.to_i}"
      safe_create_link(name, url, new_slug)
    else
      nil
    end
  end
rescue UmamiClient::ValidationError => e
  puts "Validation error: #{e.message}"
  nil
end
```

### Cleanup Old Links/Pixels

```ruby
def cleanup_old_items(days_old: 90)
  cutoff_date = Time.now - (days_old * 24 * 60 * 60)

  # Cleanup links
  response = client.links.list
  return unless response.success?

  response.data['data'].each do |link|
    created_at = Time.parse(link['createdAt'])

    if created_at < cutoff_date
      delete_response = client.links.delete(link['id'])
      puts "Deleted old link: #{link['name']}" if delete_response.success?
    end
  end

  # Cleanup pixels
  response = client.pixels.list
  return unless response.success?

  response.data['data'].each do |pixel|
    created_at = Time.parse(pixel['createdAt'])

    if created_at < cutoff_date
      delete_response = client.pixels.delete(pixel['id'])
      puts "Deleted old pixel: #{pixel['name']}" if delete_response.success?
    end
  end
end
```

## Version Requirements

- **Umami v3.0.0+**: Links and Pixels features introduced
- **Self-hosted or Cloud**: Both deployment types supported

Check your Umami version before using these features.

## Related Documentation

- [Event Tracking](event-tracking.md) - Track custom events
- [Website Statistics](website-statistics.md) - View analytics data
- [Installation](installation.md) - Getting started
- [Usage Guide](usage.md) - Basic client usage

## Support

For issues or questions:
- Review [Umami Links Documentation](https://umami.is/docs/links)
- Review [Umami Pixels Documentation](https://umami.is/docs/pixels)
- Check [Umami v3 Release Notes](https://umami.is/docs/v3)
- Report bugs in the gem repository
