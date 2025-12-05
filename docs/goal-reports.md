# Executing Goal Reports

Goal reports track single conversion points like newsletter signups, demo requests, or important page visits. Unlike funnels (which track multi-step journeys), goals measure completion of one specific action independently, making them ideal for monitoring key conversion metrics.

## Basic Goal Tracking

```ruby
 Track newsletter signup completions
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

## Goals vs Funnels

**Goals** track single conversion points:
- One specific action (page visit or event)
- Simple completion tracking
- Good for: KPI monitoring, conversion rates, A/B testing

**Funnels** track multi-step journeys:
- Sequential steps with drop-off analysis
- More complex user paths
- Good for: process optimization, identifying bottlenecks

## Path-Based Goals

Track visits to important pages:

```ruby
 Thank you page (purchase confirmation)
response = client.reports.goals(
  "website-id",
  Time.now - 7.days,
  Time.now,
  "path",
  "/thank-you"
)

purchases = response.body['num']
puts "Purchases this week: #{purchases}"

 Pricing page visits
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

## Event-Based Goals

Track custom event completions:

```ruby
 Demo request goal
response = client.reports.goals(
  "website-id",
  Time.now - 30.days,
  Time.now,
  "event",
  "demo_request"
)

demos = response.body['num']
puts "Demo requests: #{demos}"

 Video play completions
response = client.reports.goals(
  "website-id",
  Time.now - 7.days,
  Time.now,
  "event",
  "video_play"
)

plays = response.body['num']
puts "Video plays: #{plays}"

 Add to cart events
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

## Segmented Goal Tracking

Filter goals by user segments:

```ruby
 US visitor conversions
us_response = client.reports.goals(
  "website-id",
  Time.now - 30.days,
  Time.now,
  "event",
  "purchase",
  filters: { country: "US" }
)

 EU visitor conversions
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

## Mobile vs Desktop Goal Performance

```ruby
 Mobile conversions
mobile_response = client.reports.goals(
  "website-id",
  Time.now - 30.days,
  Time.now,
  "event",
  "signup",
  filters: { device: "mobile" }
)

 Desktop conversions
desktop_response = client.reports.goals(
  "website-id",
  Time.now - 30.days,
  Time.now,
  "event",
  "signup",
  filters: { device: "desktop" }
)

 Calculate conversion rates
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

## Multiple Goal Tracking

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

## Weekly Goal Monitoring

```ruby
 Get last 4 weeks of data
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

 Identify trend
if weeks.first[:completions] < weeks.last[:completions]
  puts "\n✓ Signups trending up!"
else
  puts "\n⚠ Signups declining"
end
```

## Common Goal Patterns

**E-commerce Goals:**
```ruby
 Purchase completion
client.reports.goals(website_id, start_date, end_date, "event", "purchase")

 Add to cart
client.reports.goals(website_id, start_date, end_date, "event", "add_to_cart")

 Checkout started
client.reports.goals(website_id, start_date, end_date, "path", "/checkout")

 Thank you page
client.reports.goals(website_id, start_date, end_date, "path", "/thank-you")
```

**SaaS Goals:**
```ruby
 Trial signup
client.reports.goals(website_id, start_date, end_date, "event", "trial_start")

 Demo request
client.reports.goals(website_id, start_date, end_date, "event", "demo_request")

 Pricing page visit
client.reports.goals(website_id, start_date, end_date, "path", "/pricing")

 Payment added
client.reports.goals(website_id, start_date, end_date, "event", "payment_added")
```

**Content Goals:**
```ruby
 Newsletter signup
client.reports.goals(website_id, start_date, end_date, "event", "newsletter_signup")

 Article read (scroll to bottom)
client.reports.goals(website_id, start_date, end_date, "event", "article_complete")

 Social share
client.reports.goals(website_id, start_date, end_date, "event", "share")

 Comment posted
client.reports.goals(website_id, start_date, end_date, "event", "comment")
```

**Lead Generation Goals:**
```ruby
 Contact form submission
client.reports.goals(website_id, start_date, end_date, "event", "contact_form")

 Phone click
client.reports.goals(website_id, start_date, end_date, "event", "phone_click")

 Email click
client.reports.goals(website_id, start_date, end_date, "event", "email_click")

 Download whitepaper
client.reports.goals(website_id, start_date, end_date, "event", "download")
```

## Goal Benchmarks by Industry

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

 Evaluate performance
if conversion_rate >= 5
  puts "\n✓ Excellent conversion rate!"
elsif conversion_rate >= 2
  puts "\n→ Good conversion rate"
else
  puts "\n⚠ Conversion rate needs improvement"
end
```

## Complete Goal Analysis Example

```ruby
 Comprehensive goal tracking dashboard
start_date = Time.now - 30.days
end_date = Time.now

puts "Conversion Goals Dashboard"
puts "=" * 50
puts "Period: #{start_date.strftime('%Y-%m-%d')} to #{end_date.strftime('%Y-%m-%d')}"

 Primary conversion goal
purchase_response = client.reports.goals(
  website_id, start_date, end_date, "event", "purchase"
)
purchases = purchase_response.body['num']
total_events = purchase_response.body['total']
purchase_rate = (purchases.to_f / total_events * 100).round(2)

puts "\nPrimary Goal: Purchases"
puts "  Total: #{purchases}"
puts "  Conversion rate: #{purchase_rate}%"

 Micro-conversions
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

 Segment analysis
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

 Calculate goal value (if applicable)
average_order_value = 99.99  # Your AOV
goal_value = purchases * average_order_value

puts "\n" + "=" * 50
puts "Summary:"
puts "  Total conversions: #{purchases}"
puts "  Conversion rate: #{purchase_rate}%"
puts "  Goal value: $#{goal_value.round(2)}"
puts "  Value per visitor: $#{(goal_value / total_events).round(2)}"
```

## Goal Optimization Tips

**If conversion rate is low:**
```ruby
 - Simplify the conversion process
 - Improve call-to-action visibility
 - Reduce form fields
 - Add trust signals (testimonials, badges)
 - Optimize page load speed
 - A/B test different approaches
```

**To track goal effectiveness:**
```ruby
 Monitor weekly trends
 Compare segments (mobile vs desktop)
 Test different traffic sources
 Analyze drop-off points
 Calculate goal value
 Set up alerts for significant changes
```

**Multi-goal strategy:**
```ruby
 Primary goal: Final conversion (purchase, signup)
 Secondary goals: Micro-conversions (cart, pricing page)
 Engagement goals: Content interactions (video, scroll)
 Lead goals: Contact form, demo request
```

