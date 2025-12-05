# Executing Funnel Reports

Funnel reports analyze user progression through sequential steps to identify conversion rates and drop-off points. This is essential for understanding where users abandon processes like signup, checkout, or onboarding.

## Basic Funnel Analysis

```ruby
 Simple signup funnel
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

 Analyze results
response.body.each_with_index do |step, index|
  puts "Step #{index + 1}: #{step['visitors']} visitors"
  puts "  Conversion rate: #{step['conversionRate']}%"
  puts "  Drop-off rate: #{step['dropoffRate']}%"
end
```

## Funnel Step Types

Funnels support two types of steps:

**Path steps** - Track specific URL paths:
```ruby
{ type: "path", value: "/checkout" }
```

**Event steps** - Track custom events:
```ruby
{ type: "event", value: "add_to_cart" }
```

## E-commerce Checkout Funnel

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

 Calculate overall conversion
first_step = response.body.first
last_step = response.body.last
overall_conversion = (last_step['visitors'].to_f / first_step['visitors'] * 100).round(2)
puts "Overall conversion: #{overall_conversion}%"
```

## Onboarding Funnel

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

 Identify drop-off points
response.body.each_with_index do |step, index|
  if step['dropoffRate'] > 50
    puts "⚠️  High drop-off at step #{index + 1}: #{step['dropoffRate']}%"
  end
end
```

## Conversion Windows

The `window` parameter specifies how many days users have to complete the funnel:

```ruby
 Strict same-session funnel (1 day)
client.reports.funnel(website_id, start_date, end_date, steps, 1)

 Week-long conversion window
client.reports.funnel(website_id, start_date, end_date, steps, 7)

 Month-long conversion window
client.reports.funnel(website_id, start_date, end_date, steps, 30)

 Quarter-long conversion window
client.reports.funnel(website_id, start_date, end_date, steps, 90)
```

## Filtering Funnels

Apply filters to analyze specific user segments:

```ruby
 US visitors only
client.reports.funnel(
  website_id, start_date, end_date, steps, 30,
  filters: { country: "US" }
)

 Mobile users only
client.reports.funnel(
  website_id, start_date, end_date, steps, 30,
  filters: { device: "mobile" }
)

 Specific browser
client.reports.funnel(
  website_id, start_date, end_date, steps, 30,
  filters: { browser: "chrome" }
)

 Multiple filters
client.reports.funnel(
  website_id, start_date, end_date, steps, 30,
  filters: {
    country: "US",
    device: "mobile",
    os: "ios"
  }
)
```

## Common Funnel Patterns

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

## Complete Funnel Analysis Example

```ruby
 Define analysis period
start_date = Time.now - 30.days
end_date = Time.now

 Execute funnel
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

 Calculate overall metrics
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

