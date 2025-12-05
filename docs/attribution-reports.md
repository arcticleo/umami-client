# Executing Attribution Reports

Attribution reports analyze marketing channel performance by showing which sources drive conversions. Using attribution models (first-click or last-click), these reports credit conversion sources and reveal which channels bring traffic that actually converts.

## Understanding Attribution Models

**First-Click Attribution:**
- Credits the first touchpoint in the user journey
- Shows which channels bring initial awareness
- Good for: Top-of-funnel optimization, brand awareness campaigns

**Last-Click Attribution:**
- Credits the final touchpoint before conversion
- Shows which channels close the deal
- Good for: Bottom-of-funnel optimization, direct response campaigns

## Basic Attribution Analysis

```ruby
 First-click attribution for purchases
response = client.reports.attribution(
  "website-id",
  Time.now - 30.days,
  Time.now,
  "firstClick",
  "event",
  "purchase"
)

 Analyze top referrers
puts "Top Referrers (First-Click):"
response.body['referrer']&.each do |source|
  puts "  #{source['name']}: #{source['value']} conversions"
end

 Analyze UTM sources
puts "\nTop UTM Sources:"
response.body['utm_source']&.each do |source|
  puts "  #{source['name']}: #{source['value']} conversions"
end

 Show totals
total = response.body['total']
puts "\nTotal: #{total['visitors']} visitors, #{total['pageviews']} pageviews"
```

## Attribution Response Structure

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

## Comparing Attribution Models

```ruby
 First-click attribution
first_click = client.reports.attribution(
  "website-id",
  Time.now - 30.days,
  Time.now,
  "firstClick",
  "event",
  "purchase"
)

 Last-click attribution
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

 Insights from differences
 - Sources appearing in first-click but not last-click are good for awareness
 - Sources appearing in last-click but not first-click are good for closing
 - Sources appearing in both are valuable throughout the journey
```

## UTM Campaign Attribution

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

 Calculate ROI if you have campaign costs
campaign_cost = 5000  # Your campaign budget
conversions = response.body['utm_campaign'].first['value']
avg_order_value = 99.99
revenue = conversions * avg_order_value
roi = ((revenue - campaign_cost) / campaign_cost * 100).round(2)

puts "\nCampaign ROI: #{roi}%"
```

## Paid Advertising Attribution

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

## Segmented Attribution

Filter attribution by user segments:

```ruby
 Mobile attribution
mobile_response = client.reports.attribution(
  "website-id",
  Time.now - 30.days,
  Time.now,
  "firstClick",
  "event",
  "purchase",
  filters: { device: "mobile" }
)

 Desktop attribution
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

## Geographic Attribution

```ruby
 US attribution
us_response = client.reports.attribution(
  "website-id",
  Time.now - 30.days,
  Time.now,
  "lastClick",
  "event",
  "signup",
  filters: { country: "US" }
)

 EU attribution
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

## Complete Attribution Dashboard

```ruby
 Comprehensive attribution analysis
start_date = Time.now - 30.days
end_date = Time.now

puts "Marketing Attribution Dashboard"
puts "=" * 50
puts "Period: #{start_date.strftime('%Y-%m-%d')} to #{end_date.strftime('%Y-%m-%d')}"

 Get attribution data
response = client.reports.attribution(
  website_id,
  start_date,
  end_date,
  "lastClick",
  "event",
  "purchase"
)

 Traffic Sources
puts "\nTop Traffic Sources:"
response.body['referrer']&.first(10)&.each_with_index do |source, index|
  puts "  #{index + 1}. #{source['name']}: #{source['value']} conversions"
end

 UTM Analysis
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

 Paid vs Organic
paid_conversions = response.body['paidAds']&.sum { |ad| ad['value'] } || 0
total_conversions = response.body['total']['visitors']
organic_conversions = total_conversions - paid_conversions

puts "\n" + "=" * 50
puts "Conversion Split:"
puts "  Organic: #{organic_conversions} (#{(organic_conversions.to_f / total_conversions * 100).round(1)}%)"
puts "  Paid: #{paid_conversions} (#{(paid_conversions.to_f / total_conversions * 100).round(1)}%)"

 Calculate channel efficiency
puts "\nChannel Efficiency:"
response.body['utm_source']&.first(5)&.each do |source|
  efficiency = (source['value'].to_f / total_conversions * 100).round(2)
  puts "  #{source['name']}: #{efficiency}% of all conversions"
end
```

## Marketing ROI Calculation

```ruby
response = client.reports.attribution(
  website_id,
  Time.now - 30.days,
  Time.now,
  "lastClick",
  "event",
  "purchase"
)

 Define campaign costs and metrics
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

## Attribution Best Practices

**Use first-click attribution to:**
```ruby
 - Identify awareness-building channels
 - Optimize top-of-funnel campaigns
 - Allocate budget to customer acquisition sources
 - Understand brand discovery patterns
```

**Use last-click attribution to:**
```ruby
 - Identify conversion-driving channels
 - Optimize bottom-of-funnel campaigns
 - Reward channels that close sales
 - Understand decision-making triggers
```

**Compare both models to:**
```ruby
 - Get complete journey visibility
 - Identify assist vs. close channels
 - Optimize multi-touch campaigns
 - Balance awareness and conversion spending
```

## Common Attribution Patterns

**B2C E-commerce:**
```ruby
 First-click: Social media, display ads, content
 Last-click: Google search, email, retargeting
 Strategy: Use social for awareness, search for conversion
```

**B2B SaaS:**
```ruby
 First-click: LinkedIn, content marketing, webinars
 Last-click: Direct, email, sales outreach
 Strategy: Content for awareness, direct contact for conversion
```

**Content Sites:**
```ruby
 First-click: Social media, search engines, aggregators
 Last-click: Direct, bookmarks, newsletters
 Strategy: SEO for discovery, email for retention
```
