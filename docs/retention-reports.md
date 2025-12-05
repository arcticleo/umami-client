# Executing Retention Reports

Retention reports measure website stickiness by tracking how often users return over time. Using cohort analysis, retention reports show return rates for users who first visited on specific dates, helping you understand engagement trends and user loyalty.

## Basic Retention Analysis

```ruby
 Analyze 30-day retention
response = client.reports.retention(
  "website-id",
  Time.now - 30.days,
  Time.now,
  "UTC"
)

 Display key retention metrics
puts "Retention Analysis:"
[1, 7, 14, 30].each do |day|
  data = response.body.find { |d| d['day'] == day }
  if data
    puts "Day #{day}: #{data['percentage']}% returned (#{data['returnVisitors']} users)"
  end
end
```

## Understanding Retention Data

The retention report returns cohort data showing:
- **date**: Cohort start date (when users first visited)
- **day**: Days elapsed since cohort formation (0, 1, 7, 14, 30, etc.)
- **visitors**: Initial cohort size (new users on that date)
- **returnVisitors**: Count of users who returned on that day
- **percentage**: Return rate (returnVisitors / visitors * 100)

## Key Retention Milestones

```ruby
response = client.reports.retention(
  "website-id",
  Time.now - 90.days,
  Time.now,
  "UTC"
)

 Extract key milestones
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

## Cohort Analysis

Group retention data by cohort to compare different time periods:

```ruby
response = client.reports.retention(
  "website-id",
  Time.now - 90.days,
  Time.now,
  "UTC"
)

 Group by cohort date
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

## Retention by Device

Compare retention across different devices:

```ruby
 Mobile retention
mobile_response = client.reports.retention(
  "website-id",
  Time.now - 30.days,
  Time.now,
  "UTC",
  filters: { device: "mobile" }
)

 Desktop retention
desktop_response = client.reports.retention(
  "website-id",
  Time.now - 30.days,
  Time.now,
  "UTC",
  filters: { device: "desktop" }
)

 Compare day-7 retention
mobile_day7 = mobile_response.body.find { |d| d['day'] == 7 }
desktop_day7 = desktop_response.body.find { |d| d['day'] == 7 }

puts "Day-7 Retention Comparison:"
puts "  Mobile:  #{mobile_day7['percentage']}%"
puts "  Desktop: #{desktop_day7['percentage']}%"
```

## Geographic Retention Differences

```ruby
 US retention
us_response = client.reports.retention(
  "website-id",
  Time.now - 30.days,
  Time.now,
  "America/New_York",
  filters: { country: "US" }
)

 EU retention
eu_response = client.reports.retention(
  "website-id",
  Time.now - 30.days,
  Time.now,
  "Europe/London",
  filters: { country: "GB" }
)

 Compare
us_day30 = us_response.body.find { |d| d['day'] == 30 }['percentage']
eu_day30 = eu_response.body.find { |d| d['day'] == 30 }['percentage']

puts "Day-30 Retention by Region:"
puts "  US: #{us_day30}%"
puts "  EU: #{eu_day30}%"
```

## Retention Curve Visualization

```ruby
response = client.reports.retention(
  "website-id",
  Time.now - 60.days,
  Time.now,
  "UTC"
)

 Calculate average retention for each day
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

## Timezone Considerations

Always use the appropriate timezone for your user base:

```ruby
 US West Coast
client.reports.retention(website_id, start_date, end_date, "America/Los_Angeles")

 US East Coast
client.reports.retention(website_id, start_date, end_date, "America/New_York")

 Europe
client.reports.retention(website_id, start_date, end_date, "Europe/London")

 Asia
client.reports.retention(website_id, start_date, end_date, "Asia/Tokyo")

 UTC (global audience)
client.reports.retention(website_id, start_date, end_date, "UTC")
```

## Retention Benchmarks by Industry

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

 Evaluate performance
if day_7_retention >= 40
  puts "\n✓ Excellent day-7 retention!"
elsif day_7_retention >= 25
  puts "\n→ Good day-7 retention"
else
  puts "\n⚠ Day-7 retention needs improvement"
end
```

## Complete Retention Analysis Example

```ruby
 Comprehensive retention analysis
start_date = Time.now - 90.days
end_date = Time.now

puts "Comprehensive Retention Analysis"
puts "=" * 50

 Overall retention
overall = client.reports.retention(
  website_id,
  start_date,
  end_date,
  "UTC"
)

 Segment by device
mobile = client.reports.retention(
  website_id, start_date, end_date, "UTC",
  filters: { device: "mobile" }
)

desktop = client.reports.retention(
  website_id, start_date, end_date, "UTC",
  filters: { device: "desktop" }
)

 Extract key metrics
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

 Calculate retention drop-off
day_1 = get_retention(overall, 1)
day_30 = get_retention(overall, 30)
dropoff = day_1 - day_30
puts "\nRetention Drop-off (Day 1 → Day 30):"
puts "  #{day_1}% → #{day_30}%"
puts "  Drop-off: #{dropoff.round(1)} percentage points"

 Analyze cohorts
cohorts = overall.body.group_by { |d| d['date'] }
recent_cohorts = cohorts.keys.sort.last(5)

puts "\nRecent Cohort Performance:"
recent_cohorts.each do |date|
  cohort_data = cohorts[date]
  size = cohort_data.first['visitors']
  d7 = cohort_data.find { |d| d['day'] == 7 }&.fetch('percentage', 0)
  puts "  #{date}: #{size} users, #{d7}% day-7 retention"
end

 Identify trends
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

## Retention Improvement Strategies

Based on your retention data, consider these strategies:

**If Day-1 retention is low (<30%):**
```ruby
 Low day-1 suggests poor first impression
 - Improve onboarding experience
 - Add welcome emails/notifications
 - Highlight key features immediately
 - Reduce friction in first session
```

**If Day-7 retention drops significantly:**
```ruby
 Drop between day 1-7 suggests value not clear
 - Send engagement emails days 2-5
 - Add feature discovery prompts
 - Implement progress indicators
 - Create habit-forming loops
```

**If Day-30 retention is low:**
```ruby
 Low monthly retention suggests lack of long-term value
 - Add new content/features regularly
 - Implement notification system
 - Create user communities
 - Offer premium features
```

**If mobile retention < desktop:**
```ruby
 Mobile experience may need improvement
 - Optimize mobile UI/UX
 - Reduce mobile load times
 - Add push notifications
 - Improve mobile onboarding
```

