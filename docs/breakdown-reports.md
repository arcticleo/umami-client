# Executing Breakdown Reports

Breakdown reports segment your data by one or more dimensions, allowing you to analyze metrics across different combinations of properties like country, device, browser, operating system, and more.

## Basic Usage

```ruby
 Single dimension breakdown - Operating System
response = client.reports.breakdown(
  website_id,
  start_date,
  end_date,
  ['os']
)

response.data.each do |record|
  puts "#{record['os']}: #{record['views']} views, #{record['visitors']} visitors"
end
 Windows: 1,250 views, 450 visitors
 macOS: 890 views, 320 visitors
 Linux: 340 views, 145 visitors
```

## Available Dimensions

Breakdown reports support the following dimensions:

```ruby
 Traffic dimensions
['path']        # Page URLs
['title']       # Page titles
['referrer']    # Traffic sources
['query']       # URL query parameters
['hostname']    # Domain names

 Technology dimensions
['browser']     # Web browsers
['os']          # Operating systems
['device']      # Device types (desktop, mobile, tablet)

 Geography dimensions
['country']     # Countries
['region']      # States/provinces
['city']        # Cities

 Custom dimensions
['tag']         # Custom tags
['event']       # Custom events
```

## Single Dimension Breakdowns

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
 Desktop:
   Views: 5,240
   Visitors: 1,890
   Bounce Rate: 42.3%
   Avg Time: 185s
 Mobile:
   Views: 3,120
   Visitors: 1,450
   Bounce Rate: 58.7%
   Avg Time: 92s
```

**Geographic Analysis:**
```ruby
response = client.reports.breakdown(
  website_id,
  start_date,
  end_date,
  ['country']
)

 Top 10 countries by traffic
top_countries = response.data
  .sort_by { |r| -r['views'] }
  .take(10)

top_countries.each_with_index do |record, index|
  puts "#{index + 1}. #{record['country']}: #{record['views']} views (#{record['visitors']} visitors)"
end
 1. US: 4,230 views (1,890 visitors)
 2. GB: 1,450 views (670 visitors)
 3. DE: 980 views (420 visitors)
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
 Chrome: 4,580 views (52.3%)
 Safari: 2,340 views (26.7%)
 Firefox: 1,120 views (12.8%)
 Edge: 710 views (8.1%)
```

**Page Performance:**
```ruby
response = client.reports.breakdown(
  website_id,
  start_date,
  end_date,
  ['path']
)

 Analyze page performance
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
 /blog/getting-started:
   Visits: 1,450
   Bounce Rate: 35.2%
   Avg Time on Page: 245s
 /pricing:
   Visits: 890
   Bounce Rate: 52.1%
   Avg Time on Page: 78s
```

## Multi-Dimension Breakdowns

**Technology Stack Analysis:**
```ruby
 OS + Browser combinations
response = client.reports.breakdown(
  website_id,
  start_date,
  end_date,
  ['os', 'browser']
)

 Group by OS
by_os = response.data.group_by { |r| r['os'] }

by_os.each do |os, records|
  puts "\n#{os}:"
  records.sort_by { |r| -r['views'] }.take(3).each do |record|
    puts "  #{record['browser']}: #{record['views']} views"
  end
end
 Windows:
   Chrome: 1,890 views
   Edge: 710 views
   Firefox: 450 views
 macOS:
   Safari: 1,240 views
   Chrome: 890 views
   Firefox: 120 views
```

**Geographic + Device Analysis:**
```ruby
response = client.reports.breakdown(
  website_id,
  start_date,
  end_date,
  ['country', 'device']
)

 Find mobile adoption by country
by_country = response.data.group_by { |r| r['country'] }

by_country.each do |country, records|
  total = records.sum { |r| r['views'] }
  mobile = records.find { |r| r['device'] == 'mobile' }&.dig('views') || 0
  mobile_pct = (mobile.to_f / total * 100).round(1)

  puts "#{country}: #{mobile_pct}% mobile (#{mobile}/#{total} views)"
end
 US: 32.4% mobile (1,370/4,230 views)
 GB: 45.2% mobile (655/1,450 views)
 IN: 78.9% mobile (1,890/2,395 views)
```

**Traffic Source + Landing Page:**
```ruby
response = client.reports.breakdown(
  website_id,
  start_date,
  end_date,
  ['referrer', 'path']
)

 Analyze which referrers drive traffic to which pages
by_referrer = response.data.group_by { |r| r['referrer'] }

by_referrer.each do |referrer, records|
  ref_display = referrer.empty? ? '(direct)' : referrer
  puts "\nFrom #{ref_display}:"

  records.sort_by { |r| -r['views'] }.take(3).each do |record|
    puts "  → #{record['path']}: #{record['views']} views"
  end
end
 From google.com:
   → /blog: 890 views
   → /docs: 450 views
   → /: 340 views
 From (direct):
   → /: 1,240 views
   → /dashboard: 670 views
```

**Three-Dimension Analysis:**
```ruby
 Country + OS + Device
response = client.reports.breakdown(
  website_id,
  start_date,
  end_date,
  ['country', 'os', 'device']
)

 Find most common configurations
