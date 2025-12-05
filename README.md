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

### Executing Journey Reports

Journey reports analyze actual user navigation paths through your website, revealing how users naturally explore and move between pages. Unlike funnels (which track predefined sequential steps), journey reports **discover** all possible paths users take, helping you understand real-world navigation behavior.

#### Basic Journey Analysis

```ruby
# Discover common paths from homepage
response = client.reports.journey(
  "website-id",
  Time.now - 30.days,
  Time.now,
  "/",
  5  # Track 5 steps
)

# Display top navigation paths
puts "Most common navigation paths:"
response.body.first(10).each do |path|
  puts "#{path['count']} users: #{path['items'].join(' → ')}"
end
```

#### Journey vs Funnel

**Funnels** are for measuring conversion through predefined steps:
- You define the exact sequence
- Measures drop-off at each step
- Good for: conversion optimization, checkout flows

**Journeys** are for discovering actual user behavior:
- Shows all paths users actually take
- Reveals unexpected routes
- Good for: site architecture, UX improvements, content discovery

#### Finding Paths to a Destination

Filter journeys to only show paths that reach a specific destination:

```ruby
# Find all routes from homepage to pricing page
response = client.reports.journey(
  "website-id",
  Time.now - 30.days,
  Time.now,
  "/",
  5,
  end_step: "/pricing"
)

puts "Routes to pricing page:"
response.body.each do |path|
  # Extract intermediate steps (excluding start and end)
  intermediate = path['items'][1..-2]
  puts "#{path['count']} users via: #{intermediate.join(' → ')}"
end
```

This reveals which pages users visit before reaching your pricing page, helping you understand the customer decision journey.

#### Journey Step Lengths

Track between 3 and 7 steps based on your analysis needs:

```ruby
# Short journey (3 steps) - immediate next actions
client.reports.journey(website_id, start_date, end_date, "/", 3)

# Medium journey (5 steps) - typical session exploration
client.reports.journey(website_id, start_date, end_date, "/", 5)

# Long journey (7 steps) - deep navigation patterns
client.reports.journey(website_id, start_date, end_date, "/", 7)
```

**Guidelines:**
- **3 steps**: Immediate next actions, quick decisions
- **4-5 steps**: Typical session exploration, moderate browsing
- **6-7 steps**: Deep research behavior, extensive browsing

#### Content Discovery Journey

```ruby
# Discover how users navigate from articles
response = client.reports.journey(
  "website-id",
  Time.now - 30.days,
  Time.now,
  "/blog/article-1",
  5
)

puts "Content navigation patterns:"
response.body.first(10).each do |path|
  items = path['items']
  count = path['count']

  # Identify related content readers explore
  related_content = items.select { |page| page.start_with?('/blog/') }
  puts "#{count} users read: #{related_content.join(', ')}"
end
```

#### E-commerce Shopping Journey

```ruby
# Track shopping behavior from product pages
response = client.reports.journey(
  "website-id",
  Time.now - 7.days,
  Time.now,
  "/product",
  5,
  end_step: "/checkout"
)

puts "Shopping journey analysis:"
response.body.each do |path|
  count = path['count']
  items = path['items']

  # Check if users view multiple products
  product_views = items.count { |page| page.start_with?('/product') }

  puts "#{count} users:"
  puts "  Viewed #{product_views} products"
  puts "  Path: #{items.join(' → ')}"
end
```

#### Event-Based Journeys

Track journeys starting from custom events:

```ruby
# Discover what users do after signup
response = client.reports.journey(
  "website-id",
  Time.now - 90.days,
  Time.now,
  "signup",  # Custom event
  5
)

puts "Post-signup behavior:"
response.body.first(5).each do |path|
  puts "#{path['count']} users: #{path['items'].join(' → ')}"
end
```

#### Segmented Journey Analysis

Filter journeys by user segments to understand different behaviors:

```ruby
# Mobile user navigation patterns
mobile_response = client.reports.journey(
  "website-id",
  Time.now - 30.days,
  Time.now,
  "/",
  5,
  filters: { device: "mobile" }
)

# Desktop user navigation patterns
desktop_response = client.reports.journey(
  "website-id",
  Time.now - 30.days,
  Time.now,
  "/",
  5,
  filters: { device: "desktop" }
)

# Compare behavior
puts "Mobile paths: #{mobile_response.body.length} unique"
puts "Desktop paths: #{desktop_response.body.length} unique"

# Find mobile-specific patterns
mobile_first_steps = mobile_response.body.map { |p| p['items'][1] }.compact.uniq
puts "Mobile users typically visit: #{mobile_first_steps.join(', ')}"
```

#### Geographic Journey Differences

```ruby
# US visitor behavior
us_response = client.reports.journey(
  "website-id",
  start_date, end_date, "/", 5,
  filters: { country: "US" }
)

# European visitor behavior
eu_response = client.reports.journey(
  "website-id",
  start_date, end_date, "/", 5,
  filters: { country: "DE" }
)

# Compare navigation patterns
puts "US visitors take #{us_response.body.length} different paths"
puts "EU visitors take #{eu_response.body.length} different paths"
```

#### Complete Journey Analysis Example

```ruby
# Analyze product discovery and purchase behavior
start_date = Time.now - 30.days
end_date = Time.now

# Execute journey from homepage to checkout
response = client.reports.journey(
  website_id,
  start_date,
  end_date,
  "/",
  7,
  end_step: "/checkout"
)

puts "Product Discovery Journey Analysis"
puts "=" * 50
puts "\nTotal unique paths to checkout: #{response.body.length}"

# Analyze path characteristics
response.body.each_with_index do |path, index|
  items = path['items']
  count = path['count']

  # Calculate metrics
  path_length = items.length
  product_views = items.count { |p| p.start_with?('/product') }
  has_search = items.any? { |p| p.include?('/search') }
  has_category = items.any? { |p| p.start_with?('/category') }

  puts "\nPath #{index + 1} (#{count} users, #{path_length} steps):"
  puts "  Route: #{items.join(' → ')}"
  puts "  Product views: #{product_views}"
  puts "  Used search: #{has_search ? 'Yes' : 'No'}"
  puts "  Browsed categories: #{has_category ? 'Yes' : 'No'}"
end

# Identify most efficient path
shortest_path = response.body.min_by { |p| p['items'].length }
most_popular = response.body.max_by { |p| p['count'] }

puts "\n" + "=" * 50
puts "Key Insights:"
puts "  Shortest path: #{shortest_path['items'].length} steps"
puts "  Most popular path: #{most_popular['count']} users"
puts "  Most popular route: #{most_popular['items'].join(' → ')}"

# Find common patterns
all_pages = response.body.flat_map { |p| p['items'] }
page_frequency = all_pages.group_by(&:itself).transform_values(&:count)
common_pages = page_frequency.sort_by { |_, count| -count }.first(5)

puts "\nMost visited pages in checkout journeys:"
common_pages.each do |page, count|
  puts "  #{page}: appeared in #{count} journeys"
end
```

#### Use Cases for Journey Reports

**1. Site Architecture Optimization**
```ruby
# Discover how users naturally navigate your site
# Identify which pages are navigation hubs
# Find dead-end pages that need better links
```

**2. Content Strategy**
```ruby
# See which articles lead to others
# Identify content clusters users explore together
# Find topic progression patterns
```

**3. Conversion Path Discovery**
```ruby
# Find unexpected routes to conversion
# Identify which pages assist conversions
# Understand the research process
```

**4. UX Improvements**
```ruby
# Spot confusing navigation patterns
# Identify where users backtrack
# Find areas where users get lost
```

**5. Personalization Insights**
```ruby
# Compare mobile vs desktop journeys
# Understand geographic differences
# Identify segment-specific behaviors
```

### Executing Retention Reports

Retention reports measure website stickiness by tracking how often users return over time. Using cohort analysis, retention reports show return rates for users who first visited on specific dates, helping you understand engagement trends and user loyalty.

#### Basic Retention Analysis

```ruby
# Analyze 30-day retention
response = client.reports.retention(
  "website-id",
  Time.now - 30.days,
  Time.now,
  "UTC"
)

# Display key retention metrics
puts "Retention Analysis:"
[1, 7, 14, 30].each do |day|
  data = response.body.find { |d| d['day'] == day }
  if data
    puts "Day #{day}: #{data['percentage']}% returned (#{data['returnVisitors']} users)"
  end
end
```

#### Understanding Retention Data

The retention report returns cohort data showing:
- **date**: Cohort start date (when users first visited)
- **day**: Days elapsed since cohort formation (0, 1, 7, 14, 30, etc.)
- **visitors**: Initial cohort size (new users on that date)
- **returnVisitors**: Count of users who returned on that day
- **percentage**: Return rate (returnVisitors / visitors * 100)

#### Key Retention Milestones

```ruby
response = client.reports.retention(
  "website-id",
  Time.now - 90.days,
  Time.now,
  "UTC"
)

# Extract key milestones
day_1 = response.body.find { |d| d['day'] == 1 }
day_7 = response.body.find { |d| d['day'] == 7 }
day_30 = response.body.find { |d| d['day'] == 30 }
day_90 = response.body.find { |d| d['day'] == 90 }

puts "Key Retention Metrics:"
puts "  Day 1:  #{day_1['percentage']}% (first return)"
puts "  Day 7:  #{day_7['percentage']}% (weekly retention)"
puts "  Day 30: #{day_30['percentage']}% (monthly retention)"
puts "  Day 90: #{day_90['percentage']}% (quarterly retention)"
```

**Milestone Significance:**
- **Day 1**: First return rate - critical early engagement indicator
- **Day 7**: Weekly retention - shows early product stickiness
- **Day 30**: Monthly retention - indicates long-term engagement
- **Day 90**: Quarterly retention - measures product-market fit

