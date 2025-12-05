# Executing UTM Reports

UTM reports track marketing campaigns through UTM parameters, analyzing campaign performance across five dimensions: source, medium, campaign, content, and term. These reports help you understand which marketing channels and campaigns are driving traffic to your website.

## Basic Usage

```ruby
 Basic UTM report
response = client.reports.utm(
  website_id,
  start_date,
  end_date
)

 Analyze by source
response.data['utm_source'].each do |item|
  puts "#{item['utm']}: #{item['views']} views"
end
 google: 1,450 views
 facebook: 890 views
 twitter: 340 views

 Analyze by medium
response.data['utm_medium'].each do |item|
  puts "#{item['utm']}: #{item['views']} views"
end
 cpc: 1,120 views
 email: 670 views
 social: 450 views

 Analyze by campaign
response.data['utm_campaign'].each do |item|
  puts "#{item['utm']}: #{item['views']} views"
end
 summer_sale: 1,890 views
 product_launch: 1,240 views
 newsletter_jan: 670 views
```

## UTM Parameters Overview

UTM reports organize data by five standard parameters:

```ruby
 utm_source: Traffic origin (google, facebook, newsletter)
 utm_medium: Marketing medium (cpc, email, social, referral)
 utm_campaign: Campaign name (summer_sale, product_launch)
 utm_content: Content variation (banner_a, banner_b, link_text)
 utm_term: Paid search keywords (ruby, analytics, tracking)
```

## Traffic Source Analysis

```ruby
response = client.reports.utm(
  website_id,
  start_date,
  end_date
)

 Calculate source distribution
total_views = response.data['utm_source'].sum { |s| s['views'] }

puts "Traffic Source Distribution:"
response.data['utm_source'].each do |source|
  views = source['views']
  percentage = (views.to_f / total_views * 100).round(1)

  puts "#{source['utm']}:"
  puts "  Views: #{views}"
  puts "  Percentage: #{percentage}%"
end
 Traffic Source Distribution:
 google:
   Views: 1,450
   Percentage: 35.2%
 facebook:
   Views: 890
   Percentage: 21.6%
 twitter:
   Views: 670
   Percentage: 16.3%
 linkedin:
   Views: 560
   Percentage: 13.6%
 newsletter:
   Views: 540
   Percentage: 13.1%
```

## Campaign Performance

```ruby
response = client.reports.utm(
  website_id,
  start_date,
  end_date
)

 Rank campaigns by performance
campaigns = response.data['utm_campaign']
  .sort_by { |c| -c['views'] }

total_views = campaigns.sum { |c| c['views'] }

puts "Campaign Performance:"
campaigns.each_with_index do |campaign, index|
  views = campaign['views']
  percentage = (views.to_f / total_views * 100).round(1)

  puts "#{index + 1}. #{campaign['utm']}: #{views} views (#{percentage}%)"
end
 Campaign Performance:
 1. summer_sale_2025: 1,890 views (42.3%)
 2. product_launch_q3: 1,240 views (27.8%)
 3. newsletter_july: 670 views (15.0%)
 4. webinar_series: 450 views (10.1%)
 5. partner_promo: 210 views (4.7%)

 Identify winner
winner = campaigns.first
puts "\nTop Campaign: #{winner['utm']} with #{winner['views']} views"
 Top Campaign: summer_sale_2025 with 1,890 views
```

## Medium Effectiveness

```ruby
response = client.reports.utm(
  website_id,
  start_date,
  end_date
)

mediums = response.data['utm_medium'].sort_by { |m| -m['views'] }
total_views = mediums.sum { |m| m['views'] }

puts "Medium Effectiveness:"
mediums.each do |medium|
  views = medium['views']
  percentage = (views.to_f / total_views * 100).round(1)

  puts "#{medium['utm']}: #{views} views (#{percentage}%)"
end
 Medium Effectiveness:
 cpc: 1,450 views (38.7%)
 email: 1,120 views (29.9%)
 social: 890 views (23.8%)
 referral: 280 views (7.5%)

 Best performing medium
best = mediums.first
puts "\nBest Performing Medium: #{best['utm']} (#{best['views']} views)"
 Best Performing Medium: cpc (1,450 views)
```

## Device-Specific Campaign Performance

