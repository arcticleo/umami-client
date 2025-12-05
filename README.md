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
