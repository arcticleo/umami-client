# Session Queries

Query session data including finding sessions by distinct ID (visitor identifier), retrieving session properties, and getting all activity for a specific visitor.

## Finding Sessions by Distinct ID

The most common use case: finding all events/pageviews for a specific visitor you identified with `identify()`.

```ruby
client = UmamiClient::Client.new

 1. Search for sessions by distinct ID (email, user ID, etc.)
response = client.sessions.list(
  "website-id",
  Time.now - 30.days,
  Time.now,
  search: "customer@example.com"
)

sessions = response.body['data']
puts "Found #{sessions.length} sessions"

 2. Get the session ID
session_id = sessions.first['id']

 3. Get session properties to confirm the visitor
properties = client.sessions.properties("website-id", session_id)
puts "Visitor properties:"
properties.body.each do |prop|
  puts "  #{prop['dataKey']}: #{prop['stringValue'] || prop['numberValue']}"
end

 4. Get ALL pageviews and events for this visitor
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

## List Sessions

Get a list of sessions with optional search and filtering:

```ruby
 List recent sessions
response = client.sessions.list(
  "website-id",
  Time.now - 7.days,
  Time.now,
  page_size: 50
)

response.body['data'].each do |session|
  puts "#{session['browser']}/#{session['os']}: #{session['pageviews']} views"
end

 Search for specific visitor
response = client.sessions.list(
  "website-id",
  Time.now - 30.days,
  Time.now,
  search: "premium-user@example.com"
)
```

## Session Details

Get detailed information about a specific session:

```ruby
 Get session details
response = client.sessions.get("website-id", "session-id")

puts "Browser: #{response.body['browser']}"
puts "OS: #{response.body['os']}"
puts "Country: #{response.body['country']}"
puts "Device: #{response.body['device']}"
puts "Pageviews: #{response.body['pageviews']}"
puts "Visits: #{response.body['visits']}"
```

## Session Activity

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

## Session Properties

Get custom properties set via `identify()`:

```ruby
response = client.sessions.properties("website-id", "session-id")

 Properties are returned as an array of property objects
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

## Session Statistics

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

## Weekly Session Patterns

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

## Session Property Names

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

## Session Property Values

Get all unique values for a specific property:

```ruby
 Get all plan types
response = client.sessions.property_values(
  "website-id",
  "plan"
)

puts "Subscription plans:"
response.body.each do |item|
  puts "  #{item['value']}: #{item['total']} sessions"
end

 With date range
response = client.sessions.property_values(
  "website-id",
  "plan",
  start_at: Time.now - 30.days,
  end_at: Time.now
)
```

## Complete Visitor Tracking Example

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

 Find a specific customer
customer_email = "premium.customer@example.com"

 1. Search for their sessions
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

