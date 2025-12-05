# Executing Journey Reports

Journey reports analyze actual user navigation paths through your website, revealing how users naturally explore and move between pages. Unlike funnels (which track predefined sequential steps), journey reports **discover** all possible paths users take, helping you understand real-world navigation behavior.

## Basic Journey Analysis

```ruby
 Discover common paths from homepage
response = client.reports.journey(
  "website-id",
  Time.now - 30.days,
  Time.now,
  "/",
  5  # Track 5 steps
)

 Display top navigation paths
puts "Most common navigation paths:"
response.body.first(10).each do |path|
  puts "#{path['count']} users: #{path['items'].join(' → ')}"
end
```

## Journey vs Funnel

**Funnels** are for measuring conversion through predefined steps:
- You define the exact sequence
- Measures drop-off at each step
- Good for: conversion optimization, checkout flows

**Journeys** are for discovering actual user behavior:
- Shows all paths users actually take
- Reveals unexpected routes
- Good for: site architecture, UX improvements, content discovery

## Finding Paths to a Destination

Filter journeys to only show paths that reach a specific destination:

```ruby
 Find all routes from homepage to pricing page
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

## Journey Step Lengths

Track between 3 and 7 steps based on your analysis needs:

```ruby
 Short journey (3 steps) - immediate next actions
client.reports.journey(website_id, start_date, end_date, "/", 3)

 Medium journey (5 steps) - typical session exploration
client.reports.journey(website_id, start_date, end_date, "/", 5)

 Long journey (7 steps) - deep navigation patterns
client.reports.journey(website_id, start_date, end_date, "/", 7)
```

**Guidelines:**
- **3 steps**: Immediate next actions, quick decisions
- **4-5 steps**: Typical session exploration, moderate browsing
- **6-7 steps**: Deep research behavior, extensive browsing

## Content Discovery Journey

```ruby
 Discover how users navigate from articles
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

## E-commerce Shopping Journey

```ruby
 Track shopping behavior from product pages
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

## Event-Based Journeys

Track journeys starting from custom events:

```ruby
 Discover what users do after signup
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

## Segmented Journey Analysis

Filter journeys by user segments to understand different behaviors:

```ruby
 Mobile user navigation patterns
mobile_response = client.reports.journey(
  "website-id",
  Time.now - 30.days,
  Time.now,
  "/",
  5,
  filters: { device: "mobile" }
)

 Desktop user navigation patterns
desktop_response = client.reports.journey(
  "website-id",
  Time.now - 30.days,
  Time.now,
  "/",
  5,
  filters: { device: "desktop" }
)

 Compare behavior
puts "Mobile paths: #{mobile_response.body.length} unique"
puts "Desktop paths: #{desktop_response.body.length} unique"

 Find mobile-specific patterns
mobile_first_steps = mobile_response.body.map { |p| p['items'][1] }.compact.uniq
puts "Mobile users typically visit: #{mobile_first_steps.join(', ')}"
```

## Geographic Journey Differences

```ruby
 US visitor behavior
us_response = client.reports.journey(
  "website-id",
  start_date, end_date, "/", 5,
  filters: { country: "US" }
)

 European visitor behavior
eu_response = client.reports.journey(
  "website-id",
  start_date, end_date, "/", 5,
  filters: { country: "DE" }
)

 Compare navigation patterns
puts "US visitors take #{us_response.body.length} different paths"
puts "EU visitors take #{eu_response.body.length} different paths"
```

## Complete Journey Analysis Example

```ruby
 Analyze product discovery and purchase behavior
start_date = Time.now - 30.days
end_date = Time.now

 Execute journey from homepage to checkout
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

 Analyze path characteristics
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

 Identify most efficient path
shortest_path = response.body.min_by { |p| p['items'].length }
most_popular = response.body.max_by { |p| p['count'] }

puts "\n" + "=" * 50
puts "Key Insights:"
puts "  Shortest path: #{shortest_path['items'].length} steps"
puts "  Most popular path: #{most_popular['count']} users"
puts "  Most popular route: #{most_popular['items'].join(' → ')}"

 Find common patterns
all_pages = response.body.flat_map { |p| p['items'] }
page_frequency = all_pages.group_by(&:itself).transform_values(&:count)
common_pages = page_frequency.sort_by { |_, count| -count }.first(5)

puts "\nMost visited pages in checkout journeys:"
common_pages.each do |page, count|
  puts "  #{page}: appeared in #{count} journeys"
end
```

## Use Cases for Journey Reports

**1. Site Architecture Optimization**
```ruby
 Discover how users naturally navigate your site
 Identify which pages are navigation hubs
 Find dead-end pages that need better links
```

**2. Content Strategy**
```ruby
 See which articles lead to others
 Identify content clusters users explore together
 Find topic progression patterns
```

**3. Conversion Path Discovery**
```ruby
 Find unexpected routes to conversion
 Identify which pages assist conversions
 Understand the research process
```

**4. UX Improvements**
```ruby
 Spot confusing navigation patterns
 Identify where users backtrack
 Find areas where users get lost
```

**5. Personalization Insights**
```ruby
 Compare mobile vs desktop journeys
 Understand geographic differences
 Identify segment-specific behaviors
```