```ruby
 Mobile campaign performance
mobile_response = client.reports.utm(
  website_id,
  start_date,
  end_date,
  filters: [
    { type: 'device', value: 'mobile' }
  ]
)

 Desktop campaign performance
desktop_response = client.reports.utm(
  website_id,
  start_date,
  end_date,
  filters: [
    { type: 'device', value: 'desktop' }
  ]
)

puts "Campaign Performance by Device:"
puts "\nMobile:"
mobile_response.data['utm_campaign'].take(3).each do |campaign|
  puts "  #{campaign['utm']}: #{campaign['views']} views"
end

puts "\nDesktop:"
desktop_response.data['utm_campaign'].take(3).each do |campaign|
  puts "  #{campaign['utm']}: #{campaign['views']} views"
end
 Campaign Performance by Device:
 Mobile:
   summer_sale_2025: 890 views
   newsletter_july: 450 views
   social_promo: 340 views
 Desktop:
   product_launch_q3: 1,120 views
   summer_sale_2025: 1,000 views
   webinar_series: 450 views
```

## Geographic Campaign Analysis

```ruby
 Get campaigns by country
countries = ['US', 'GB', 'DE']

puts "Campaign Performance by Country:"
countries.each do |country|
  response = client.reports.utm(
    website_id,
    start_date,
    end_date,
    filters: [
      { type: 'country', value: country }
    ]
  )

  puts "\n#{country}:"
  if response.data['utm_campaign'] && response.data['utm_campaign'].length > 0
    response.data['utm_campaign'].take(3).each do |campaign|
      puts "  #{campaign['utm']}: #{campaign['views']} views"
    end
  else
    puts "  No campaign data"
  end
end
 Campaign Performance by Country:
 US:
   summer_sale_2025: 1,120 views
   product_launch_q3: 780 views
   newsletter_july: 450 views
 GB:
   product_launch_q3: 340 views
   summer_sale_2025: 280 views
   webinar_series: 120 views
 DE:
   summer_sale_2025: 210 views
   product_launch_q3: 120 views
   partner_promo: 90 views
```

## Content Variation Testing (A/B Testing)

```ruby
response = client.reports.utm(
  website_id,
  start_date,
  end_date
)

if response.data['utm_content'] && response.data['utm_content'].length > 0
  contents = response.data['utm_content'].sort_by { |c| -c['views'] }
  total_views = contents.sum { |c| c['views'] }

  puts "Content Variation Performance:"
  contents.each do |content|
    views = content['views']
    percentage = (views.to_f / total_views * 100).round(1)

    puts "#{content['utm']}: #{views} views (#{percentage}%)"
  end

  # Determine winner
  winner = contents.first
  loser = contents.last
  improvement = ((winner['views'].to_f / loser['views'] - 1) * 100).round(1)

  puts "\nA/B Test Results:"
  puts "  Winner: #{winner['utm']} (#{winner['views']} views)"
  puts "  Runner-up: #{loser['utm']} (#{loser['views']} views)"
  puts "  Improvement: #{improvement}%"
end
 Content Variation Performance:
 hero_image_a: 1,450 views (58.0%)
 hero_image_b: 1,050 views (42.0%)
 A/B Test Results:
   Winner: hero_image_a (1,450 views)
   Runner-up: hero_image_b (1,050 views)
   Improvement: 38.1%
```

## Keyword Analysis (Paid Search)

```ruby
response = client.reports.utm(
  website_id,
  start_date,
  end_date
)

if response.data['utm_term'] && response.data['utm_term'].length > 0
  terms = response.data['utm_term'].sort_by { |t| -t['views'] }
  total_views = terms.sum { |t| t['views'] }

  puts "Keyword Performance:"
  terms.each_with_index do |term, index|
    views = term['views']
    percentage = (views.to_f / total_views * 100).round(1)

    puts "#{index + 1}. #{term['utm']}: #{views} views (#{percentage}%)"
  end

  # Top keywords
  top_keywords = terms.take(5)
  puts "\nTop 5 Keywords:"
  top_keywords.each do |keyword|
    puts "  #{keyword['utm']}: #{keyword['views']} views"
  end
end
 Keyword Performance:
 1. analytics_software: 340 views (34.0%)
 2. website_tracking: 280 views (28.0%)
 3. user_analytics: 210 views (21.0%)
 4. web_metrics: 120 views (12.0%)
 5. visitor_tracking: 50 views (5.0%)
```

## Multi-Channel Attribution