#### Cohort Analysis

Group retention data by cohort to compare different time periods:

```ruby
response = client.reports.retention(
  "website-id",
  Time.now - 90.days,
  Time.now,
  "UTC"
)

# Group by cohort date
cohorts = response.body.group_by { |d| d['date'] }

puts "Cohort Comparison:"
cohorts.each do |date, data|
  initial_size = data.first['visitors']
  day_30_retention = data.find { |d| d['day'] == 30 }&.fetch('percentage', 0)

  puts "#{date}:"
  puts "  Initial users: #{initial_size}"
  puts "  Day-30 retention: #{day_30_retention}%"
end
```

#### Retention by Device

Compare retention across different devices:

```ruby
# Mobile retention
mobile_response = client.reports.retention(
  "website-id",
  Time.now - 30.days,
  Time.now,
  "UTC",
  filters: { device: "mobile" }
)

# Desktop retention
desktop_response = client.reports.retention(
  "website-id",
  Time.now - 30.days,
  Time.now,
  "UTC",
  filters: { device: "desktop" }
)

# Compare day-7 retention
mobile_day7 = mobile_response.body.find { |d| d['day'] == 7 }
desktop_day7 = desktop_response.body.find { |d| d['day'] == 7 }

puts "Day-7 Retention Comparison:"
puts "  Mobile:  #{mobile_day7['percentage']}%"
puts "  Desktop: #{desktop_day7['percentage']}%"
```

#### Geographic Retention Differences

```ruby
# US retention
us_response = client.reports.retention(
  "website-id",
  Time.now - 30.days,
  Time.now,
  "America/New_York",
  filters: { country: "US" }
)

# EU retention
eu_response = client.reports.retention(
  "website-id",
  Time.now - 30.days,
  Time.now,
  "Europe/London",
  filters: { country: "GB" }
)

# Compare
us_day30 = us_response.body.find { |d| d['day'] == 30 }['percentage']
eu_day30 = eu_response.body.find { |d| d['day'] == 30 }['percentage']

puts "Day-30 Retention by Region:"
puts "  US: #{us_day30}%"
puts "  EU: #{eu_day30}%"
```

#### Retention Curve Visualization

```ruby
response = client.reports.retention(
  "website-id",
  Time.now - 60.days,
  Time.now,
  "UTC"
)

# Calculate average retention for each day
days = response.body.map { |d| d['day'] }.uniq.sort
retention_curve = days.map do |day|
  day_data = response.body.select { |d| d['day'] == day }
  avg_retention = day_data.sum { |d| d['percentage'] } / day_data.length.to_f
  [day, avg_retention]
end

puts "Retention Curve:"
retention_curve.each do |day, retention|
  bars = "█" * (retention / 2).to_i  # Visual bar chart
  puts "Day #{day.to_s.rjust(2)}: #{bars} #{retention.round(1)}%"
end
```

#### Timezone Considerations

Always use the appropriate timezone for your user base:

```ruby
# US West Coast
client.reports.retention(website_id, start_date, end_date, "America/Los_Angeles")

# US East Coast
client.reports.retention(website_id, start_date, end_date, "America/New_York")

# Europe
client.reports.retention(website_id, start_date, end_date, "Europe/London")

# Asia
client.reports.retention(website_id, start_date, end_date, "Asia/Tokyo")

# UTC (global audience)
client.reports.retention(website_id, start_date, end_date, "UTC")
```

#### Retention Benchmarks by Industry

```ruby
response = client.reports.retention(
  website_id,
  Time.now - 30.days,
  Time.now,
  "UTC"
)

day_7_retention = response.body.find { |d| d['day'] == 7 }['percentage']
day_30_retention = response.body.find { |d| d['day'] == 30 }['percentage']

puts "Your Retention:"
puts "  Day 7:  #{day_7_retention}%"
puts "  Day 30: #{day_30_retention}%"

puts "\nIndustry Benchmarks:"
puts "  SaaS:       40%+ day-7, 20%+ day-30"
puts "  E-commerce: 20%+ day-7, 10%+ day-30"
puts "  Content:    30%+ day-7, 15%+ day-30"
puts "  Social:     50%+ day-7, 30%+ day-30"

# Evaluate performance
if day_7_retention >= 40
  puts "\n✓ Excellent day-7 retention!"
elsif day_7_retention >= 25
  puts "\n→ Good day-7 retention"
else
  puts "\n⚠ Day-7 retention needs improvement"
end
```

#### Complete Retention Analysis Example

```ruby
# Comprehensive retention analysis
start_date = Time.now - 90.days
end_date = Time.now

puts "Comprehensive Retention Analysis"
puts "=" * 50

# Overall retention
overall = client.reports.retention(
  website_id,
  start_date,
  end_date,
  "UTC"
)

# Segment by device
mobile = client.reports.retention(
  website_id, start_date, end_date, "UTC",
  filters: { device: "mobile" }
)

desktop = client.reports.retention(
  website_id, start_date, end_date, "UTC",
  filters: { device: "desktop" }
)

# Extract key metrics
def get_retention(response, day)
  data = response.body.find { |d| d['day'] == day }
  data ? data['percentage'] : 0
end

puts "\nOverall Retention:"
puts "  Day 1:  #{get_retention(overall, 1)}%"
puts "  Day 7:  #{get_retention(overall, 7)}%"
puts "  Day 30: #{get_retention(overall, 30)}%"
puts "  Day 90: #{get_retention(overall, 90)}%"

puts "\nMobile vs Desktop (Day-7):"
mobile_d7 = get_retention(mobile, 7)
desktop_d7 = get_retention(desktop, 7)
puts "  Mobile:  #{mobile_d7}%"
puts "  Desktop: #{desktop_d7}%"

# Calculate retention drop-off
day_1 = get_retention(overall, 1)
day_30 = get_retention(overall, 30)
dropoff = day_1 - day_30
puts "\nRetention Drop-off (Day 1 → Day 30):"
puts "  #{day_1}% → #{day_30}%"
puts "  Drop-off: #{dropoff.round(1)} percentage points"

# Analyze cohorts
cohorts = overall.body.group_by { |d| d['date'] }
recent_cohorts = cohorts.keys.sort.last(5)

puts "\nRecent Cohort Performance:"
recent_cohorts.each do |date|
  cohort_data = cohorts[date]
  size = cohort_data.first['visitors']
  d7 = cohort_data.find { |d| d['day'] == 7 }&.fetch('percentage', 0)
  puts "  #{date}: #{size} users, #{d7}% day-7 retention"
end

# Identify trends
retention_by_cohort = recent_cohorts.map do |date|
  cohort_data = cohorts[date]
  cohort_data.find { |d| d['day'] == 7 }&.fetch('percentage', 0)
end

if retention_by_cohort.last > retention_by_cohort.first
  puts "\n✓ Retention improving over time!"
else
  puts "\n⚠ Retention declining - investigate causes"
end

puts "\n" + "=" * 50
puts "Analysis complete"
```

#### Retention Improvement Strategies

Based on your retention data, consider these strategies:

**If Day-1 retention is low (<30%):**
```ruby
# Low day-1 suggests poor first impression
# - Improve onboarding experience
# - Add welcome emails/notifications
# - Highlight key features immediately
# - Reduce friction in first session
```

**If Day-7 retention drops significantly:**
```ruby
# Drop between day 1-7 suggests value not clear
# - Send engagement emails days 2-5
# - Add feature discovery prompts
# - Implement progress indicators
# - Create habit-forming loops
```

**If Day-30 retention is low:**
```ruby
# Low monthly retention suggests lack of long-term value
# - Add new content/features regularly
# - Implement notification system
# - Create user communities
# - Offer premium features
```

**If mobile retention < desktop:**
```ruby
# Mobile experience may need improvement
# - Optimize mobile UI/UX
# - Reduce mobile load times
# - Add push notifications
# - Improve mobile onboarding
```

### Executing Goal Reports

Goal reports track single conversion points like newsletter signups, demo requests, or important page visits. Unlike funnels (which track multi-step journeys), goals measure completion of one specific action independently, making them ideal for monitoring key conversion metrics.

#### Basic Goal Tracking

```ruby
# Track newsletter signup completions
response = client.reports.goals(
  "website-id",
  Time.now - 30.days,
  Time.now,
  "event",
  "newsletter_signup"
)

completions = response.body['num']
total = response.body['total']
rate = (completions.to_f / total * 100).round(2)

puts "Newsletter Signups:"
puts "  Completions: #{completions}"
puts "  Total events: #{total}"
puts "  Conversion rate: #{rate}%"
```

#### Goals vs Funnels

**Goals** track single conversion points:
- One specific action (page visit or event)
- Simple completion tracking
- Good for: KPI monitoring, conversion rates, A/B testing

**Funnels** track multi-step journeys:
- Sequential steps with drop-off analysis
- More complex user paths
- Good for: process optimization, identifying bottlenecks

#### Path-Based Goals

Track visits to important pages:

```ruby
# Thank you page (purchase confirmation)
response = client.reports.goals(
  "website-id",
  Time.now - 7.days,
  Time.now,
  "path",
  "/thank-you"
)

purchases = response.body['num']
puts "Purchases this week: #{purchases}"

# Pricing page visits
response = client.reports.goals(
  "website-id",
  Time.now - 30.days,
  Time.now,
  "path",
  "/pricing"
)

pricing_visits = response.body['num']
total_pageviews = response.body['total']
interest_rate = (pricing_visits.to_f / total_pageviews * 100).round(2)
puts "#{interest_rate}% of visitors viewed pricing"
```

#### Event-Based Goals

