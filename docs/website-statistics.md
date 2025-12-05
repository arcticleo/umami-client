# Website Statistics

Retrieve analytics data from your Umami instance. All statistics operations require authentication.

## Active Visitors

Get the number of visitors currently active on your website (last 5 minutes):

```ruby
client = UmamiClient::Client.new

 Get active visitor count
response = client.stats.active("website-id")
puts "Active visitors: #{response.body['visitors']}"
```

## Summary Statistics

Get aggregated statistics for a date range, including pageviews, visitors, visits, bounce rate, and time spent.

### Basic Usage

```ruby
 Get stats for a specific date range
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

### Convenience Methods

For common date ranges, use these convenience methods:

```ruby
 Today's stats
response = client.stats.today("website-id")
puts "Today's pageviews: #{response.body['pageviews']['value']}"

 Yesterday's stats
response = client.stats.yesterday("website-id")
puts "Yesterday's visitors: #{response.body['visitors']['value']}"

 Last 7 days
response = client.stats.last_7_days("website-id")

 Last 30 days
response = client.stats.last_30_days("website-id")

 All convenience methods support custom timezone
response = client.stats.today("website-id", timezone: "Europe/London")
```

## Pageviews Time Series

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

 Plot the data
response.body['pageviews'].each do |point|
  puts "#{point['x']}: #{point['y']} pageviews"
end
 Output:
 2025-11-04 00:00:00: 142 pageviews
 2025-11-05 00:00:00: 198 pageviews
 ...
```

### With Comparison

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

## Metrics

Get aggregated metrics like top pages, referrers, browsers, countries, and more.

### Top Pages

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
 Output:
   /blog/post-1: 1,234 views
   /products: 892 views
   /: 654 views
```

### Available Metric Types

```ruby
 Top referrers
client.stats.metrics(website_id, start_at, end_at, "referrer", limit: 10)

 Browsers
client.stats.metrics(website_id, start_at, end_at, "browser", limit: 10)

 Operating systems
client.stats.metrics(website_id, start_at, end_at, "os", limit: 10)

 Devices
client.stats.metrics(website_id, start_at, end_at, "device", limit: 10)

 Countries
client.stats.metrics(website_id, start_at, end_at, "country", limit: 10)

 Languages
client.stats.metrics(website_id, start_at, end_at, "language", limit: 10)

 Page titles
client.stats.metrics(website_id, start_at, end_at, "title", limit: 10)

 Query parameters
client.stats.metrics(website_id, start_at, end_at, "query", limit: 10)

 Custom events
client.stats.metrics(website_id, start_at, end_at, "event", limit: 10)
```

### With Filters

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

### Pagination

```ruby
response = client.stats.metrics(
  "website-id",
  start_at,
  end_at,
  "url",
  limit: 20,
  offset: 0
)

 Get next page
response = client.stats.metrics(
  "website-id",
  start_at,
  end_at,
  "url",
  limit: 20,
  offset: 20
)
```

## Event Series

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

 Process event data
response.body['events'].each do |event|
  puts "#{event['x']}: #{event['y']} events"
end
```

## Complete Dashboard Example

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

 Real-time data
active = client.stats.active(website_id)
puts "🟢 #{active.body['visitors']} visitors online now"
puts ""

 Today's summary
today = client.stats.today(website_id)
puts "📊 Today's Stats:"
puts "  Pageviews: #{today.body['pageviews']['value']}"
puts "  Visitors: #{today.body['visitors']['value']}"
puts "  Visits: #{today.body['visits']['value']}"
puts "  Bounce rate: #{today.body['bounces']['value']}%"
puts ""

 Last 7 days trend
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

 Top content
now = Time.now
thirty_days_ago = now - (30 * 24 * 60 * 60)

urls = client.stats.metrics(website_id, thirty_days_ago, now, "url", limit: 5)
puts "🔥 Top Pages (30 days):"
urls.body.each_with_index do |metric, i|
  puts "  #{i + 1}. #{metric['x']}: #{metric['y']} views"
end
puts ""

 Traffic sources
countries = client.stats.metrics(website_id, thirty_days_ago, now, "country", limit: 5)
puts "🌍 Top Countries:"
countries.body.each do |metric|
  puts "  #{metric['x']}: #{metric['y']} visits"
end
puts ""

 Browsers
browsers = client.stats.metrics(website_id, thirty_days_ago, now, "browser", limit: 5)
puts "🌐 Top Browsers:"
browsers.body.each do |metric|
  puts "  #{metric['x']}: #{metric['y']} visits"
end
```

## Time Handling

The Stats API accepts timestamps as either:
- Ruby `Time` objects (automatically converted to milliseconds)
- Integer timestamps in milliseconds

```ruby
 Using Time objects (recommended)
start_time = Time.now - (7 * 24 * 60 * 60)
end_time = Time.now
client.stats.summary(website_id, start_time, end_time)

 Using millisecond timestamps
start_ms = (Time.now.to_f * 1000).to_i - (7 * 24 * 60 * 60 * 1000)
end_ms = (Time.now.to_f * 1000).to_i
client.stats.summary(website_id, start_ms, end_ms)
```