```ruby
 Analyze all UTM parameters together
response = client.reports.utm(
  website_id,
  start_date,
  end_date
)

 Calculate channel effectiveness
sources = response.data['utm_source']
mediums = response.data['utm_medium']
campaigns = response.data['utm_campaign']

puts "Marketing Channel Overview:"
puts "\nSources: #{sources.length} active"
puts "Mediums: #{mediums.length} active"
puts "Campaigns: #{campaigns.length} active"

 Total UTM-tagged traffic
total_source_views = sources.sum { |s| s['views'] }
total_medium_views = mediums.sum { |m| m['views'] }
total_campaign_views = campaigns.sum { |c| c['views'] }

puts "\nTotal UTM-tagged pageviews:"
puts "  By source: #{total_source_views}"
puts "  By medium: #{total_medium_views}"
puts "  By campaign: #{total_campaign_views}"

 Top performers in each category
puts "\nTop Performers:"
puts "  Source: #{sources.max_by { |s| s['views'] }['utm']} (#{sources.max_by { |s| s['views'] }['views']} views)"
puts "  Medium: #{mediums.max_by { |m| m['views'] }['utm']} (#{mediums.max_by { |m| m['views'] }['views']} views)"
puts "  Campaign: #{campaigns.max_by { |c| c['views'] }['utm']} (#{campaigns.max_by { |c| c['views'] }['views']} views)"
 Marketing Channel Overview:
 Sources: 8 active
 Mediums: 5 active
 Campaigns: 6 active
 Total UTM-tagged pageviews:
   By source: 4,120
   By medium: 3,740
   By campaign: 4,460
 Top Performers:
   Source: google (1,450 views)
   Medium: cpc (1,450 views)
   Campaign: summer_sale_2025 (1,890 views)
```

## Period Comparison

```ruby
 Compare campaign performance across time periods
def get_utm_data(client, website_id, start_date, end_date)
  response = client.reports.utm(website_id, start_date, end_date)
  response.data
end

 Current period (last 30 days)
current_end = Time.now
current_start = current_end - (30 * 24 * 60 * 60)

current = get_utm_data(
  client,
  website_id,
  current_start.utc.iso8601(3),
  current_end.utc.iso8601(3)
)

 Previous period (30 days before that)
previous_end = current_start
previous_start = previous_end - (30 * 24 * 60 * 60)

previous = get_utm_data(
  client,
  website_id,
  previous_start.utc.iso8601(3),
  previous_end.utc.iso8601(3)
)

 Compare campaigns
current_campaigns = current['utm_campaign'].each_with_object({}) do |c, hash|
  hash[c['utm']] = c['views']
end

previous_campaigns = previous['utm_campaign'].each_with_object({}) do |c, hash|
  hash[c['utm']] = c['views']
end

puts "Campaign Performance Comparison:"
current_campaigns.each do |campaign, views|
  prev_views = previous_campaigns[campaign] || 0

  if prev_views > 0
    change = views - prev_views
    change_pct = ((views.to_f / prev_views - 1) * 100).round(1)
    indicator = change >= 0 ? "↑" : "↓"

    puts "#{campaign}:"
    puts "  Current: #{views} views"
    puts "  Previous: #{prev_views} views"
    puts "  Change: #{change} views #{indicator} #{change_pct.abs}%"
  else
    puts "#{campaign}: #{views} views (new)"
  end
  puts
end
 Campaign Performance Comparison:
 summer_sale_2025:
   Current: 1,890 views
   Previous: 1,450 views
   Change: 440 views ↑ 30.3%
 product_launch_q3:
   Current: 1,240 views
   Previous: 890 views
   Change: 350 views ↑ 39.3%
 newsletter_july: 670 views (new)
```

## ROI Analysis

```ruby
 Combine UTM reports with revenue data (if available)
utm_response = client.reports.utm(
  website_id,
  start_date,
  end_date
)

 Get revenue by campaign (using filters)
campaign_roi = utm_response.data['utm_campaign'].map do |campaign|
  # Get revenue for this campaign
  revenue_response = client.reports.revenue(
    website_id,
    start_date,
    end_date,
    "UTC",
    "USD",
    filters: [
      { type: 'utm_campaign', value: campaign['utm'] }
    ]
  )

  revenue = revenue_response.data['total']['sum']
  transactions = revenue_response.data['total']['count']

  {
    campaign: campaign['utm'],
    views: campaign['views'],
    revenue: revenue,
    transactions: transactions,
    conversion_rate: (transactions.to_f / campaign['views'] * 100).round(2),
    revenue_per_view: (revenue.to_f / campaign['views']).round(2)
  }
end.sort_by { |c| -c[:revenue] }

puts "Campaign ROI Analysis:"
campaign_roi.each do |data|
  puts "\n#{data[:campaign]}:"
  puts "  Views: #{data[:views]}"
  puts "  Transactions: #{data[:transactions]}"
  puts "  Revenue: $#{data[:revenue]}"
  puts "  Conversion Rate: #{data[:conversion_rate]}%"
  puts "  Revenue per View: $#{data[:revenue_per_view]}"
end
 Campaign ROI Analysis:
 summer_sale_2025:
   Views: 1,890
   Transactions: 78
   Revenue: $3,450
   Conversion Rate: 4.13%
   Revenue per View: $1.83
 product_launch_q3:
   Views: 1,240
   Transactions: 45
   Revenue: $2,890
   Conversion Rate: 3.63%
   Revenue per View: $2.33
```