Track custom event completions:

```ruby
# Demo request goal
response = client.reports.goals(
  "website-id",
  Time.now - 30.days,
  Time.now,
  "event",
  "demo_request"
)

demos = response.body['num']
puts "Demo requests: #{demos}"

# Video play completions
response = client.reports.goals(
  "website-id",
  Time.now - 7.days,
  Time.now,
  "event",
  "video_play"
)

plays = response.body['num']
puts "Video plays: #{plays}"

# Add to cart events
response = client.reports.goals(
  "website-id",
  Time.now - 30.days,
  Time.now,
  "event",
  "add_to_cart"
)

cart_adds = response.body['num']
puts "Items added to cart: #{cart_adds}"
```

#### Segmented Goal Tracking

Filter goals by user segments:

```ruby
# US visitor conversions
us_response = client.reports.goals(
  "website-id",
  Time.now - 30.days,
  Time.now,
  "event",
  "purchase",
  filters: { country: "US" }
)

# EU visitor conversions
eu_response = client.reports.goals(
  "website-id",
  Time.now - 30.days,
  Time.now,
  "event",
  "purchase",
  filters: { country: "GB" }
)

us_purchases = us_response.body['num']
eu_purchases = eu_response.body['num']

puts "Purchases by Region:"
puts "  US: #{us_purchases}"
puts "  EU: #{eu_purchases}"
```

#### Mobile vs Desktop Goal Performance

```ruby
# Mobile conversions
mobile_response = client.reports.goals(
  "website-id",
  Time.now - 30.days,
  Time.now,
  "event",
  "signup",
  filters: { device: "mobile" }
)

# Desktop conversions
desktop_response = client.reports.goals(
  "website-id",
  Time.now - 30.days,
  Time.now,
  "event",
  "signup",
  filters: { device: "desktop" }
)

# Calculate conversion rates
mobile_conv = mobile_response.body['num']
mobile_total = mobile_response.body['total']
mobile_rate = (mobile_conv.to_f / mobile_total * 100).round(2)

desktop_conv = desktop_response.body['num']
desktop_total = desktop_response.body['total']
desktop_rate = (desktop_conv.to_f / desktop_total * 100).round(2)

puts "Signup Conversion Rates:"
puts "  Mobile:  #{mobile_rate}% (#{mobile_conv}/#{mobile_total})"
puts "  Desktop: #{desktop_rate}% (#{desktop_conv}/#{desktop_total})"

if mobile_rate > desktop_rate
  puts "  → Mobile converts better by #{(mobile_rate - desktop_rate).round(2)}%"
else
  puts "  → Desktop converts better by #{(desktop_rate - mobile_rate).round(2)}%"
end
```

#### Multiple Goal Tracking

Track several goals simultaneously:

```ruby
goals = [
  { name: "Signup", type: "event", value: "signup" },
  { name: "Purchase", type: "event", value: "purchase" },
  { name: "Newsletter", type: "event", value: "newsletter_signup" },
  { name: "Demo Request", type: "event", value: "demo_request" },
  { name: "Pricing Visit", type: "path", value: "/pricing" }
]

puts "Goal Performance (Last 30 Days):"
puts "=" * 50

goals.each do |goal|
  response = client.reports.goals(
    website_id,
    Time.now - 30.days,
    Time.now,
    goal[:type],
    goal[:value]
  )

  if response.success?
    completions = response.body['num']
    total = response.body['total']
    rate = (completions.to_f / total * 100).round(2)

    puts "\n#{goal[:name]}:"
    puts "  Completions: #{completions}"
    puts "  Conversion rate: #{rate}%"
  end
end
```

#### Weekly Goal Monitoring

```ruby
# Get last 4 weeks of data
weeks = 4.times.map do |i|
  start_date = Time.now - (i + 1).weeks
  end_date = Time.now - i.weeks

  response = client.reports.goals(
    website_id,
    start_date,
    end_date,
    "event",
    "signup"
  )

  {
    week: "Week #{4 - i}",
    completions: response.body['num'],
    rate: (response.body['num'].to_f / response.body['total'] * 100).round(2)
  }
end

puts "Weekly Signup Trends:"
weeks.reverse.each do |week|
  puts "  #{week[:week]}: #{week[:completions]} signups (#{week[:rate]}%)"
end

# Identify trend
if weeks.first[:completions] < weeks.last[:completions]
  puts "\n✓ Signups trending up!"
else
  puts "\n⚠ Signups declining"
end
```

#### Common Goal Patterns

**E-commerce Goals:**
```ruby
# Purchase completion
client.reports.goals(website_id, start_date, end_date, "event", "purchase")

# Add to cart
client.reports.goals(website_id, start_date, end_date, "event", "add_to_cart")

# Checkout started
client.reports.goals(website_id, start_date, end_date, "path", "/checkout")

# Thank you page
client.reports.goals(website_id, start_date, end_date, "path", "/thank-you")
```

**SaaS Goals:**
```ruby
# Trial signup
client.reports.goals(website_id, start_date, end_date, "event", "trial_start")

# Demo request
client.reports.goals(website_id, start_date, end_date, "event", "demo_request")

# Pricing page visit
client.reports.goals(website_id, start_date, end_date, "path", "/pricing")

# Payment added
client.reports.goals(website_id, start_date, end_date, "event", "payment_added")
```

**Content Goals:**
```ruby
# Newsletter signup
client.reports.goals(website_id, start_date, end_date, "event", "newsletter_signup")

# Article read (scroll to bottom)
client.reports.goals(website_id, start_date, end_date, "event", "article_complete")

# Social share
client.reports.goals(website_id, start_date, end_date, "event", "share")

# Comment posted
client.reports.goals(website_id, start_date, end_date, "event", "comment")
```

**Lead Generation Goals:**
```ruby
# Contact form submission
client.reports.goals(website_id, start_date, end_date, "event", "contact_form")

# Phone click
client.reports.goals(website_id, start_date, end_date, "event", "phone_click")

# Email click
client.reports.goals(website_id, start_date, end_date, "event", "email_click")

# Download whitepaper
client.reports.goals(website_id, start_date, end_date, "event", "download")
```

#### Goal Benchmarks by Industry

```ruby
response = client.reports.goals(
  website_id,
  Time.now - 30.days,
  Time.now,
  "event",
  "purchase"
)

conversion_rate = (response.body['num'].to_f / response.body['total'] * 100).round(2)

puts "Your Conversion Rate: #{conversion_rate}%"
puts "\nIndustry Benchmarks:"
puts "  E-commerce:     2-3% purchase conversion"
puts "  SaaS:           2-5% signup conversion"
puts "  Newsletter:     5-10% signup rate"
puts "  Demo requests:  1-3% conversion"
puts "  Lead gen forms: 10-15% submission rate"

# Evaluate performance
if conversion_rate >= 5
  puts "\n✓ Excellent conversion rate!"
elsif conversion_rate >= 2
  puts "\n→ Good conversion rate"
else
  puts "\n⚠ Conversion rate needs improvement"
end
```

#### Complete Goal Analysis Example

```ruby
# Comprehensive goal tracking dashboard
start_date = Time.now - 30.days
end_date = Time.now

puts "Conversion Goals Dashboard"
puts "=" * 50
puts "Period: #{start_date.strftime('%Y-%m-%d')} to #{end_date.strftime('%Y-%m-%d')}"

# Primary conversion goal
purchase_response = client.reports.goals(
  website_id, start_date, end_date, "event", "purchase"
)
purchases = purchase_response.body['num']
total_events = purchase_response.body['total']
purchase_rate = (purchases.to_f / total_events * 100).round(2)

puts "\nPrimary Goal: Purchases"
puts "  Total: #{purchases}"
puts "  Conversion rate: #{purchase_rate}%"

# Micro-conversions
micro_goals = [
  { name: "Product views", type: "path", value: "/product" },
  { name: "Add to cart", type: "event", value: "add_to_cart" },
  { name: "Checkout started", type: "path", value: "/checkout" }
]

puts "\nMicro-Conversions:"
micro_goals.each do |goal|
  response = client.reports.goals(
    website_id, start_date, end_date, goal[:type], goal[:value]
  )
  count = response.body['num']
  puts "  #{goal[:name]}: #{count}"
end

# Segment analysis
puts "\nSegment Analysis:"

segments = [
  { name: "Mobile", filter: { device: "mobile" } },
  { name: "Desktop", filter: { device: "desktop" } },
  { name: "US", filter: { country: "US" } },
  { name: "Organic", filter: { referrer: "google" } }
]

segments.each do |segment|
  response = client.reports.goals(
    website_id, start_date, end_date,
    "event", "purchase",
    filters: segment[:filter]
  )

  conv = response.body['num']
  total = response.body['total']
  rate = total > 0 ? (conv.to_f / total * 100).round(2) : 0

  puts "  #{segment[:name]}: #{conv} purchases (#{rate}%)"
end

# Calculate goal value (if applicable)
average_order_value = 99.99  # Your AOV
goal_value = purchases * average_order_value

puts "\n" + "=" * 50
puts "Summary:"
puts "  Total conversions: #{purchases}"
puts "  Conversion rate: #{purchase_rate}%"
puts "  Goal value: $#{goal_value.round(2)}"
puts "  Value per visitor: $#{(goal_value / total_events).round(2)}"
```

#### Goal Optimization Tips

**If conversion rate is low:**
```ruby
# - Simplify the conversion process
# - Improve call-to-action visibility
# - Reduce form fields
# - Add trust signals (testimonials, badges)
# - Optimize page load speed
# - A/B test different approaches
```

**To track goal effectiveness:**
```ruby
# Monitor weekly trends
# Compare segments (mobile vs desktop)
# Test different traffic sources
# Analyze drop-off points
# Calculate goal value
# Set up alerts for significant changes
```

