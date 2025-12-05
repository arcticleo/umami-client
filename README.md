# Umami Client

A Ruby client library for the [Umami Analytics API](https://umami.is/docs/api).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'umami-client'
```

And then execute:

```bash
$ bundle install
```

Or install it yourself as:

```bash
$ gem install umami-client
```

## Usage

### Configuration

The client supports two authentication methods:

#### 1. Umami Cloud (API Key Authentication)

Configure globally:

```ruby
require 'umami_client'

UmamiClient.configure do |config|
  config.api_key = "your-api-key"
  config.base_url = "https://api.umami.is" # optional, defaults to this
end
```

Or create a client with custom configuration:

```ruby
client = UmamiClient.new(
  api_key: "your-api-key",
  base_url: "https://api.umami.is"
)
```

#### 2. Self-Hosted (Username/Password Authentication)

For self-hosted Umami instances, use your web interface login credentials:

Configure globally:

```ruby
require 'umami_client'

UmamiClient.configure do |config|
  config.username = "your-username"  # Same as web login
  config.password = "your-password"  # Same as web login
  config.base_url = "https://your-umami-instance.com"
end

# Or use environment variables:
# UMAMI_USERNAME=your-username
# UMAMI_PASSWORD=your-password
# UMAMI_BASE_URL=https://your-umami-instance.com
```

Or create a client with custom configuration:

```ruby
client = UmamiClient.new(
  username: "your-username",
  password: "your-password",
  base_url: "https://your-umami-instance.com"
)
```

**How it works:** The client automatically detects which authentication method to use based on the credentials provided. For self-hosted instances, the client calls `/api/auth/login` with your credentials, receives a bearer token, and manages it automatically for all subsequent requests.

### Environment Variables

You can use environment variables to configure the client:

**For Umami Cloud:**
```bash
UMAMI_API_KEY=your-api-key
UMAMI_BASE_URL=https://api.umami.is  # optional
```

**For Self-Hosted:**
```bash
UMAMI_USERNAME=your-username
UMAMI_PASSWORD=your-password
UMAMI_BASE_URL=https://your-umami-instance.com
```

Then configure without passing values:
```ruby
UmamiClient.configure do |config|
  config.api_key = ENV['UMAMI_API_KEY']           # for Cloud
  config.username = ENV['UMAMI_USERNAME']         # for self-hosted
  config.password = ENV['UMAMI_PASSWORD']         # for self-hosted
  config.base_url = ENV['UMAMI_BASE_URL']
end
```

## Event Tracking

### Track Pageviews

Track page views on your website:

```ruby
UmamiClient.configure do |config|
  config.base_url = "https://your-umami-instance.com"
  config.username = "your-username"
  config.password = "your-password"
  config.website_id = "your-website-id"
  config.default_hostname = "example.com"
end

client = UmamiClient::Client.new

# Simple pageview
client.events.track_pageview("/")

# Pageview with title
client.events.track_pageview("/products", title: "Products Page")

# Pageview with referrer
client.events.track_pageview(
  "/blog/post-1",
  title: "Blog Post",
  referrer: "https://google.com"
)
```

### Track Custom Events

Track custom events with optional data:

```ruby
# Simple event
client.events.track_event("button_click")

# Event with custom data
client.events.track_event(
  "purchase",
  url: "/checkout/complete",
  data: {
    amount: 99.99,
    currency: "USD",
    product_id: "prod_123"
  }
)
```

**Note:** Custom events with the `name` field may not show up in some Umami versions. For reliable tracking, use `track_pageview` instead.

### User Identification

Use `identify` to associate a unique identifier with your website visitors so you can track their activity across sessions and devices. User properties are stored persistently and appear in the Properties column of the Session detail view in your Umami dashboard.

#### Basic Usage

```ruby
# Identify a website visitor by their unique ID (email, customer ID, etc.)
client.events.identify("customer_12345")

# Identify a visitor with custom properties
client.events.identify(
  "customer@example.com",
  data: {
    name: "John Doe",
    plan: "premium",
    signup_date: "2024-01-15",
    country: "USA",
    monthly_revenue: 99.99,
    is_verified: true
  }
)
```

#### When to Call Identify

**Call `identify` once per visitor session, typically:**

1. **After your website visitor logs into your application**
   ```ruby
   # In your application's authentication controller
   def after_sign_in(visitor)
     UmamiClient::Client.new.events.identify(
       visitor.email,  # Your website visitor's email
       data: {
         name: visitor.name,
         plan: visitor.subscription_plan,
         signup_date: visitor.created_at.to_date.to_s
       }
     )
   end
   ```

2. **After a visitor registers on your website**
   ```ruby
   # When a new user signs up for your service
   def after_create_account(visitor)
     UmamiClient::Client.new.events.identify(
       visitor.id.to_s,
       data: {
         name: visitor.name,
         source: visitor.signup_source,
         plan: "free"
       }
     )
   end
   ```

3. **When visitor properties change**
   ```ruby
   # When a customer upgrades their plan
   def after_upgrade_subscription(customer)
     UmamiClient::Client.new.events.identify(
       customer.email,
       data: {
         plan: customer.subscription_plan,
         upgraded_at: Time.now.to_s
       }
     )
   end
   ```

#### How Often to Call Identify

**DO:**
- ✅ Call once per session when a website visitor logs in
- ✅ Call after a visitor registers to set initial properties
- ✅ Call when important visitor properties change (plan upgrade, etc.)

**DON'T:**
- ❌ Call on every page view (it's not necessary - visitor ID persists automatically)
- ❌ Call multiple times in the same session with the same data
- ❌ Call for anonymous/unauthenticated visitors (unless you have a persistent anonymous ID)

#### Visitor ID Persistence

Once you call `identify`, the visitor ID automatically persists across all subsequent events:

```ruby
client = UmamiClient::Client.new

# Identify the website visitor once
client.events.identify("customer@example.com", data: { name: "John" })

# All subsequent events automatically include the visitor ID
client.events.track_pageview("/dashboard")  # ← includes visitor ID
client.events.track_event("button_click")    # ← includes visitor ID
client.events.track_pageview("/settings")    # ← includes visitor ID

# Clear the visitor ID when done (e.g., when visitor logs out)
client.events.reset_user
```

#### Rails Integration Example

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  # Track visitors to your website (NOT Umami admin users)
  after_action :identify_visitor, if: :user_signed_in?

  private

  def identify_visitor
    # Only identify once per session to avoid redundant calls
    return if session[:umami_identified]

    # Track your website's logged-in user/customer
    umami_client.events.identify(
      current_user.email,  # Your website visitor's identifier
      data: {
        name: current_user.name,
        plan: current_user.subscription_plan,
        signup_date: current_user.created_at.to_date.to_s
      }
    )

    session[:umami_identified] = true
  end

  def umami_client
    @umami_client ||= UmamiClient::Client.new
  end
end
```

#### Viewing Visitor Properties in Umami Dashboard

In your Umami dashboard:
1. Navigate to **Sessions**
2. Click on a visitor to view their session details
3. The **Properties** column on the right shows all visitor properties
4. You can also search for visitors by their distinct ID

### Configuration Options

```ruby
UmamiClient.configure do |config|
  # Required
  config.base_url = "https://your-umami-instance.com"
  config.username = "your-username"
  config.password = "your-password"
  config.website_id = "your-website-id"
  config.default_hostname = "example.com"

  # Optional
  config.user_agent = "Mozilla/5.0 ..."  # Default: Safari on macOS
  config.timeout = 30                    # Request timeout in seconds
  config.max_retries = 3                 # Max retry attempts
  config.retry_delay = 0.5               # Initial retry delay
  config.backoff_factor = 2              # Exponential backoff multiplier
end
```

### Custom User-Agent

The User-Agent string determines how Umami parses OS and device information. You can customize it:

```ruby
# Default (macOS Safari)
config.user_agent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.1 Safari/605.1.15"

# Windows Chrome
config.user_agent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

# iPhone Safari
config.user_agent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"
```

## Website Management

Manage websites in your Umami instance. All website management operations require authentication.

### List Websites

```ruby
client = UmamiClient::Client.new

# List all websites
response = client.websites.list
response.body["data"].each do |website|
  puts "#{website['name']}: #{website['id']}"
end

# With pagination
response = client.websites.list(page: 1, page_size: 50)
```

### Get Website Details

```ruby
# Get specific website by ID
response = client.websites.get("website-id")
website_data = response.body

puts website_data["name"]
puts website_data["domain"]
puts website_data["createdAt"]
```

### Create Website

```ruby
# Create a new website
response = client.websites.create("My Website", "example.com")

if response.success?
  website_id = response.body["id"]
  puts "Created website: #{website_id}"
end

# Create with optional parameters
response = client.websites.create(
  "Team Website",
  "team.example.com",
  share_id: "public-share-id",  # Optional: for public sharing
  team_id: "team-uuid"            # Optional: assign to team
)
```

### Update Website

The Umami API requires both `name` and `domain` when updating. This gem automatically fetches the missing field if you only provide one.

```ruby
# Update name only (domain fetched automatically)
response = client.websites.update("website-id", name: "New Name")

# Update domain only (name fetched automatically)
response = client.websites.update("website-id", domain: "newdomain.com")

# Update both
response = client.websites.update(
  "website-id",
  name: "New Name",
  domain: "newdomain.com"
)

# Update share ID (enable public sharing)
response = client.websites.update(
  "website-id",
  share_id: "my-share-id"
)

# Remove sharing (set share_id to nil)
response = client.websites.update(
  "website-id",
  share_id: nil
)
```

### Delete Website

```ruby
# Permanently delete a website
response = client.websites.delete("website-id")

if response.body["ok"]
  puts "Website deleted successfully"
end
```

### Reset Website Data

Clear all analytics data (pageviews, events, sessions) while preserving the website configuration.

```ruby
# Reset all tracking data
response = client.websites.reset("website-id")
puts "All data cleared" if response.success?
```

### Using the Website Model

For cleaner code, wrap website data in the `Website` model:

```ruby
# Get website and wrap in model
response = client.websites.get("website-id")
website = UmamiClient::Website.new(response.body)

# Access attributes
puts website.id
puts website.name
puts website.domain
puts website.created_at      # Parsed Time object
puts website.updated_at      # Parsed Time object

# Check status
puts "Shared!" if website.shared?
puts "Team website!" if website.team_website?

# Get public share URL
if website.shared?
  puts website.share_url("https://umami.example.com")
  # => "https://umami.example.com/share/abc123"
end

# Convert to hash
website.to_h
# => { id: "...", name: "...", domain: "...", ... }
```

### Complete Example

```ruby
require 'umami_client'

UmamiClient.configure do |config|
  config.username = ENV['UMAMI_USERNAME']
  config.password = ENV['UMAMI_PASSWORD']
  config.base_url = "https://umami.example.com"
end

client = UmamiClient::Client.new

# List all websites
puts "Current websites:"
client.websites.list.body["data"].each do |site|
  website = UmamiClient::Website.new(site)
  puts "  - #{website.name} (#{website.domain})"
end

# Create a new website
response = client.websites.create("Blog", "blog.example.com")
new_website = UmamiClient::Website.new(response.body)
puts "\nCreated: #{new_website.name}"

# Update it
client.websites.update(new_website.id, name: "My Awesome Blog")
puts "Updated name"

# Get updated details
response = client.websites.get(new_website.id)
updated = UmamiClient::Website.new(response.body)
puts "New name: #{updated.name}"

# Clean up
client.websites.delete(new_website.id)
puts "Deleted"
```

## Website Statistics

Retrieve analytics data from your Umami instance. All statistics operations require authentication.

### Active Visitors

Get the number of visitors currently active on your website (last 5 minutes):

```ruby
client = UmamiClient::Client.new

# Get active visitor count
response = client.stats.active("website-id")
puts "Active visitors: #{response.body['visitors']}"
```

### Summary Statistics

Get aggregated statistics for a date range, including pageviews, visitors, visits, bounce rate, and time spent.

#### Basic Usage

```ruby
# Get stats for a specific date range
now = Time.now
seven_days_ago = now - (7 * 24 * 60 * 60)

response = client.stats.summary(
  "website-id",
  seven_days_ago,
  now,
  unit: 'day',
  timezone: 'America/New_York'
)

stats = response.body
puts "Pageviews: #{stats['pageviews']['value']}"
puts "Visitors: #{stats['visitors']['value']}"
puts "Visits: #{stats['visits']['value']}"
puts "Bounce rate: #{stats['bounces']['value']}%"
puts "Total time: #{stats['totaltime']['value']} seconds"
```

#### Convenience Methods

For common date ranges, use these convenience methods:

```ruby
# Today's stats
response = client.stats.today("website-id")
puts "Today's pageviews: #{response.body['pageviews']['value']}"

# Yesterday's stats
response = client.stats.yesterday("website-id")
puts "Yesterday's visitors: #{response.body['visitors']['value']}"

# Last 7 days
response = client.stats.last_7_days("website-id")

# Last 30 days
response = client.stats.last_30_days("website-id")

# All convenience methods support custom timezone
response = client.stats.today("website-id", timezone: "Europe/London")
```

### Pageviews Time Series

Get time-bucketed pageview data for charts and graphs:

```ruby
now = Time.now
thirty_days_ago = now - (30 * 24 * 60 * 60)

response = client.stats.pageviews(
  "website-id",
  thirty_days_ago,
  now,
  unit: 'day',           # Options: 'minute', 'hour', 'day', 'month', 'year'
  timezone: 'UTC'        # Optional, defaults to UTC
)

# Plot the data
response.body['pageviews'].each do |point|
  puts "#{point['x']}: #{point['y']} pageviews"
end
# Output:
# 2025-11-04 00:00:00: 142 pageviews
# 2025-11-05 00:00:00: 198 pageviews
# ...
```

#### With Comparison

Compare data against a previous period:

```ruby
response = client.stats.pageviews(
  "website-id",
  seven_days_ago,
  now,
  unit: 'day',
  compare: 'prev'  # Compare to previous period ('prev' or 'yoy' for year-over-year)
)
```

### Metrics

Get aggregated metrics like top pages, referrers, browsers, countries, and more.

#### Top Pages

```ruby
now = Time.now
thirty_days_ago = now - (30 * 24 * 60 * 60)

response = client.stats.metrics(
  "website-id",
  thirty_days_ago,
  now,
  "url",      # Metric type
  limit: 10   # Top 10 results
)

puts "Top pages:"
response.body.each do |metric|
  puts "  #{metric['x']}: #{metric['y']} views"
end
# Output:
#   /blog/post-1: 1,234 views
#   /products: 892 views
#   /: 654 views
```

#### Available Metric Types

```ruby
# Top referrers
client.stats.metrics(website_id, start_at, end_at, "referrer", limit: 10)

# Browsers
client.stats.metrics(website_id, start_at, end_at, "browser", limit: 10)

# Operating systems
client.stats.metrics(website_id, start_at, end_at, "os", limit: 10)

# Devices
client.stats.metrics(website_id, start_at, end_at, "device", limit: 10)

# Countries
client.stats.metrics(website_id, start_at, end_at, "country", limit: 10)

# Languages
client.stats.metrics(website_id, start_at, end_at, "language", limit: 10)

# Page titles
client.stats.metrics(website_id, start_at, end_at, "title", limit: 10)

# Query parameters
client.stats.metrics(website_id, start_at, end_at, "query", limit: 10)

# Custom events
client.stats.metrics(website_id, start_at, end_at, "event", limit: 10)
```

#### With Filters

Filter metrics by URL, referrer, or other properties:

```ruby
response = client.stats.metrics(
  "website-id",
  start_at,
  end_at,
  "browser",
  filters: {
    url: "/blog/*",
    country: "US"
  }
)
```

#### Pagination

```ruby
response = client.stats.metrics(
  "website-id",
  start_at,
  end_at,
  "url",
  limit: 20,
  offset: 0
)

# Get next page
response = client.stats.metrics(
  "website-id",
  start_at,
  end_at,
  "url",
  limit: 20,
  offset: 20
)
```

### Event Series

Get time-bucketed custom event data:

```ruby
now = Time.now
seven_days_ago = now - (7 * 24 * 60 * 60)

response = client.stats.events_series(
  "website-id",
  seven_days_ago,
  now,
  unit: 'day',
  timezone: 'UTC'
)

# Process event data
response.body['events'].each do |event|
  puts "#{event['x']}: #{event['y']} events"
end
```

### Complete Dashboard Example

Build a complete analytics dashboard:

```ruby
require 'umami_client'

UmamiClient.configure do |config|
  config.username = ENV['UMAMI_USERNAME']
  config.password = ENV['UMAMI_PASSWORD']
  config.base_url = "https://umami.example.com"
end

client = UmamiClient::Client.new
website_id = "your-website-id"

# Real-time data
active = client.stats.active(website_id)
puts "🟢 #{active.body['visitors']} visitors online now"
puts ""

# Today's summary
today = client.stats.today(website_id)
puts "📊 Today's Stats:"
puts "  Pageviews: #{today.body['pageviews']['value']}"
puts "  Visitors: #{today.body['visitors']['value']}"
puts "  Visits: #{today.body['visits']['value']}"
puts "  Bounce rate: #{today.body['bounces']['value']}%"
puts ""

# Last 7 days trend
now = Time.now
seven_days_ago = now - (7 * 24 * 60 * 60)
pageviews = client.stats.pageviews(
  website_id,
  seven_days_ago,
  now,
  unit: 'day'
)

puts "📈 7-Day Trend:"
pageviews.body['pageviews'].each do |point|
  date = point['x'].split(' ')[0]
  puts "  #{date}: #{point['y']} views"
end
puts ""

# Top content
now = Time.now
thirty_days_ago = now - (30 * 24 * 60 * 60)

urls = client.stats.metrics(website_id, thirty_days_ago, now, "url", limit: 5)
puts "🔥 Top Pages (30 days):"
urls.body.each_with_index do |metric, i|
  puts "  #{i + 1}. #{metric['x']}: #{metric['y']} views"
end
puts ""

# Traffic sources
countries = client.stats.metrics(website_id, thirty_days_ago, now, "country", limit: 5)
puts "🌍 Top Countries:"
countries.body.each do |metric|
  puts "  #{metric['x']}: #{metric['y']} visits"
end
puts ""

# Browsers
browsers = client.stats.metrics(website_id, thirty_days_ago, now, "browser", limit: 5)
puts "🌐 Top Browsers:"
browsers.body.each do |metric|
  puts "  #{metric['x']}: #{metric['y']} visits"
end
```

### Time Handling

The Stats API accepts timestamps as either:
- Ruby `Time` objects (automatically converted to milliseconds)
- Integer timestamps in milliseconds

```ruby
# Using Time objects (recommended)
start_time = Time.now - (7 * 24 * 60 * 60)
end_time = Time.now
client.stats.summary(website_id, start_time, end_time)

# Using millisecond timestamps
start_ms = (Time.now.to_f * 1000).to_i - (7 * 24 * 60 * 60 * 1000)
end_ms = (Time.now.to_f * 1000).to_i
client.stats.summary(website_id, start_ms, end_ms)
```

## Session Queries

Query session data including finding sessions by distinct ID (visitor identifier), retrieving session properties, and getting all activity for a specific visitor.

### Finding Sessions by Distinct ID

The most common use case: finding all events/pageviews for a specific visitor you identified with `identify()`.

```ruby
client = UmamiClient::Client.new

# 1. Search for sessions by distinct ID (email, user ID, etc.)
response = client.sessions.list(
  "website-id",
  Time.now - 30.days,
  Time.now,
  search: "customer@example.com"
)

sessions = response.body['data']
puts "Found #{sessions.length} sessions"

# 2. Get the session ID
session_id = sessions.first['id']

# 3. Get session properties to confirm the visitor
properties = client.sessions.properties("website-id", session_id)
puts "Visitor properties:"
properties.body.each do |prop|
  puts "  #{prop['dataKey']}: #{prop['stringValue'] || prop['numberValue']}"
end

# 4. Get ALL pageviews and events for this visitor
activity = client.sessions.activity(
  "website-id",
  session_id,
  Time.now - 30.days,
  Time.now
)

puts "\nVisitor activity:"
activity.body.each do |event|
  event_type = event['eventType'] == 1 ? 'pageview' : 'event'
  puts "  [#{event_type}] #{event['urlPath']} at #{event['createdAt']}"
end
```

### List Sessions

Get a list of sessions with optional search and filtering:

```ruby
# List recent sessions
response = client.sessions.list(
  "website-id",
  Time.now - 7.days,
  Time.now,
  page_size: 50
)

response.body['data'].each do |session|
  puts "#{session['browser']}/#{session['os']}: #{session['pageviews']} views"
end

# Search for specific visitor
response = client.sessions.list(
  "website-id",
  Time.now - 30.days,
  Time.now,
  search: "premium-user@example.com"
)
```

### Session Details

Get detailed information about a specific session:

```ruby
# Get session details
response = client.sessions.get("website-id", "session-id")

puts "Browser: #{response.body['browser']}"
puts "OS: #{response.body['os']}"
puts "Country: #{response.body['country']}"
puts "Device: #{response.body['device']}"
puts "Pageviews: #{response.body['pageviews']}"
puts "Visits: #{response.body['visits']}"
```

### Session Activity

Get all pageviews and events for a session:

```ruby
response = client.sessions.activity(
  "website-id",
  "session-id",
  Time.now - 30.days,
  Time.now
)

response.body.each do |activity|
  event_type = activity['eventType'] == 1 ? 'pageview' : 'event'
  event_name = activity['eventName'] || '-'

  puts "[#{event_type}] #{activity['urlPath']}"
  puts "  Event: #{event_name}" if event_name != '-'
  puts "  Time: #{activity['createdAt']}"
  puts "  Referrer: #{activity['referrerPath']}" if activity['referrerPath']
end
```

### Session Properties

Get custom properties set via `identify()`:

```ruby
response = client.sessions.properties("website-id", "session-id")

# Properties are returned as an array of property objects
response.body.each do |prop|
  key = prop['dataKey']
  value = case prop['dataType']
          when 1 then prop['stringValue']  # String
          when 2 then prop['numberValue']   # Number
          when 3 then prop['stringValue'] == 'true'  # Boolean
          when 4 then prop['dateValue']     # Date
          end

  puts "#{key}: #{value}"
end
```

### Session Statistics

Get aggregated statistics across all sessions:

```ruby
response = client.sessions.stats(
  "website-id",
  Time.now - 30.days,
  Time.now
)

puts "Total pageviews: #{response.body['pageviews']['value']}"
puts "Unique visitors: #{response.body['visitors']['value']}"
puts "Total visits: #{response.body['visits']['value']}"
puts "Countries: #{response.body['countries']['value']}"
puts "Events: #{response.body['events']['value']}"
```

### Weekly Session Patterns

Analyze session patterns by day of week and hour:

```ruby
response = client.sessions.weekly(
  "website-id",
  Time.now - 30.days,
  Time.now,
  timezone: 'America/New_York'
)

weekdays = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']

response.body.each_with_index do |day_data, idx|
  total = day_data.sum
  peak_hour = day_data.each_with_index.max[1]

  puts "#{weekdays[idx]}: #{total} sessions (peak at #{peak_hour}:00)"
end
```

### Session Property Names

Get a list of all custom property names that have been set:

```ruby
response = client.sessions.property_names(
  "website-id",
  Time.now - 30.days,
  Time.now
)

puts "Custom properties being tracked:"
response.body.each do |prop|
  puts "  #{prop['propertyName']}: #{prop['total']} sessions"
end
```

### Session Property Values

Get all unique values for a specific property:

```ruby
# Get all plan types
response = client.sessions.property_values(
  "website-id",
  "plan"
)

puts "Subscription plans:"
response.body.each do |item|
  puts "  #{item['value']}: #{item['total']} sessions"
end

# With date range
response = client.sessions.property_values(
  "website-id",
  "plan",
  start_at: Time.now - 30.days,
  end_at: Time.now
)
```

### Complete Visitor Tracking Example

Track a visitor's complete journey from signup to activity:

```ruby
require 'umami_client'

UmamiClient.configure do |config|
  config.username = ENV['UMAMI_USERNAME']
  config.password = ENV['UMAMI_PASSWORD']
  config.base_url = "https://umami.example.com"
end

client = UmamiClient::Client.new
website_id = "your-website-id"

# Find a specific customer
customer_email = "premium.customer@example.com"

# 1. Search for their sessions
sessions_response = client.sessions.list(
  website_id,
  Time.now - 90.days,
  Time.now,
  search: customer_email
)

if sessions_response.body['data'].any?
  session = sessions_response.body['data'].first
  session_id = session['id']

  puts "Customer: #{customer_email}"
  puts "Browser: #{session['browser']}"
  puts "Location: #{session['city']}, #{session['country']}"
  puts ""

  # 2. Get their profile data
  properties = client.sessions.properties(website_id, session_id)

  puts "Profile:"
  properties.body.each do |prop|
    value = prop['stringValue'] || prop['numberValue']
    puts "  #{prop['dataKey']}: #{value}"
  end
  puts ""

  # 3. Get their activity history
  activity = client.sessions.activity(
    website_id,
    session_id,
    Time.now - 90.days,
    Time.now
  )

  puts "Recent Activity (#{activity.body.length} events):"
  activity.body.first(10).each do |event|
    event_type = event['eventType'] == 1 ? 'VIEW' : 'EVENT'
    puts "  [#{event_type}] #{event['urlPath']} - #{event['createdAt']}"
  end
else
  puts "No sessions found for #{customer_email}"
end
```

## Reports Management

Reports are saved analytics queries that can be executed repeatedly with consistent parameters. The Reports API allows you to create, read, update, and delete reports programmatically.

### List Reports

Retrieve all reports for a website with optional type filtering and pagination:

```ruby
# List all reports
response = client.reports.list("website-id")
response.body['data'].each do |report|
  puts "#{report['name']} (#{report['type']})"
end

# Filter by report type
response = client.reports.list("website-id", type: "funnel")

# With pagination
response = client.reports.list(
  "website-id",
  page: 2,
  page_size: 50
)
```

**Available report types:**
- `attribution` - Marketing attribution analysis
- `breakdown` - Dimension breakdown (OS, country, device, browser)
- `funnel` - Conversion funnel tracking
- `goal` - Goal completion metrics
- `journey` - User journey/path analysis
- `retention` - User retention and cohort analysis
- `revenue` - Revenue tracking and metrics
- `utm` - UTM parameter campaign tracking

### Create Report

Create a new saved report with specific parameters:

```ruby
# Create a funnel report
response = client.reports.create(
  "website-id",
  "Signup Funnel",
  "funnel",
  {
    window: 30,  # 30-day conversion window
    steps: [
      { url: "/signup" },
      { url: "/confirm-email" },
      { url: "/welcome" }
    ]
  },
  description: "Track user signup completion"
)

puts "Created report: #{response.body['id']}"

# Create a breakdown report
response = client.reports.create(
  "website-id",
  "Traffic by Country",
  "breakdown",
  {
    type: "country",
    limit: 20
  },
  description: "Geographic traffic distribution"
)

# Create a goal report
response = client.reports.create(
  "website-id",
  "Purchase Conversions",
  "goal",
  {
    url: "/thank-you",
    type: "pageview"
  },
  description: "Track completed purchases"
)
```

### Get Report

Retrieve full details of a specific report:

```ruby
response = client.reports.get("report-id")

report = response.body
puts "Report: #{report['name']}"
puts "Type: #{report['type']}"
puts "Description: #{report['description']}"
puts "Parameters: #{report['parameters']}"
puts "Created: #{report['createdAt']}"
puts "Updated: #{report['updatedAt']}"
```

### Update Report

Modify an existing report's name, description, or parameters:

```ruby
# Update funnel window and steps
response = client.reports.update(
  "report-id",
  "Updated Signup Funnel",
  "funnel",
  {
    window: 60,  # Changed to 60 days
    steps: [
      { url: "/signup" },
      { url: "/confirm-email" },
      { url: "/welcome" },
      { url: "/onboarding-complete" }  # Added step
    ]
  },
  description: "Extended funnel with onboarding"
)

puts "Updated: #{response.body['name']}"
```

**Note:** When updating, you must provide all parameters (name, type, parameters), not just the fields you want to change.

### Delete Report

Permanently remove a report:

```ruby
response = client.reports.delete("report-id")
puts "Deleted: #{response.body['ok']}"  # => true
```

### Complete Example

Here's a complete workflow for managing reports:

```ruby
# Create a retention report
create_response = client.reports.create(
  website_id,
  "30-Day User Retention",
  "retention",
  {
    period: 30,
    cohortStart: (Time.now - 90.days).to_i * 1000,
    cohortEnd: Time.now.to_i * 1000
  },
  description: "Monthly retention cohort analysis"
)

report_id = create_response.body['id']
puts "Created report: #{report_id}"

# List all retention reports
list_response = client.reports.list(website_id, type: "retention")
puts "\nRetention Reports:"
list_response.body['data'].each do |report|
  puts "  - #{report['name']} (created #{report['createdAt']})"
end

# Get full report details
get_response = client.reports.get(report_id)
puts "\nReport Details:"
puts "  Name: #{get_response.body['name']}"
puts "  Parameters: #{get_response.body['parameters']}"

# Update the report
update_response = client.reports.update(
  report_id,
  "90-Day User Retention",
  "retention",
  {
    period: 90,  # Extended to 90 days
    cohortStart: (Time.now - 180.days).to_i * 1000,
    cohortEnd: Time.now.to_i * 1000
  },
  description: "Quarterly retention cohort analysis"
)
puts "\nUpdated to: #{update_response.body['name']}"

# Clean up - delete the report
delete_response = client.reports.delete(report_id)
puts "\nDeleted: #{delete_response.body['ok']}"
```

### Report Parameters by Type

Each report type has specific parameter requirements. Here are common patterns:

**Funnel Reports:**
```ruby
parameters: {
  window: 30,           # Conversion window in days
  steps: [              # Array of funnel steps
    { url: "/step1" },
    { url: "/step2" }
  ]
}
```

**Breakdown Reports:**
```ruby
parameters: {
  type: "country",      # Dimension: country, os, browser, device
  limit: 20             # Number of results
}
```

**Goal Reports:**
```ruby
parameters: {
  url: "/success",      # Goal URL
  type: "pageview"      # Goal type: pageview or event
}
```

**Journey Reports:**
```ruby
parameters: {
  start: "/home",       # Journey start point
  end: "/checkout"      # Journey end point
}
```

**Retention Reports:**
```ruby
parameters: {
  period: 30,           # Retention period in days
  cohortStart: 1700000000000,  # Cohort start (milliseconds)
  cohortEnd: 1702000000000     # Cohort end (milliseconds)
}
```

**Attribution Reports:**
```ruby
parameters: {
  model: "first-click"  # Attribution model
}
```

**Revenue Reports:**
```ruby
parameters: {
  currency: "USD"       # Revenue currency
}
```

**UTM Reports:**
```ruby
parameters: {
  type: "utm_source"    # UTM parameter: utm_source, utm_medium, utm_campaign
}
```

### Executing Funnel Reports

Funnel reports analyze user progression through sequential steps to identify conversion rates and drop-off points. This is essential for understanding where users abandon processes like signup, checkout, or onboarding.

#### Basic Funnel Analysis

```ruby
# Simple signup funnel
response = client.reports.funnel(
  "website-id",
  Time.now - 30.days,
  Time.now,
  [
    { type: "path", value: "/signup" },
    { type: "path", value: "/confirm-email" },
    { type: "path", value: "/welcome" }
  ],
  30  # 30-day conversion window
)

# Analyze results
response.body.each_with_index do |step, index|
  puts "Step #{index + 1}: #{step['visitors']} visitors"
  puts "  Conversion rate: #{step['conversionRate']}%"
  puts "  Drop-off rate: #{step['dropoffRate']}%"
end
```

#### Funnel Step Types

Funnels support two types of steps:

**Path steps** - Track specific URL paths:
```ruby
{ type: "path", value: "/checkout" }
```

**Event steps** - Track custom events:
```ruby
{ type: "event", value: "add_to_cart" }
```

#### E-commerce Checkout Funnel

```ruby
response = client.reports.funnel(
  "website-id",
  Time.now - 7.days,
  Time.now,
  [
    { type: "path", value: "/cart" },
    { type: "event", value: "begin-checkout" },
    { type: "event", value: "add-payment-info" },
    { type: "event", value: "purchase" }
  ],
  7,  # 7-day conversion window
  filters: { country: "US" }
)

# Calculate overall conversion
first_step = response.body.first
last_step = response.body.last
overall_conversion = (last_step['visitors'].to_f / first_step['visitors'] * 100).round(2)
puts "Overall conversion: #{overall_conversion}%"
```

#### Onboarding Funnel

```ruby
response = client.reports.funnel(
  "website-id",
  Time.now - 90.days,
  Time.now,
  [
    { type: "event", value: "signup" },
    { type: "event", value: "profile_complete" },
    { type: "event", value: "tutorial_start" },
    { type: "event", value: "tutorial_complete" },
    { type: "event", value: "first_action" }
  ],
  14  # 14-day conversion window
)

# Identify drop-off points
response.body.each_with_index do |step, index|
  if step['dropoffRate'] > 50
    puts "⚠️  High drop-off at step #{index + 1}: #{step['dropoffRate']}%"
  end
end
```

#### Conversion Windows

The `window` parameter specifies how many days users have to complete the funnel:

```ruby
# Strict same-session funnel (1 day)
client.reports.funnel(website_id, start_date, end_date, steps, 1)

# Week-long conversion window
client.reports.funnel(website_id, start_date, end_date, steps, 7)

# Month-long conversion window
client.reports.funnel(website_id, start_date, end_date, steps, 30)

# Quarter-long conversion window
client.reports.funnel(website_id, start_date, end_date, steps, 90)
```

#### Filtering Funnels

Apply filters to analyze specific user segments:

```ruby
# US visitors only
client.reports.funnel(
  website_id, start_date, end_date, steps, 30,
  filters: { country: "US" }
)

# Mobile users only
client.reports.funnel(
  website_id, start_date, end_date, steps, 30,
  filters: { device: "mobile" }
)

# Specific browser
client.reports.funnel(
  website_id, start_date, end_date, steps, 30,
  filters: { browser: "chrome" }
)

# Multiple filters
client.reports.funnel(
  website_id, start_date, end_date, steps, 30,
  filters: {
    country: "US",
    device: "mobile",
    os: "ios"
  }
)
```

#### Common Funnel Patterns

**Signup Funnel:**
```ruby
steps = [
  { type: "path", value: "/landing" },
  { type: "path", value: "/signup" },
  { type: "event", value: "email_verified" },
  { type: "path", value: "/welcome" }
]
```

**Checkout Funnel:**
```ruby
steps = [
  { type: "path", value: "/cart" },
  { type: "path", value: "/checkout" },
  { type: "event", value: "payment_info_added" },
  { type: "event", value: "order_complete" }
]
```

**Content Engagement Funnel:**
```ruby
steps = [
  { type: "path", value: "/article" },
  { type: "event", value: "scroll_75" },
  { type: "event", value: "newsletter_signup" }
]
```

**SaaS Trial Conversion:**
```ruby
steps = [
  { type: "event", value: "trial_start" },
  { type: "event", value: "feature_used" },
  { type: "event", value: "invite_sent" },
  { type: "event", value: "payment_added" }
]
```

#### Complete Funnel Analysis Example

```ruby
# Define analysis period
start_date = Time.now - 30.days
end_date = Time.now

# Execute funnel
response = client.reports.funnel(
  website_id,
  start_date,
  end_date,
  [
    { type: "path", value: "/pricing" },
    { type: "path", value: "/signup" },
    { type: "event", value: "email_verified" },
    { type: "event", value: "payment_added" },
    { type: "event", value: "subscription_active" }
  ],
  30
)

puts "Conversion Funnel Analysis"
puts "=" * 50

response.body.each_with_index do |step, index|
  visitors = step['visitors']
  conversion = step['conversionRate']
  dropoff = step['dropoffRate']

  puts "\nStep #{index + 1}:"
  puts "  Visitors: #{visitors}"
  puts "  Conversion: #{conversion}% of previous step"
  puts "  Drop-off: #{dropoff}%"

  # Highlight problem areas
  if dropoff > 60
    puts "  ⚠️  CRITICAL: High drop-off rate!"
  elsif dropoff > 40
    puts "  ⚠️  WARNING: Significant drop-off"
  end
end

# Calculate overall metrics
first_step = response.body.first
last_step = response.body.last
total_visitors = first_step['visitors']
completed = last_step['visitors']
overall_rate = (completed.to_f / total_visitors * 100).round(2)

puts "\n" + "=" * 50
puts "Overall Metrics:"
puts "  Started: #{total_visitors}"
puts "  Completed: #{completed}"
puts "  Overall conversion: #{overall_rate}%"
puts "  Total drop-off: #{((1 - completed.to_f / total_visitors) * 100).round(2)}%"
```

## Disabled Mode for Testing

When running tests, you typically don't want to make actual HTTP requests to Umami. Disabled mode allows you to skip all HTTP requests while still validating parameters and returning mock responses.

### Basic Usage

```ruby
# Disable tracking
UmamiClient.disable!

# All tracking methods now return mock responses without making HTTP requests
client = UmamiClient::Client.new
response = client.events.track_pageview("/test")
# => Returns a mock response with status 200 and fake sessionId/visitId

# Check if disabled
UmamiClient.disabled? # => true

# Re-enable tracking
UmamiClient.enable!
```

### Test Configuration

#### Minitest

```ruby
# test/test_helper.rb
require 'umami_client'

# Disable tracking for all tests
UmamiClient.disable!

# Or configure via config
UmamiClient.configure do |config|
  config.disabled = true
end
```

#### RSpec

```ruby
# spec/spec_helper.rb
require 'umami_client'

RSpec.configure do |config|
  # Disable tracking before the test suite runs
  config.before(:suite) do
    UmamiClient.disable!
  end
end
```

#### Rails

```ruby
# config/environments/test.rb
Rails.application.configure do
  # Disable Umami tracking in test environment
  config.after_initialize do
    UmamiClient.disable!
  end
end
```

### With Logging

You can enable logging to see what would have been tracked:

```ruby
require 'logger'

UmamiClient.configure do |config|
  config.disabled = true
  config.logger = Logger.new($stdout)
end

client = UmamiClient::Client.new
client.events.track_pageview("/test")
# Logs: [Umami Disabled] Would have tracked event: url=/test
```

### How It Works

When disabled mode is enabled:

- ✅ **No HTTP requests** are made to Umami
- ✅ **Parameters are still validated** (raises errors for invalid input)
- ✅ **Mock responses returned** with realistic structure (200 status, sessionId, visitId)
- ✅ **Optional logging** shows what would have been tracked
- ✅ **All tracking methods work** (track_pageview, track_event, identify)

### Example Test

```ruby
require 'minitest/autorun'
require 'umami_client'

class MyFeatureTest < Minitest::Test
  def setup
    UmamiClient.configure do |config|
      config.base_url = "https://umami.example.com"
      config.website_id = "test-id"
      config.default_hostname = "example.com"
      config.disabled = true  # Disable for tests
    end

    @client = UmamiClient::Client.new
  end

  def test_tracks_signup_event
    # This won't make an actual HTTP request
    response = @client.events.track_event("user_signup")

    assert_equal 200, response.status
    assert response.body['sessionId']
    # Your app logic continues normally
  end
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/yourusername/umami-client.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