## Source Quality Scoring

```ruby
response = client.reports.utm(
  website_id,
  start_date,
  end_date
)

 Score sources based on volume
sources = response.data['utm_source'].map do |source|
  views = source['views']
  total = response.data['utm_source'].sum { |s| s['views'] }
  percentage = (views.to_f / total * 100).round(1)

  # Quality score: volume + consistency
  quality_score = case percentage
  when 0..5 then 'Low'
  when 5..15 then 'Medium'
  when 15..30 then 'High'
  else 'Very High'
  end

  {
    source: source['utm'],
    views: views,
    percentage: percentage,
    quality: quality_score
  }
end.sort_by { |s| -s[:views] }

puts "Traffic Source Quality Scores:"
sources.each do |data|
  puts "#{data[:source]}:"
  puts "  Views: #{data[:views]} (#{data[:percentage]}%)"
  puts "  Quality: #{data[:quality]}"
end
 Traffic Source Quality Scores:
 google:
   Views: 1,450 (35.2%)
   Quality: Very High
 facebook:
   Views: 890 (21.6%)
   Quality: High
 twitter:
   Views: 670 (16.3%)
   Quality: High
 linkedin:
   Views: 340 (8.3%)
   Quality: Medium
 newsletter:
   Views: 120 (2.9%)
   Quality: Low
```

## Best Practices for UTM Tracking

**Naming Conventions:**
```ruby
 Use consistent, lowercase naming
 Good:
utm_source=google&utm_medium=cpc&utm_campaign=summer_sale

 Avoid:
utm_source=Google&utm_medium=CPC&utm_campaign=Summer Sale
```

**Standard UTM Medium Values:**
```ruby
 Organic social: social
 Paid social: paid_social or cpc
 Email: email
 Display ads: display
 Paid search: cpc or ppc
 Organic search: organic
 Referral: referral
 Direct: (none)
 Affiliate: affiliate
```

**Campaign Naming Structure:**
```ruby
 Format: {campaign_name}_{variant}_{year}
utm_campaign=summer_sale_a_2025
utm_campaign=product_launch_mobile_2025
utm_campaign=newsletter_july_2025

 Include:
 - Descriptive name
 - Variant (if A/B testing)
 - Time period
```

## Common UTM Patterns

**Email Campaigns:**
```ruby
utm_source=newsletter
utm_medium=email
utm_campaign=weekly_digest_july
utm_content=cta_button
```

**Paid Search:**
```ruby
utm_source=google
utm_medium=cpc
utm_campaign=brand_keywords
utm_term=analytics_software
```

**Social Media:**
```ruby
utm_source=facebook
utm_medium=paid_social
utm_campaign=product_launch
utm_content=video_ad_a
```

**Content Marketing:**
```ruby
utm_source=guest_blog
utm_medium=referral
utm_campaign=thought_leadership
utm_content=article_link
```

## Industry Benchmarks

**Click-Through Rates by Medium:**
```ruby
 Email: 2-5%
 Paid search: 3-5%
 Display ads: 0.1-0.5%
 Social media (organic): 1-3%
 Social media (paid): 1-2%
```

**Campaign Effectiveness:**
```ruby
 Top 20% of campaigns drive 80% of results (80/20 rule)
 Successful campaigns: 3%+ conversion rate
 Average campaigns: 1-3% conversion rate
 Poor campaigns: <1% conversion rate
```

**Source Quality:**
```ruby
 High-quality sources: 20%+ of total traffic
 Medium-quality: 5-20% of total traffic
 Low-quality: <5% of total traffic
 Consider pausing sources with <100 views/month
```