**Multi-goal strategy:**
```ruby
# Primary goal: Final conversion (purchase, signup)
# Secondary goals: Micro-conversions (cart, pricing page)
# Engagement goals: Content interactions (video, scroll)
# Lead goals: Contact form, demo request
```

### Executing Attribution Reports

Attribution reports analyze marketing channel performance by showing which sources drive conversions. Using attribution models (first-click or last-click), these reports credit conversion sources and reveal which channels bring traffic that actually converts.

#### Understanding Attribution Models

**First-Click Attribution:**
- Credits the first touchpoint in the user journey
- Shows which channels bring initial awareness
- Good for: Top-of-funnel optimization, brand awareness campaigns

**Last-Click Attribution:**
- Credits the final touchpoint before conversion
- Shows which channels close the deal
- Good for: Bottom-of-funnel optimization, direct response campaigns

#### Basic Attribution Analysis

```ruby
# First-click attribution for purchases
response = client.reports.attribution(
  "website-id",
  Time.now - 30.days,
  Time.now,
  "firstClick",
  "event",
  "purchase"
)

# Analyze top referrers
puts "Top Referrers (First-Click):"
response.body['referrer']&.each do |source|
  puts "  #{source['name']}: #{source['value']} conversions"
end

# Analyze UTM sources
puts "\nTop UTM Sources:"
response.body['utm_source']&.each do |source|
  puts "  #{source['name']}: #{source['value']} conversions"
end

# Show totals
total = response.body['total']
puts "\nTotal: #{total['visitors']} visitors, #{total['pageviews']} pageviews"
```

#### Attribution Response Structure

The response includes attribution data across multiple channels:

```ruby
{
  'referrer' => [        # Traffic sources (websites, search engines)
    { 'name' => 'google', 'value' => 150 },
    { 'name' => 'direct', 'value' => 89 }
  ],
  'paidAds' => [         # Paid advertising performance
    { 'name' => 'google-ads', 'value' => 45 }
  ],
  'utm_source' => [      # Campaign source (google, facebook, newsletter)
    { 'name' => 'facebook', 'value' => 67 }
  ],
  'utm_medium' => [      # Campaign medium (cpc, email, social)
    { 'name' => 'cpc', 'value' => 120 }
  ],
  'utm_campaign' => [    # Campaign name
    { 'name' => 'summer-sale', 'value' => 89 }
  ],
  'utm_content' => [     # Ad variation
    { 'name' => 'banner-a', 'value' => 34 }
  ],
  'utm_term' => [        # Keyword (for paid search)
    { 'name' => 'buy shoes', 'value' => 12 }
  ],
  'total' => {           # Aggregate metrics
    'visitors' => 1234,
    'visits' => 2456,
    'pageviews' => 5678
  }
}
```

#### Comparing Attribution Models

```ruby
# First-click attribution
first_click = client.reports.attribution(
  "website-id",
  Time.now - 30.days,
  Time.now,
  "firstClick",
  "event",
  "purchase"
)

# Last-click attribution
last_click = client.reports.attribution(
  "website-id",
  Time.now - 30.days,
  Time.now,
  "lastClick",
  "event",
  "purchase"
)

puts "Attribution Model Comparison:"
puts "\nFirst-Click (Initial awareness):"
first_click.body['referrer'].first(5).each do |source|
  puts "  #{source['name']}: #{source['value']}"
end

puts "\nLast-Click (Final touchpoint):"
last_click.body['referrer'].first(5).each do |source|
  puts "  #{source['name']}: #{source['value']}"
end

# Insights from differences
# - Sources appearing in first-click but not last-click are good for awareness
# - Sources appearing in last-click but not first-click are good for closing
# - Sources appearing in both are valuable throughout the journey
```

#### UTM Campaign Attribution

```ruby
response = client.reports.attribution(
  "website-id",
  Time.now - 30.days,
  Time.now,
  "lastClick",
  "event",
  "purchase"
)

puts "UTM Campaign Performance:"
puts "\nSources:"
response.body['utm_source']&.each do |source|
  puts "  #{source['name']}: #{source['value']} conversions"
end

puts "\nMediums:"
response.body['utm_medium']&.each do |medium|
  puts "  #{medium['name']}: #{medium['value']} conversions"
end

puts "\nCampaigns:"
response.body['utm_campaign']&.each do |campaign|
  puts "  #{campaign['name']}: #{campaign['value']} conversions"
end

# Calculate ROI if you have campaign costs
campaign_cost = 5000  # Your campaign budget
conversions = response.body['utm_campaign'].first['value']
avg_order_value = 99.99
revenue = conversions * avg_order_value
roi = ((revenue - campaign_cost) / campaign_cost * 100).round(2)

puts "\nCampaign ROI: #{roi}%"
```

#### Paid Advertising Attribution

```ruby
response = client.reports.attribution(
  "website-id",
  Time.now - 30.days,
  Time.now,
  "lastClick",
  "event",
  "purchase"
)

if response.body['paidAds'] && response.body['paidAds'].any?
  puts "Paid Advertising Performance:"
  response.body['paidAds'].each do |ad|
    puts "  #{ad['name']}: #{ad['value']} conversions"
  end

  # Calculate paid ads conversion rate
  total_visitors = response.body['total']['visitors']
  paid_conversions = response.body['paidAds'].sum { |ad| ad['value'] }
  conversion_rate = (paid_conversions.to_f / total_visitors * 100).round(2)

  puts "\nPaid Ads Conversion Rate: #{conversion_rate}%"
else
  puts "No paid advertising data available"
end
```

#### Segmented Attribution

Filter attribution by user segments:

```ruby
# Mobile attribution
mobile_response = client.reports.attribution(
  "website-id",
  Time.now - 30.days,
  Time.now,
  "firstClick",
  "event",
  "purchase",
  filters: { device: "mobile" }
)

# Desktop attribution
desktop_response = client.reports.attribution(
  "website-id",
  Time.now - 30.days,
  Time.now,
  "firstClick",
  "event",
  "purchase",
  filters: { device: "desktop" }
)

puts "Attribution by Device:"
puts "\nMobile Top Sources:"
mobile_response.body['referrer'].first(3).each do |source|
  puts "  #{source['name']}: #{source['value']}"
end

puts "\nDesktop Top Sources:"
desktop_response.body['referrer'].first(3).each do |source|
  puts "  #{source['name']}: #{source['value']}"
end
```

#### Geographic Attribution

```ruby
# US attribution
us_response = client.reports.attribution(
  "website-id",
  Time.now - 30.days,
  Time.now,
  "lastClick",
  "event",
  "signup",
  filters: { country: "US" }
)

# EU attribution
eu_response = client.reports.attribution(
  "website-id",
  Time.now - 30.days,
  Time.now,
  "lastClick",
  "event",
  "signup",
  filters: { country: "GB" }
)

puts "Geographic Attribution:"
puts "\nUS UTM Sources:"
us_response.body['utm_source']&.first(3)&.each do |source|
  puts "  #{source['name']}: #{source['value']}"
end

puts "\nEU UTM Sources:"
eu_response.body['utm_source']&.first(3)&.each do |source|
  puts "  #{source['name']}: #{source['value']}"
end
```

#### Complete Attribution Dashboard

```ruby
# Comprehensive attribution analysis
start_date = Time.now - 30.days
end_date = Time.now

puts "Marketing Attribution Dashboard"
puts "=" * 50
puts "Period: #{start_date.strftime('%Y-%m-%d')} to #{end_date.strftime('%Y-%m-%d')}"

# Get attribution data
response = client.reports.attribution(
  website_id,
  start_date,
  end_date,
  "lastClick",
  "event",
  "purchase"
)

# Traffic Sources
puts "\nTop Traffic Sources:"
response.body['referrer']&.first(10)&.each_with_index do |source, index|
  puts "  #{index + 1}. #{source['name']}: #{source['value']} conversions"
end

# UTM Analysis
puts "\nUTM Source Performance:"
response.body['utm_source']&.first(5)&.each do |source|
  puts "  #{source['name']}: #{source['value']} conversions"
end

puts "\nUTM Medium Performance:"
response.body['utm_medium']&.first(5)&.each do |medium|
  puts "  #{medium['name']}: #{medium['value']} conversions"
end

puts "\nTop Campaigns:"
response.body['utm_campaign']&.first(5)&.each do |campaign|
  puts "  #{campaign['name']}: #{campaign['value']} conversions"
end

# Paid vs Organic
paid_conversions = response.body['paidAds']&.sum { |ad| ad['value'] } || 0
total_conversions = response.body['total']['visitors']
organic_conversions = total_conversions - paid_conversions

puts "\n" + "=" * 50
puts "Conversion Split:"
puts "  Organic: #{organic_conversions} (#{(organic_conversions.to_f / total_conversions * 100).round(1)}%)"
puts "  Paid: #{paid_conversions} (#{(paid_conversions.to_f / total_conversions * 100).round(1)}%)"

# Calculate channel efficiency
puts "\nChannel Efficiency:"
response.body['utm_source']&.first(5)&.each do |source|
  efficiency = (source['value'].to_f / total_conversions * 100).round(2)
  puts "  #{source['name']}: #{efficiency}% of all conversions"
end
```

#### Marketing ROI Calculation