top_configs = response.data
  .sort_by { |r| -r['views'] }
  .take(10)

puts "Top 10 Configuration Combinations:"
top_configs.each_with_index do |record, index|
  config = "#{record['country']} / #{record['os']} / #{record['device']}"
  puts "#{index + 1}. #{config}: #{record['views']} views"
end
 Top 10 Configuration Combinations:
 1. US / Windows / desktop: 1,450 views
 2. US / iOS / mobile: 890 views
 3. GB / Windows / desktop: 670 views
 4. US / macOS / desktop: 560 views
```

## Filtered Breakdowns

**Mobile-Only Analysis:**
```ruby
 Analyze mobile users only
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
 Mobile Browser Usage:
 iOS - Safari: 1,240 views
 Android - Chrome: 1,890 views
 iOS - Chrome: 340 views
```

**Country-Specific Analysis:**
```ruby
 Analyze US traffic only
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
 US Device Usage:
 Desktop:
   Windows: 1,450 views
   macOS: 890 views
 Mobile:
   iOS: 670 views
   Android: 450 views
```

**Specific Page Analysis:**
```ruby
 Analyze who visits a specific page
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

## Advanced Analysis Patterns

**Engagement Segmentation:**
```ruby
response = client.reports.breakdown(
  website_id,
  start_date,
  end_date,
  ['country', 'device']
)

 Segment by engagement quality
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
 High Engagement Segments:
   US / desktop: 92.3 score
     (35.2% bounce, 274s avg time)
   GB / desktop: 87.5 score
     (38.9% bounce, 245s avg time)
```

**Market Opportunity Analysis:**
```ruby
response = client.reports.breakdown(
  website_id,
  start_date,
  end_date,
  ['country']
)

 Calculate market metrics
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
 US: Mature market
   Visitors: 1,890
   Return Rate: 178.4%
   Pages/Visit: 3.8
 IN: New market
   Visitors: 450
   Return Rate: 105.2%
   Pages/Visit: 1.9
```

**Content Performance by Source:**
```ruby
response = client.reports.breakdown(
  website_id,
  start_date,
  end_date,
  ['referrer', 'path']
)

 Analyze which sources drive best content engagement
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
 /blog/getting-started:
   google.com: 890 views (45.2%)
   (direct): 450 views (22.9%)
   twitter.com: 340 views (17.3%)
```

**Cross-Platform Analysis:**
```ruby
response = client.reports.breakdown(
  website_id,
  start_date,
  end_date,
  ['os', 'browser', 'device']
)

 Analyze platform-specific behaviors
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
 Windows Desktop:
   Views: 3,450
   Avg Time: 198s
   Bounce Rate: 41.2%
 Mac Desktop:
   Views: 1,890
   Avg Time: 245s
   Bounce Rate: 35.8%
 iOS Mobile:
   Views: 1,340
   Avg Time: 92s
   Bounce Rate: 58.3%
```

## Business Intelligence Use Cases

**1. Browser Compatibility Testing Priority:**
```ruby
response = client.reports.breakdown(
  website_id,
  start_date,
  end_date,
  ['browser', 'os']
)

 Identify test configurations by importance
test_matrix = response.data
  .sort_by { |r| -r['views'] }
  .take(10)

puts "Priority Test Matrix:"
test_matrix.each_with_index do |record, index|
  puts "#{index + 1}. #{record['browser']} on #{record['os']}: #{record['views']} views (#{record['visitors']} users)"
end
 Priority Test Matrix:
 1. Chrome on Windows: 1,890 views (780 users)
 2. Safari on macOS: 1,240 views (540 users)
 3. Chrome on macOS: 890 views (380 users)
```

**2. Localization Priority:**
```ruby
response = client.reports.breakdown(
  website_id,
  start_date,
  end_date,
  ['country']
)

 Calculate localization ROI potential
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
 Localization Priority (by engagement potential):
 1. US: 1,890 visitors, 1.78x return
 2. GB: 670 visitors, 1.45x return
 3. DE: 420 visitors, 1.32x return
```

**3. Mobile Optimization Priority:**
```ruby
response = client.reports.breakdown(
  website_id,
  start_date,
  end_date,
  ['device', 'path']
)

 Find pages with high mobile traffic but poor performance
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
 Track specific feature usage across segments
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

 Calculate adoption rate by segment
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
 Feature Adoption by Segment:
 US / desktop: 12.3% adoption (232/1,890)
 US / mobile: 3.4% adoption (23/670)
 GB / desktop: 8.7% adoption (58/670)
```

## Industry Benchmarks

**Bounce Rates by Device:**
```ruby
 Content sites: Desktop 40-60%, Mobile 60-75%
 E-commerce: Desktop 35-50%, Mobile 50-65%
 SaaS: Desktop 30-45%, Mobile 45-60%
```

**Pages per Visit by Device:**
```ruby
 Desktop: 3-5 pages typically
 Mobile: 2-3 pages typically
 Tablet: 2.5-4 pages typically
```

**Geographic Engagement:**
```ruby
 Mature markets (US, GB, DE): Higher page depth, lower bounce
 Growing markets (BR, MX, IN): Lower page depth, higher bounce initially
 Consider localization when traffic > 500 visitors/month from market
```

