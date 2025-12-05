# Website Management

Manage websites in your Umami instance. All website management operations require authentication.

## List Websites

```ruby
client = UmamiClient::Client.new

 List all websites
response = client.websites.list
response.body["data"].each do |website|
  puts "#{website['name']}: #{website['id']}"
end

 With pagination
response = client.websites.list(page: 1, page_size: 50)
```

## Get Website Details

```ruby
 Get specific website by ID
response = client.websites.get("website-id")
website_data = response.body

puts website_data["name"]
puts website_data["domain"]
puts website_data["createdAt"]
```

## Create Website

```ruby
 Create a new website
response = client.websites.create("My Website", "example.com")

if response.success?
  website_id = response.body["id"]
  puts "Created website: #{website_id}"
end

 Create with optional parameters
response = client.websites.create(
  "Team Website",
  "team.example.com",
  share_id: "public-share-id",  # Optional: for public sharing
  team_id: "team-uuid"            # Optional: assign to team
)
```

## Update Website

The Umami API requires both `name` and `domain` when updating. This gem automatically fetches the missing field if you only provide one.

```ruby
 Update name only (domain fetched automatically)
response = client.websites.update("website-id", name: "New Name")

 Update domain only (name fetched automatically)
response = client.websites.update("website-id", domain: "newdomain.com")

 Update both
response = client.websites.update(
  "website-id",
  name: "New Name",
  domain: "newdomain.com"
)

 Update share ID (enable public sharing)
response = client.websites.update(
  "website-id",
  share_id: "my-share-id"
)

 Remove sharing (set share_id to nil)
response = client.websites.update(
  "website-id",
  share_id: nil
)
```

## Delete Website

```ruby
 Permanently delete a website
response = client.websites.delete("website-id")

if response.body["ok"]
  puts "Website deleted successfully"
end
```

## Reset Website Data

Clear all analytics data (pageviews, events, sessions) while preserving the website configuration.

```ruby
 Reset all tracking data
response = client.websites.reset("website-id")
puts "All data cleared" if response.success?
```

## Using the Website Model

For cleaner code, wrap website data in the `Website` model:

```ruby
 Get website and wrap in model
response = client.websites.get("website-id")
website = UmamiClient::Website.new(response.body)

 Access attributes
puts website.id
puts website.name
puts website.domain
puts website.created_at      # Parsed Time object
puts website.updated_at      # Parsed Time object

 Check status
puts "Shared!" if website.shared?
puts "Team website!" if website.team_website?

 Get public share URL
if website.shared?
  puts website.share_url("https://umami.example.com")
  # => "https://umami.example.com/share/abc123"
end

 Convert to hash
website.to_h
 => { id: "...", name: "...", domain: "...", ... }
```

## Complete Example

```ruby
require 'umami_client'

UmamiClient.configure do |config|
  config.username = ENV['UMAMI_USERNAME']
  config.password = ENV['UMAMI_PASSWORD']
  config.base_url = "https://umami.example.com"
end

client = UmamiClient::Client.new

 List all websites
puts "Current websites:"
client.websites.list.body["data"].each do |site|
  website = UmamiClient::Website.new(site)
  puts "  - #{website.name} (#{website.domain})"
end

 Create a new website
response = client.websites.create("Blog", "blog.example.com")
new_website = UmamiClient::Website.new(response.body)
puts "\nCreated: #{new_website.name}"

 Update it
client.websites.update(new_website.id, name: "My Awesome Blog")
puts "Updated name"

 Get updated details
response = client.websites.get(new_website.id)
updated = UmamiClient::Website.new(response.body)
puts "New name: #{updated.name}"

 Clean up
client.websites.delete(new_website.id)
puts "Deleted"
```