```ruby
response = client.reports.attribution(
  website_id,
  Time.now - 30.days,
  Time.now,
  "lastClick",
  "event",
  "purchase"
)

# Define campaign costs and metrics
campaign_data = {
  'google' => { cost: 5000, aov: 99.99 },
  'facebook' => { cost: 3000, aov: 89.99 },
  'newsletter' => { cost: 500, aov: 79.99 }
}

puts "Marketing ROI Analysis:"
puts "=" * 50

response.body['utm_source']&.each do |source|
  if campaign_data[source['name']]
    conversions = source['value']
    cost = campaign_data[source['name']][:cost]
    aov = campaign_data[source['name']][:aov]

    revenue = conversions * aov
    profit = revenue - cost
    roi = ((profit / cost) * 100).round(2)
    cpa = (cost.to_f / conversions).round(2)

    puts "\n#{source['name'].capitalize}:"
    puts "  Conversions: #{conversions}"
    puts "  Cost: $#{cost}"
    puts "  Revenue: $#{revenue.round(2)}"
    puts "  Profit: $#{profit.round(2)}"
    puts "  ROI: #{roi}%"
    puts "  CPA: $#{cpa}"
  end
end
```

#### Attribution Best Practices

**Use first-click attribution to:**
```ruby
# - Identify awareness-building channels
# - Optimize top-of-funnel campaigns
# - Allocate budget to customer acquisition sources
# - Understand brand discovery patterns
```

**Use last-click attribution to:**
```ruby
# - Identify conversion-driving channels
# - Optimize bottom-of-funnel campaigns
# - Reward channels that close sales
# - Understand decision-making triggers
```

**Compare both models to:**
```ruby
# - Get complete journey visibility
# - Identify assist vs. close channels
# - Optimize multi-touch campaigns
# - Balance awareness and conversion spending
```

#### Common Attribution Patterns

**B2C E-commerce:**
```ruby
# First-click: Social media, display ads, content
# Last-click: Google search, email, retargeting
# Strategy: Use social for awareness, search for conversion
```

**B2B SaaS:**
```ruby
# First-click: LinkedIn, content marketing, webinars
# Last-click: Direct, email, sales outreach
# Strategy: Content for awareness, direct contact for conversion
```

**Content Sites:**
```ruby
# First-click: Social media, search engines, aggregators
# Last-click: Direct, bookmarks, newsletters
# Strategy: SEO for discovery, email for retention
```

## Executing Breakdown Reports

Breakdown reports segment your data by one or more dimensions, allowing you to analyze metrics across different combinations of properties like country, device, browser, operating system, and more.

### Basic Usage

```ruby
# Single dimension breakdown - Operating System
response = client.reports.breakdown(
  website_id,
  start_date,
  end_date,
  ['os']
)

response.data.each do |record|
  puts "#{record['os']}: #{record['views']} views, #{record['visitors']} visitors"
end
# Windows: 1,250 views, 450 visitors
# macOS: 890 views, 320 visitors
# Linux: 340 views, 145 visitors
```

### Available Dimensions

Breakdown reports support the following dimensions:

```ruby
# Traffic dimensions
['path']        # Page URLs
['title']       # Page titles
['referrer']    # Traffic sources
['query']       # URL query parameters
['hostname']    # Domain names

# Technology dimensions
['browser']     # Web browsers
['os']          # Operating systems
['device']      # Device types (desktop, mobile, tablet)

# Geography dimensions
['country']     # Countries
['region']      # States/provinces
['city']        # Cities

# Custom dimensions
['tag']         # Custom tags
['event']       # Custom events
```

### Single Dimension Breakdowns

**Device Analysis:**
```ruby
response = client.reports.breakdown(
  website_id,
  start_date,
  end_date,
  ['device']
)

response.data.each do |record|
  device = record['device']
  views = record['views']
  visitors = record['visitors']
  bounce_rate = (record['bounces'].to_f / record['visits'] * 100).round(1)
  avg_time = (record['totaltime'].to_f / record['visits']).round(0)

  puts "#{device.capitalize}:"
  puts "  Views: #{views}"
  puts "  Visitors: #{visitors}"
  puts "  Bounce Rate: #{bounce_rate}%"
  puts "  Avg Time: #{avg_time}s"
end
# Desktop:
#   Views: 5,240
#   Visitors: 1,890
#   Bounce Rate: 42.3%
#   Avg Time: 185s
# Mobile:
#   Views: 3,120
#   Visitors: 1,450
#   Bounce Rate: 58.7%
#   Avg Time: 92s
```

**Geographic Analysis:**
```ruby
response = client.reports.breakdown(
  website_id,
  start_date,
  end_date,
  ['country']
)

# Top 10 countries by traffic
top_countries = response.data
  .sort_by { |r| -r['views'] }
  .take(10)

top_countries.each_with_index do |record, index|
  puts "#{index + 1}. #{record['country']}: #{record['views']} views (#{record['visitors']} visitors)"
end
# 1. US: 4,230 views (1,890 visitors)
# 2. GB: 1,450 views (670 visitors)
# 3. DE: 980 views (420 visitors)
```

**Browser Analysis:**
```ruby
response = client.reports.breakdown(
  website_id,
  start_date,
  end_date,
  ['browser']
)

total_views = response.data.sum { |r| r['views'] }

response.data.each do |record|
  browser = record['browser']
  views = record['views']
  percentage = (views.to_f / total_views * 100).round(1)

  puts "#{browser}: #{views} views (#{percentage}%)"
end
# Chrome: 4,580 views (52.3%)
# Safari: 2,340 views (26.7%)
# Firefox: 1,120 views (12.8%)
# Edge: 710 views (8.1%)
```

**Page Performance:**
```ruby
response = client.reports.breakdown(
  website_id,
  start_date,
  end_date,
  ['path']
)

# Analyze page performance
response.data.each do |record|
  path = record['path']
  visits = record['visits']
  bounce_rate = (record['bounces'].to_f / visits * 100).round(1)
  avg_time = (record['totaltime'].to_f / visits).round(0)

  puts "#{path}:"
  puts "  Visits: #{visits}"
  puts "  Bounce Rate: #{bounce_rate}%"
  puts "  Avg Time on Page: #{avg_time}s"
end
# /blog/getting-started:
#   Visits: 1,450
#   Bounce Rate: 35.2%
#   Avg Time on Page: 245s
# /pricing:
#   Visits: 890
#   Bounce Rate: 52.1%
#   Avg Time on Page: 78s
```

### Multi-Dimension Breakdowns

**Technology Stack Analysis:**
```ruby
# OS + Browser combinations
response = client.reports.breakdown(
  website_id,
  start_date,
  end_date,
  ['os', 'browser']
)

# Group by OS
by_os = response.data.group_by { |r| r['os'] }

by_os.each do |os, records|
  puts "\n#{os}:"
  records.sort_by { |r| -r['views'] }.take(3).each do |record|
    puts "  #{record['browser']}: #{record['views']} views"
  end
end
# Windows:
#   Chrome: 1,890 views
#   Edge: 710 views
#   Firefox: 450 views
# macOS:
#   Safari: 1,240 views
#   Chrome: 890 views
#   Firefox: 120 views
```

**Geographic + Device Analysis:**
```ruby
response = client.reports.breakdown(
  website_id,
  start_date,
  end_date,
  ['country', 'device']
)

# Find mobile adoption by country
by_country = response.data.group_by { |r| r['country'] }

by_country.each do |country, records|
  total = records.sum { |r| r['views'] }
  mobile = records.find { |r| r['device'] == 'mobile' }&.dig('views') || 0
  mobile_pct = (mobile.to_f / total * 100).round(1)

  puts "#{country}: #{mobile_pct}% mobile (#{mobile}/#{total} views)"
end
# US: 32.4% mobile (1,370/4,230 views)
# GB: 45.2% mobile (655/1,450 views)
# IN: 78.9% mobile (1,890/2,395 views)
```

**Traffic Source + Landing Page:**
```ruby
response = client.reports.breakdown(
  website_id,
  start_date,
  end_date,
  ['referrer', 'path']
)

# Analyze which referrers drive traffic to which pages
by_referrer = response.data.group_by { |r| r['referrer'] }

by_referrer.each do |referrer, records|
  ref_display = referrer.empty? ? '(direct)' : referrer
  puts "\nFrom #{ref_display}:"

  records.sort_by { |r| -r['views'] }.take(3).each do |record|
    puts "  → #{record['path']}: #{record['views']} views"
  end
end
# From google.com:
#   → /blog: 890 views
#   → /docs: 450 views
#   → /: 340 views
# From (direct):
#   → /: 1,240 views
#   → /dashboard: 670 views
```

**Three-Dimension Analysis:**
```ruby
# Country + OS + Device
response = client.reports.breakdown(
  website_id,
  start_date,
  end_date,
  ['country', 'os', 'device']
)

# Find most common configurations
top_configs = response.data
  .sort_by { |r| -r['views'] }
  .take(10)

puts "Top 10 Configuration Combinations:"
top_configs.each_with_index do |record, index|
  config = "#{record['country']} / #{record['os']} / #{record['device']}"
  puts "#{index + 1}. #{config}: #{record['views']} views"
end
# Top 10 Configuration Combinations:
# 1. US / Windows / desktop: 1,450 views
# 2. US / iOS / mobile: 890 views
# 3. GB / Windows / desktop: 670 views
# 4. US / macOS / desktop: 560 views
```

### Filtered Breakdowns

**Mobile-Only Analysis:**
```ruby
# Analyze mobile users only
response = client.reports.breakdown(
  website_id,
  start_date,
  end_date,
  ['os', 'browser'],
  filters: [
    { type: 'device', value: 'mobile' }
  ]
)

puts "Mobile Browser Usage:"
response.data.each do |record|
  puts "#{record['os']} - #{record['browser']}: #{record['views']} views"
end
# Mobile Browser Usage:
# iOS - Safari: 1,240 views
# Android - Chrome: 1,890 views
# iOS - Chrome: 340 views
```

**Country-Specific Analysis:**
```ruby
# Analyze US traffic only
response = client.reports.breakdown(
  website_id,
  start_date,
  end_date,
  ['device', 'os'],
  filters: [
    { type: 'country', value: 'US' }
  ]
)

puts "US Device Usage:"
by_device = response.data.group_by { |r| r['device'] }

by_device.each do |device, records|
  puts "\n#{device.capitalize}:"
  records.each do |record|
    puts "  #{record['os']}: #{record['views']} views"
  end
end
# US Device Usage:
# Desktop:
#   Windows: 1,450 views
#   macOS: 890 views
# Mobile:
#   iOS: 670 views
#   Android: 450 views
```

**Specific Page Analysis:**
```ruby
# Analyze who visits a specific page
response = client.reports.breakdown(
  website_id,
  start_date,
  end_date,
  ['country', 'device'],
  filters: [
    { type: 'path', value: '/pricing' }
  ]
)

puts "Pricing Page Visitors:"
response.data.each do |record|
  puts "#{record['country']} (#{record['device']}): #{record['visitors']} visitors"
end
```

### Advanced Analysis Patterns

**Engagement Segmentation:**
```ruby
response = client.reports.breakdown(
  website_id,
  start_date,
  end_date,
  ['country', 'device']
)

# Segment by engagement quality
high_engagement = []
medium_engagement = []
low_engagement = []

response.data.each do |record|
  visits = record['visits']
  next if visits == 0

  bounce_rate = (record['bounces'].to_f / visits * 100).round(1)
  avg_time = (record['totaltime'].to_f / visits).round(0)

  engagement_score = (100 - bounce_rate) + (avg_time / 10.0)

  segment = {
    country: record['country'],
    device: record['device'],
    views: record['views'],
    bounce_rate: bounce_rate,
    avg_time: avg_time,
    score: engagement_score.round(1)
  }

  if engagement_score >= 80
    high_engagement << segment
  elsif engagement_score >= 50
    medium_engagement << segment
  else
    low_engagement << segment
  end
end

puts "High Engagement Segments:"
high_engagement.sort_by { |s| -s[:score] }.take(5).each do |seg|
  puts "  #{seg[:country]} / #{seg[:device]}: #{seg[:score]} score"
  puts "    (#{seg[:bounce_rate]}% bounce, #{seg[:avg_time]}s avg time)"
end
# High Engagement Segments:
#   US / desktop: 92.3 score
#     (35.2% bounce, 274s avg time)
#   GB / desktop: 87.5 score
#     (38.9% bounce, 245s avg time)
```

**Market Opportunity Analysis:**
```ruby
response = client.reports.breakdown(
  website_id,
  start_date,
  end_date,
  ['country']
)

# Calculate market metrics
response.data.each do |record|
  country = record['country']
  visitors = record['visitors']
  visits = record['visits']
  views = record['views']

  return_rate = (visits.to_f / visitors * 100).round(1)
  pages_per_visit = (views.to_f / visits).round(1)

  # Market maturity indicator
  maturity = if return_rate > 150 && pages_per_visit > 3
    'Mature'
  elsif return_rate > 120 || pages_per_visit > 2.5
    'Growing'
  else
    'New'
  end

  puts "#{country}: #{maturity} market"
  puts "  Visitors: #{visitors}"
  puts "  Return Rate: #{return_rate}%"
  puts "  Pages/Visit: #{pages_per_visit}"
  puts
end
# US: Mature market
#   Visitors: 1,890
#   Return Rate: 178.4%
#   Pages/Visit: 3.8
# IN: New market
#   Visitors: 450
#   Return Rate: 105.2%
#   Pages/Visit: 1.9
```

**Content Performance by Source:**
```ruby
response = client.reports.breakdown(
  website_id,
  start_date,
  end_date,
  ['referrer', 'path']
)

# Analyze which sources drive best content engagement
by_path = response.data.group_by { |r| r['path'] }

by_path.each do |path, records|
  puts "\n#{path}:"

  total_views = records.sum { |r| r['views'] }

  # Top 3 sources for this page
  top_sources = records
    .sort_by { |r| -r['views'] }
    .take(3)

  top_sources.each do |record|
    referrer = record['referrer'].empty? ? '(direct)' : record['referrer']
    views = record['views']
    percentage = (views.to_f / total_views * 100).round(1)

    puts "  #{referrer}: #{views} views (#{percentage}%)"
  end
end
# /blog/getting-started:
#   google.com: 890 views (45.2%)
#   (direct): 450 views (22.9%)
#   twitter.com: 340 views (17.3%)
```

**Cross-Platform Analysis:**
```ruby
response = client.reports.breakdown(
  website_id,
  start_date,
  end_date,
  ['os', 'browser', 'device']
)

# Analyze platform-specific behaviors
platforms = {
  'Windows Desktop' => [],
  'Mac Desktop' => [],
  'iOS Mobile' => [],
  'Android Mobile' => []
}

response.data.each do |record|
  os = record['os']
  device = record['device']
  visits = record['visits']

  next if visits == 0

  avg_time = (record['totaltime'].to_f / visits).round(0)
  bounce_rate = (record['bounces'].to_f / visits * 100).round(1)

  key = case
  when os == 'Windows' && device == 'desktop'
    'Windows Desktop'
  when os == 'macOS' && device == 'desktop'
    'Mac Desktop'
  when os == 'iOS' && device == 'mobile'
    'iOS Mobile'
  when os == 'Android' && device == 'mobile'
    'Android Mobile'
  else
    next
  end

  platforms[key] << {
    browser: record['browser'],
    views: record['views'],
    avg_time: avg_time,
    bounce_rate: bounce_rate
  }
end

platforms.each do |platform, data|
  next if data.empty?

  total_views = data.sum { |d| d[:views] }
  weighted_avg_time = data.sum { |d| d[:views] * d[:avg_time] } / total_views
  weighted_bounce = data.sum { |d| d[:views] * d[:bounce_rate] } / total_views

  puts "\n#{platform}:"
  puts "  Views: #{total_views}"
  puts "  Avg Time: #{weighted_avg_time.round(0)}s"
  puts "  Bounce Rate: #{weighted_bounce.round(1)}%"
end
# Windows Desktop:
#   Views: 3,450
#   Avg Time: 198s
#   Bounce Rate: 41.2%
# Mac Desktop:
#   Views: 1,890
#   Avg Time: 245s
#   Bounce Rate: 35.8%
# iOS Mobile:
#   Views: 1,340
#   Avg Time: 92s
#   Bounce Rate: 58.3%
```

### Business Intelligence Use Cases

**1. Browser Compatibility Testing Priority:**
```ruby
response = client.reports.breakdown(
  website_id,
  start_date,
  end_date,
  ['browser', 'os']
)

# Identify test configurations by importance
test_matrix = response.data
  .sort_by { |r| -r['views'] }
  .take(10)

puts "Priority Test Matrix:"
test_matrix.each_with_index do |record, index|
  puts "#{index + 1}. #{record['browser']} on #{record['os']}: #{record['views']} views (#{record['visitors']} users)"
end
# Priority Test Matrix:
# 1. Chrome on Windows: 1,890 views (780 users)
# 2. Safari on macOS: 1,240 views (540 users)
# 3. Chrome on macOS: 890 views (380 users)
```

**2. Localization Priority:**
```ruby
response = client.reports.breakdown(
  website_id,
  start_date,
  end_date,
  ['country']
)

# Calculate localization ROI potential
localization_candidates = response.data
  .select { |r| r['visitors'] > 100 }  # Meaningful volume
  .map do |record|
    visitors = record['visitors']
    visits = record['visits']
    return_rate = (visits.to_f / visitors).round(2)

    {
      country: record['country'],
      visitors: visitors,
      return_rate: return_rate,
      potential: (visitors * return_rate).round(0)  # Engagement potential
    }
  end
  .sort_by { |c| -c[:potential] }

puts "Localization Priority (by engagement potential):"
localization_candidates.take(5).each_with_index do |candidate, index|
  puts "#{index + 1}. #{candidate[:country]}: #{candidate[:visitors]} visitors, #{candidate[:return_rate]}x return"
end
# Localization Priority (by engagement potential):
# 1. US: 1,890 visitors, 1.78x return
# 2. GB: 670 visitors, 1.45x return
# 3. DE: 420 visitors, 1.32x return
```

**3. Mobile Optimization Priority:**
```ruby
response = client.reports.breakdown(
  website_id,
  start_date,
  end_date,
  ['device', 'path']
)

# Find pages with high mobile traffic but poor performance
mobile_data = response.data.select { |r| r['device'] == 'mobile' }

problem_pages = mobile_data.map do |record|
  visits = record['visits']
  next if visits == 0

  bounce_rate = (record['bounces'].to_f / visits * 100).round(1)
  avg_time = (record['totaltime'].to_f / visits).round(0)

  # High traffic but poor engagement
  if record['views'] > 100 && (bounce_rate > 60 || avg_time < 30)
    {
      path: record['path'],
      views: record['views'],
      bounce_rate: bounce_rate,
      avg_time: avg_time,
      priority: record['views'] * bounce_rate  # Weighted priority
    }
  end
end.compact.sort_by { |p| -p[:priority] }

puts "Mobile Optimization Priorities:"
problem_pages.take(5).each do |page|
  puts "#{page[:path]}:"
  puts "  #{page[:views]} views, #{page[:bounce_rate]}% bounce, #{page[:avg_time]}s avg time"
end
```

**4. Feature Adoption by Segment:**
```ruby
# Track specific feature usage across segments
response = client.reports.breakdown(
  website_id,
  start_date,
  end_date,
  ['country', 'device'],
  filters: [
    { type: 'path', value: '/dashboard/advanced-features' }
  ]
)

total_response = client.reports.breakdown(
  website_id,
  start_date,
  end_date,
  ['country', 'device']
)

# Calculate adoption rate by segment
by_segment = total_response.data.each_with_object({}) do |record, hash|
  key = "#{record['country']}/#{record['device']}"
  hash[key] = record['visitors']
end

puts "Feature Adoption by Segment:"
response.data.each do |record|
  key = "#{record['country']}/#{record['device']}"
  feature_users = record['visitors']
  total_users = by_segment[key] || 1

  adoption_rate = (feature_users.to_f / total_users * 100).round(1)

  puts "#{record['country']} / #{record['device']}: #{adoption_rate}% adoption (#{feature_users}/#{total_users})"
end
# Feature Adoption by Segment:
# US / desktop: 12.3% adoption (232/1,890)
# US / mobile: 3.4% adoption (23/670)
# GB / desktop: 8.7% adoption (58/670)
```

### Industry Benchmarks

**Bounce Rates by Device:**
```ruby
# Content sites: Desktop 40-60%, Mobile 60-75%
# E-commerce: Desktop 35-50%, Mobile 50-65%
# SaaS: Desktop 30-45%, Mobile 45-60%
```

**Pages per Visit by Device:**
```ruby
# Desktop: 3-5 pages typically
# Mobile: 2-3 pages typically
# Tablet: 2.5-4 pages typically
```

**Geographic Engagement:**
```ruby
# Mature markets (US, GB, DE): Higher page depth, lower bounce
# Growing markets (BR, MX, IN): Lower page depth, higher bounce initially
# Consider localization when traffic > 500 visitors/month from market
```

## Executing Revenue Reports

Revenue reports enable tracking and analysis of financial data associated with user conversions and transactions. They provide time-series data, geographic distribution, and aggregate statistics including sum, count, unique visitors, and average transaction value.

### Basic Usage

```ruby
# Basic revenue report
response = client.reports.revenue(
  website_id,
  start_date,
  end_date,
  "America/New_York",
  "USD"
)

# Aggregate totals
totals = response.data['total']
puts "Total Revenue: $#{totals['sum']}"
puts "Transactions: #{totals['count']}"
puts "Unique Customers: #{totals['unique_count']}"
puts "Average Order Value: $#{totals['average'].round(2)}"
# Total Revenue: $45,230
# Transactions: 1,234
# Unique Customers: 1,189
# Average Order Value: $36.65
```

### Response Structure

Revenue reports return three key data sections:

```ruby
response = client.reports.revenue(website_id, start_date, end_date, timezone, currency)

# 1. Chart - Time-series revenue data
response.data['chart'].each do |point|
  date = Time.parse(point['t']).strftime('%Y-%m-%d')
  puts "#{date}: $#{point['y']}"
end
# 2025-10-14: $1,450
# 2025-10-15: $2,340
# 2025-10-16: $1,890

# 2. Country - Geographic distribution
response.data['country'].each do |country|
  puts "#{country['name']}: $#{country['value']}"
end
# US: $25,340
# GB: $12,450
# DE: $7,440

# 3. Total - Aggregate statistics
totals = response.data['total']
# sum: Total revenue
# count: Number of transactions
# unique_count: Number of unique customers
# average: Average order value
```

### Currency Support

Revenue reports support any ISO 4217 currency code:

```ruby
# US Dollars
response = client.reports.revenue(
  website_id,
  start_date,
  end_date,
  "America/New_York",
  "USD"
)

# Euros
response = client.reports.revenue(
  website_id,
  start_date,
  end_date,
  "Europe/Paris",
  "EUR"
)

# British Pounds
response = client.reports.revenue(
  website_id,
  start_date,
  end_date,
  "Europe/London",
  "GBP"
)

# Japanese Yen
response = client.reports.revenue(
  website_id,
  start_date,
  end_date,
  "Asia/Tokyo",
  "JPY"
)
```

### Time-Series Analysis

```ruby
# Last 30 days revenue trend
start_date = (Time.now - (30 * 24 * 60 * 60)).utc.iso8601(3)
end_date = Time.now.utc.iso8601(3)

response = client.reports.revenue(
  website_id,
  start_date,
  end_date,
  "UTC",
  "USD"
)

# Calculate daily statistics
revenues = response.data['chart'].map { |p| p['y'] }
avg_daily = revenues.sum.to_f / revenues.length
max_daily = revenues.max
min_daily = revenues.min

puts "Daily Statistics (30 days):"
puts "  Average: $#{avg_daily.round(2)}"
puts "  Maximum: $#{max_daily}"
puts "  Minimum: $#{min_daily}"
puts "  Total: $#{revenues.sum}"
# Daily Statistics (30 days):
#   Average: $1,507.67
#   Maximum: $3,450
#   Minimum: $890
#   Total: $45,230

# Identify best and worst days
chart_data = response.data['chart'].map do |point|
  { date: Time.parse(point['t']), revenue: point['y'] }
end

best_day = chart_data.max_by { |d| d[:revenue] }
worst_day = chart_data.min_by { |d| d[:revenue] }

puts "\nBest Day: #{best_day[:date].strftime('%A, %B %d')}: $#{best_day[:revenue]}"
puts "Worst Day: #{worst_day[:date].strftime('%A, %B %d')}: $#{worst_day[:revenue]}"
# Best Day: Saturday, October 14: $3,450
# Worst Day: Tuesday, October 3: $890
```

### Geographic Revenue Analysis

```ruby
response = client.reports.revenue(
  website_id,
  start_date,
  end_date,
  "UTC",
  "USD"
)

total_revenue = response.data['total']['sum']

puts "Revenue by Country:"
response.data['country'].each do |country|
  revenue = country['value']
  percentage = (revenue.to_f / total_revenue * 100).round(1)

  puts "#{country['name']}:"
  puts "  Revenue: $#{revenue}"
  puts "  Percentage: #{percentage}%"
end
# Revenue by Country:
# US:
#   Revenue: $25,340
#   Percentage: 56.0%
# GB:
#   Revenue: $12,450
#   Percentage: 27.5%
# DE:
#   Revenue: $7,440
#   Percentage: 16.5%
```

### Device-Specific Revenue

```ruby
# Mobile revenue
mobile_response = client.reports.revenue(
  website_id,
  start_date,
  end_date,
  "America/New_York",
  "USD",
  filters: [
    { type: 'device', value: 'mobile' }
  ]
)

# Desktop revenue
desktop_response = client.reports.revenue(
  website_id,
  start_date,
  end_date,
  "America/New_York",
  "USD",
  filters: [
    { type: 'device', value: 'desktop' }
  ]
)

mobile_total = mobile_response.data['total']['sum']
mobile_aov = mobile_response.data['total']['average']

desktop_total = desktop_response.data['total']['sum']
desktop_aov = desktop_response.data['total']['average']

puts "Mobile Revenue: $#{mobile_total} (AOV: $#{mobile_aov.round(2)})"
puts "Desktop Revenue: $#{desktop_total} (AOV: $#{desktop_aov.round(2)})"
# Mobile Revenue: $18,900 (AOV: $28.45)
# Desktop Revenue: $26,330 (AOV: $42.18)

# Calculate contribution
total = mobile_total + desktop_total
mobile_pct = (mobile_total.to_f / total * 100).round(1)
desktop_pct = (desktop_total.to_f / total * 100).round(1)

puts "Mobile: #{mobile_pct}% | Desktop: #{desktop_pct}%"
# Mobile: 41.8% | Desktop: 58.2%
```

### Country-Specific Analysis

```ruby
# US revenue
us_response = client.reports.revenue(
  website_id,
  start_date,
  end_date,
  "America/New_York",
  "USD",
  filters: [
    { type: 'country', value: 'US' }
  ]
)

# UK revenue
uk_response = client.reports.revenue(
  website_id,
  start_date,
  end_date,
  "Europe/London",
  "GBP",
  filters: [
    { type: 'country', value: 'GB' }
  ]
)

us_totals = us_response.data['total']
puts "US Market:"
puts "  Revenue: $#{us_totals['sum']}"
puts "  Transactions: #{us_totals['count']}"
puts "  AOV: $#{us_totals['average'].round(2)}"

uk_totals = uk_response.data['total']
puts "\nUK Market:"
puts "  Revenue: £#{uk_totals['sum']}"
puts "  Transactions: #{uk_totals['count']}"
puts "  AOV: £#{uk_totals['average'].round(2)}"
# US Market:
#   Revenue: $25,340
#   Transactions: 678
#   AOV: $37.38
# UK Market:
#   Revenue: £9,850
#   Transactions: 342
#   AOV: £28.80
```

### Segmented Revenue Analysis

```ruby
# Analyze revenue by device and country combination
devices = ['mobile', 'desktop']
countries = ['US', 'GB', 'DE']

results = {}

devices.each do |device|
  countries.each do |country|
    response = client.reports.revenue(
      website_id,
      start_date,
      end_date,
      "UTC",
      "USD",
      filters: [
        { type: 'device', value: device },
        { type: 'country', value: country }
      ]
    )

    totals = response.data['total']
    results["#{country}/#{device}"] = {
      revenue: totals['sum'],
      transactions: totals['count'],
      aov: totals['average']
    }
  end
end

# Display matrix
puts "Revenue by Device & Country:"
countries.each do |country|
  puts "\n#{country}:"
  devices.each do |device|
    data = results["#{country}/#{device}"]
    puts "  #{device.capitalize}: $#{data[:revenue]} (#{data[:transactions]} txns, $#{data[:aov].round(2)} AOV)"
  end
end
# Revenue by Device & Country:
# US:
#   Mobile: $10,450 (412 txns, $25.36 AOV)
#   Desktop: $14,890 (266 txns, $55.98 AOV)
# GB:
#   Mobile: $5,230 (189 txns, $27.67 AOV)
#   Desktop: $7,220 (153 txns, $47.19 AOV)
```

### Period Comparison

```ruby
# Compare two time periods
def get_period_revenue(client, website_id, start_date, end_date)
  response = client.reports.revenue(
    website_id,
    start_date,
    end_date,
    "UTC",
    "USD"
  )
  response.data['total']
end

# Current period (last 30 days)
current_end = Time.now
current_start = current_end - (30 * 24 * 60 * 60)

current = get_period_revenue(
  client,
  website_id,
  current_start.utc.iso8601(3),
  current_end.utc.iso8601(3)
)

# Previous period (30 days before that)
previous_end = current_start
previous_start = previous_end - (30 * 24 * 60 * 60)

previous = get_period_revenue(
  client,
  website_id,
  previous_start.utc.iso8601(3),
  previous_end.utc.iso8601(3)
)

# Calculate changes
revenue_change = current['sum'] - previous['sum']
revenue_change_pct = ((current['sum'].to_f / previous['sum'] - 1) * 100).round(1)

txn_change = current['count'] - previous['count']
txn_change_pct = ((current['count'].to_f / previous['count'] - 1) * 100).round(1)

aov_change = current['average'] - previous['average']
aov_change_pct = ((current['average'] / previous['average'] - 1) * 100).round(1)

puts "Period Comparison (Last 30 Days vs Previous 30 Days):"
puts "\nRevenue:"
puts "  Current: $#{current['sum']}"
puts "  Previous: $#{previous['sum']}"
puts "  Change: $#{revenue_change} (#{revenue_change_pct}%)"

puts "\nTransactions:"
puts "  Current: #{current['count']}"
puts "  Previous: #{previous['count']}"
puts "  Change: #{txn_change} (#{txn_change_pct}%)"

puts "\nAverage Order Value:"
puts "  Current: $#{current['average'].round(2)}"
puts "  Previous: $#{previous['average'].round(2)}"
puts "  Change: $#{aov_change.round(2)} (#{aov_change_pct}%)"
# Period Comparison (Last 30 Days vs Previous 30 Days):
# Revenue:
#   Current: $45,230
#   Previous: $38,450
#   Change: $6,780 (17.6%)
# Transactions:
#   Current: 1,234
#   Previous: 1,089
#   Change: 145 (13.3%)
# Average Order Value:
#   Current: $36.65
#   Previous: $35.31
#   Change: $1.34 (3.8%)
```

### Revenue Growth Tracking

```ruby
# Track monthly revenue growth
months = 6
monthly_data = []

months.times do |i|
  month_end = Time.now - (i * 30 * 24 * 60 * 60)
  month_start = month_end - (30 * 24 * 60 * 60)

  response = client.reports.revenue(
    website_id,
    month_start.utc.iso8601(3),
    month_end.utc.iso8601(3),
    "UTC",
    "USD"
  )

  totals = response.data['total']
  monthly_data << {
    month: month_end.strftime('%B %Y'),
    revenue: totals['sum'],
    transactions: totals['count'],
    aov: totals['average']
  }
end

puts "6-Month Revenue Trend:"
monthly_data.reverse.each_with_index do |data, index|
  if index > 0
    prev = monthly_data.reverse[index - 1]
    growth = ((data[:revenue].to_f / prev[:revenue] - 1) * 100).round(1)
    growth_indicator = growth >= 0 ? "↑" : "↓"

    puts "#{data[:month]}: $#{data[:revenue]} #{growth_indicator} #{growth.abs}%"
  else
    puts "#{data[:month]}: $#{data[:revenue]}"
  end
end
# 6-Month Revenue Trend:
# May 2025: $32,450
# June 2025: $35,890 ↑ 10.6%
# July 2025: $38,450 ↑ 7.1%
# August 2025: $41,230 ↑ 7.2%
# September 2025: $43,560 ↑ 5.6%
# October 2025: $45,230 ↑ 3.8%
```

### Customer Segmentation by Value

```ruby
# Get overall revenue data
response = client.reports.revenue(
  website_id,
  start_date,
  end_date,
  "UTC",
  "USD"
)

totals = response.data['total']
total_revenue = totals['sum']
total_customers = totals['unique_count']
aov = totals['average']

# Analyze geographic segments
country_data = response.data['country'].map do |country|
  # Get country-specific details
  country_response = client.reports.revenue(
    website_id,
    start_date,
    end_date,
    "UTC",
    "USD",
    filters: [
      { type: 'country', value: country['name'] }
    ]
  )

  country_totals = country_response.data['total']

  {
    country: country['name'],
    revenue: country['value'],
    customers: country_totals['unique_count'],
    aov: country_totals['average'],
    revenue_per_customer: country['value'].to_f / country_totals['unique_count']
  }
end

# Sort by revenue per customer (customer value)
country_data.sort_by! { |c| -c[:revenue_per_customer] }

puts "Customer Value by Country:"
country_data.each do |data|
  puts "\n#{data[:country]}:"
  puts "  Total Revenue: $#{data[:revenue]}"
  puts "  Customers: #{data[:customers]}"
  puts "  AOV: $#{data[:aov].round(2)}"
  puts "  Revenue/Customer: $#{data[:revenue_per_customer].round(2)}"
end
# Customer Value by Country:
# US:
#   Total Revenue: $25,340
#   Customers: 612
#   AOV: $37.38
#   Revenue/Customer: $41.41
# GB:
#   Total Revenue: $12,450
#   Customers: 328
#   AOV: $30.12
#   Revenue/Customer: $37.96
```

### Revenue Attribution

Combine revenue reports with other filters to understand revenue attribution:

```ruby
# Revenue by traffic source (referrer)
referrers = ['google.com', 'facebook.com', 'twitter.com', '(direct)']

puts "Revenue by Traffic Source:"
referrers.each do |referrer|
  filter_value = referrer == '(direct)' ? '' : referrer

  response = client.reports.revenue(
    website_id,
    start_date,
    end_date,
    "UTC",
    "USD",
    filters: [
      { type: 'referrer', value: filter_value }
    ]
  )

  totals = response.data['total']
  source_display = referrer == '(direct)' ? 'Direct' : referrer

  puts "\n#{source_display}:"
  puts "  Revenue: $#{totals['sum']}"
  puts "  Transactions: #{totals['count']}"
  puts "  AOV: $#{totals['average'].round(2)}"
end
# Revenue by Traffic Source:
# google.com:
#   Revenue: $15,670
#   Transactions: 456
#   AOV: $34.36
# Direct:
#   Revenue: $18,920
#   Transactions: 512
#   AOV: $36.95
```

### Advanced Business Metrics

```ruby
# Calculate comprehensive business metrics
response = client.reports.revenue(
  website_id,
  start_date,
  end_date,
  "UTC",
  "USD"
)

totals = response.data['total']
days = ((Time.parse(end_date) - Time.parse(start_date)) / (24 * 60 * 60)).round

# Core metrics
total_revenue = totals['sum']
total_transactions = totals['count']
total_customers = totals['unique_count']
aov = totals['average']

# Calculated metrics
daily_revenue = total_revenue.to_f / days
daily_transactions = total_transactions.to_f / days
customer_ltv = total_revenue.to_f / total_customers
repeat_rate = ((total_transactions - total_customers).to_f / total_customers * 100).round(1)

puts "Business Metrics (#{days} days):"
puts "\nRevenue Metrics:"
puts "  Total Revenue: $#{total_revenue}"
puts "  Daily Revenue: $#{daily_revenue.round(2)}"
puts "  Monthly Run Rate: $#{(daily_revenue * 30).round(0)}"
puts "  Annual Run Rate: $#{(daily_revenue * 365).round(0)}"

puts "\nTransaction Metrics:"
puts "  Total Transactions: #{total_transactions}"
puts "  Daily Transactions: #{daily_transactions.round(1)}"
puts "  Average Order Value: $#{aov.round(2)}"

puts "\nCustomer Metrics:"
puts "  Total Customers: #{total_customers}"
puts "  Customer Lifetime Value: $#{customer_ltv.round(2)}"
puts "  Repeat Purchase Rate: #{repeat_rate}%"
# Business Metrics (90 days):
# Revenue Metrics:
#   Total Revenue: $45,230
#   Daily Revenue: $502.56
#   Monthly Run Rate: $15,077
#   Annual Run Rate: $183,434
# Transaction Metrics:
#   Total Transactions: 1,234
#   Daily Transactions: 13.7
#   Average Order Value: $36.65
# Customer Metrics:
#   Total Customers: 1,189
#   Customer Lifetime Value: $38.04
#   Repeat Purchase Rate: 3.8%
```

### Industry Benchmarks

**Average Order Value (AOV) by Industry:**
```ruby
# E-commerce: $50-100
# SaaS (Monthly): $20-50
# SaaS (Annual): $200-2,000
# Digital Products: $10-50
# Services: $100-1,000
```

**Conversion Rate Benchmarks:**
```ruby
# E-commerce: 1-3%
# SaaS: 3-5%
# Digital Products: 2-5%
# Services: 5-10%
```

**Mobile vs Desktop AOV:**
```ruby
# Mobile typically: 60-80% of desktop AOV
# Mobile revenue share: 30-50% of total
# Desktop typically: Higher AOV, fewer transactions
```

**Geographic Performance:**
```ruby
# US typically: Highest AOV in most industries
# EU: 70-90% of US AOV
# Asia: Varies widely (30-100% of US AOV)
# Consider local purchasing power and market maturity
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
