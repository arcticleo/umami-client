# Executing Revenue Reports

Revenue reports enable tracking and analysis of financial data associated with user conversions and transactions. They provide time-series data, geographic distribution, and aggregate statistics including sum, count, unique visitors, and average transaction value.

## Basic Usage

```ruby
 Basic revenue report
response = client.reports.revenue(
  website_id,
  start_date,
  end_date,
  "America/New_York",
  "USD"
)

 Aggregate totals
totals = response.data['total']
puts "Total Revenue: $#{totals['sum']}"
puts "Transactions: #{totals['count']}"
puts "Unique Customers: #{totals['unique_count']}"
puts "Average Order Value: $#{totals['average'].round(2)}"
 Total Revenue: $45,230
 Transactions: 1,234
 Unique Customers: 1,189
 Average Order Value: $36.65
```

## Response Structure

Revenue reports return three key data sections:

```ruby
response = client.reports.revenue(website_id, start_date, end_date, timezone, currency)

 1. Chart - Time-series revenue data
response.data['chart'].each do |point|
  date = Time.parse(point['t']).strftime('%Y-%m-%d')
  puts "#{date}: $#{point['y']}"
end
 2025-10-14: $1,450
 2025-10-15: $2,340
 2025-10-16: $1,890

 2. Country - Geographic distribution
response.data['country'].each do |country|
  puts "#{country['name']}: $#{country['value']}"
end
 US: $25,340
 GB: $12,450
 DE: $7,440

 3. Total - Aggregate statistics
totals = response.data['total']
 sum: Total revenue
 count: Number of transactions
 unique_count: Number of unique customers
 average: Average order value
```

## Currency Support

Revenue reports support any ISO 4217 currency code:

```ruby
 US Dollars
response = client.reports.revenue(
  website_id,
  start_date,
  end_date,
  "America/New_York",
  "USD"
)

 Euros
response = client.reports.revenue(
  website_id,
  start_date,
  end_date,
  "Europe/Paris",
  "EUR"
)

 British Pounds
response = client.reports.revenue(
  website_id,
  start_date,
  end_date,
  "Europe/London",
  "GBP"
)

 Japanese Yen
response = client.reports.revenue(
  website_id,
  start_date,
  end_date,
  "Asia/Tokyo",
  "JPY"
)
```

## Time-Series Analysis

```ruby
 Last 30 days revenue trend
start_date = (Time.now - (30 * 24 * 60 * 60)).utc.iso8601(3)
end_date = Time.now.utc.iso8601(3)

response = client.reports.revenue(
  website_id,
  start_date,
  end_date,
  "UTC",
  "USD"
)

 Calculate daily statistics
revenues = response.data['chart'].map { |p| p['y'] }
avg_daily = revenues.sum.to_f / revenues.length
max_daily = revenues.max
min_daily = revenues.min

puts "Daily Statistics (30 days):"
puts "  Average: $#{avg_daily.round(2)}"
puts "  Maximum: $#{max_daily}"
puts "  Minimum: $#{min_daily}"
puts "  Total: $#{revenues.sum}"
 Daily Statistics (30 days):
   Average: $1,507.67
   Maximum: $3,450
   Minimum: $890
   Total: $45,230

 Identify best and worst days
chart_data = response.data['chart'].map do |point|
  { date: Time.parse(point['t']), revenue: point['y'] }
end

best_day = chart_data.max_by { |d| d[:revenue] }
worst_day = chart_data.min_by { |d| d[:revenue] }

puts "\nBest Day: #{best_day[:date].strftime('%A, %B %d')}: $#{best_day[:revenue]}"
puts "Worst Day: #{worst_day[:date].strftime('%A, %B %d')}: $#{worst_day[:revenue]}"
 Best Day: Saturday, October 14: $3,450
 Worst Day: Tuesday, October 3: $890
```

## Geographic Revenue Analysis

```ruby
response = client.reports.revenue(
  website_id,
  start_date,
  end_date,
  "UTC",
  "USD"
)

total_revenue = response.data['total']['sum']

puts "Revenue by Country:"
response.data['country'].each do |country|
  revenue = country['value']
  percentage = (revenue.to_f / total_revenue * 100).round(1)

  puts "#{country['name']}:"
  puts "  Revenue: $#{revenue}"
  puts "  Percentage: #{percentage}%"
end
 Revenue by Country:
 US:
   Revenue: $25,340
   Percentage: 56.0%
 GB:
   Revenue: $12,450
   Percentage: 27.5%
 DE:
   Revenue: $7,440
   Percentage: 16.5%
```

## Device-Specific Revenue

```ruby
 Mobile revenue
mobile_response = client.reports.revenue(
  website_id,
  start_date,
  end_date,
  "America/New_York",
  "USD",
  filters: [
    { type: 'device', value: 'mobile' }
  ]
)

 Desktop revenue
desktop_response = client.reports.revenue(
  website_id,
  start_date,
  end_date,
  "America/New_York",
  "USD",
  filters: [
    { type: 'device', value: 'desktop' }
  ]
)

mobile_total = mobile_response.data['total']['sum']
mobile_aov = mobile_response.data['total']['average']

desktop_total = desktop_response.data['total']['sum']
desktop_aov = desktop_response.data['total']['average']

puts "Mobile Revenue: $#{mobile_total} (AOV: $#{mobile_aov.round(2)})"
puts "Desktop Revenue: $#{desktop_total} (AOV: $#{desktop_aov.round(2)})"
 Mobile Revenue: $18,900 (AOV: $28.45)
 Desktop Revenue: $26,330 (AOV: $42.18)

 Calculate contribution
total = mobile_total + desktop_total
mobile_pct = (mobile_total.to_f / total * 100).round(1)
desktop_pct = (desktop_total.to_f / total * 100).round(1)

puts "Mobile: #{mobile_pct}% | Desktop: #{desktop_pct}%"
 Mobile: 41.8% | Desktop: 58.2%
```

## Country-Specific Analysis

```ruby
 US revenue
us_response = client.reports.revenue(
  website_id,
  start_date,
  end_date,
  "America/New_York",
  "USD",
  filters: [
    { type: 'country', value: 'US' }
  ]
)

 UK revenue
uk_response = client.reports.revenue(
  website_id,
  start_date,
  end_date,
  "Europe/London",
  "GBP",
  filters: [
    { type: 'country', value: 'GB' }
  ]
)

us_totals = us_response.data['total']
puts "US Market:"
puts "  Revenue: $#{us_totals['sum']}"
puts "  Transactions: #{us_totals['count']}"
puts "  AOV: $#{us_totals['average'].round(2)}"

uk_totals = uk_response.data['total']
puts "\nUK Market:"
puts "  Revenue: £#{uk_totals['sum']}"
puts "  Transactions: #{uk_totals['count']}"
puts "  AOV: £#{uk_totals['average'].round(2)}"
 US Market:
   Revenue: $25,340
   Transactions: 678
   AOV: $37.38
 UK Market:
   Revenue: £9,850
   Transactions: 342
   AOV: £28.80
```

## Segmented Revenue Analysis

```ruby
 Analyze revenue by device and country combination
devices = ['mobile', 'desktop']
countries = ['US', 'GB', 'DE']

results = {}

devices.each do |device|
  countries.each do |country|
    response = client.reports.revenue(
      website_id,
      start_date,
      end_date,
      "UTC",
      "USD",
      filters: [
        { type: 'device', value: device },
        { type: 'country', value: country }
      ]
    )

    totals = response.data['total']
    results["#{country}/#{device}"] = {
      revenue: totals['sum'],
      transactions: totals['count'],
      aov: totals['average']
    }
  end
end

 Display matrix
puts "Revenue by Device & Country:"
countries.each do |country|
  puts "\n#{country}:"
  devices.each do |device|
    data = results["#{country}/#{device}"]
    puts "  #{device.capitalize}: $#{data[:revenue]} (#{data[:transactions]} txns, $#{data[:aov].round(2)} AOV)"
  end
end
 Revenue by Device & Country:
 US:
   Mobile: $10,450 (412 txns, $25.36 AOV)
   Desktop: $14,890 (266 txns, $55.98 AOV)
 GB:
   Mobile: $5,230 (189 txns, $27.67 AOV)
   Desktop: $7,220 (153 txns, $47.19 AOV)
```

## Period Comparison

```ruby
 Compare two time periods
def get_period_revenue(client, website_id, start_date, end_date)
  response = client.reports.revenue(
    website_id,
    start_date,
    end_date,
    "UTC",
    "USD"
  )
  response.data['total']
end

 Current period (last 30 days)
current_end = Time.now
current_start = current_end - (30 * 24 * 60 * 60)

current = get_period_revenue(
  client,
  website_id,
  current_start.utc.iso8601(3),
  current_end.utc.iso8601(3)
)

 Previous period (30 days before that)
previous_end = current_start
previous_start = previous_end - (30 * 24 * 60 * 60)

previous = get_period_revenue(
  client,
  website_id,
  previous_start.utc.iso8601(3),
  previous_end.utc.iso8601(3)
)

 Calculate changes
revenue_change = current['sum'] - previous['sum']
revenue_change_pct = ((current['sum'].to_f / previous['sum'] - 1) * 100).round(1)

txn_change = current['count'] - previous['count']
txn_change_pct = ((current['count'].to_f / previous['count'] - 1) * 100).round(1)

aov_change = current['average'] - previous['average']
aov_change_pct = ((current['average'] / previous['average'] - 1) * 100).round(1)

puts "Period Comparison (Last 30 Days vs Previous 30 Days):"
puts "\nRevenue:"
puts "  Current: $#{current['sum']}"
puts "  Previous: $#{previous['sum']}"
puts "  Change: $#{revenue_change} (#{revenue_change_pct}%)"

puts "\nTransactions:"
puts "  Current: #{current['count']}"
puts "  Previous: #{previous['count']}"
puts "  Change: #{txn_change} (#{txn_change_pct}%)"

puts "\nAverage Order Value:"
puts "  Current: $#{current['average'].round(2)}"
puts "  Previous: $#{previous['average'].round(2)}"
puts "  Change: $#{aov_change.round(2)} (#{aov_change_pct}%)"
 Period Comparison (Last 30 Days vs Previous 30 Days):
 Revenue:
   Current: $45,230
   Previous: $38,450
   Change: $6,780 (17.6%)
 Transactions:
   Current: 1,234
   Previous: 1,089
   Change: 145 (13.3%)
 Average Order Value:
   Current: $36.65
   Previous: $35.31
   Change: $1.34 (3.8%)
```

## Revenue Growth Tracking

```ruby
 Track monthly revenue growth
months = 6
monthly_data = []

months.times do |i|
  month_end = Time.now - (i * 30 * 24 * 60 * 60)
  month_start = month_end - (30 * 24 * 60 * 60)

  response = client.reports.revenue(
    website_id,
    month_start.utc.iso8601(3),
    month_end.utc.iso8601(3),
    "UTC",
    "USD"
  )

  totals = response.data['total']
  monthly_data << {
    month: month_end.strftime('%B %Y'),
    revenue: totals['sum'],
    transactions: totals['count'],
    aov: totals['average']
  }
end

puts "6-Month Revenue Trend:"
monthly_data.reverse.each_with_index do |data, index|
  if index > 0
    prev = monthly_data.reverse[index - 1]
    growth = ((data[:revenue].to_f / prev[:revenue] - 1) * 100).round(1)
    growth_indicator = growth >= 0 ? "↑" : "↓"

    puts "#{data[:month]}: $#{data[:revenue]} #{growth_indicator} #{growth.abs}%"
  else
    puts "#{data[:month]}: $#{data[:revenue]}"
  end
end
 6-Month Revenue Trend:
 May 2025: $32,450
 June 2025: $35,890 ↑ 10.6%
 July 2025: $38,450 ↑ 7.1%
 August 2025: $41,230 ↑ 7.2%
 September 2025: $43,560 ↑ 5.6%
 October 2025: $45,230 ↑ 3.8%
```

## Customer Segmentation by Value

```ruby
 Get overall revenue data
response = client.reports.revenue(
  website_id,
  start_date,
  end_date,
  "UTC",
  "USD"
)

totals = response.data['total']
total_revenue = totals['sum']
total_customers = totals['unique_count']
aov = totals['average']

 Analyze geographic segments
country_data = response.data['country'].map do |country|
  # Get country-specific details
  country_response = client.reports.revenue(
    website_id,
    start_date,
    end_date,
    "UTC",
    "USD",
    filters: [
      { type: 'country', value: country['name'] }
    ]
  )

  country_totals = country_response.data['total']

  {
    country: country['name'],
    revenue: country['value'],
    customers: country_totals['unique_count'],
    aov: country_totals['average'],
    revenue_per_customer: country['value'].to_f / country_totals['unique_count']
  }
end

 Sort by revenue per customer (customer value)
country_data.sort_by! { |c| -c[:revenue_per_customer] }

puts "Customer Value by Country:"
country_data.each do |data|
  puts "\n#{data[:country]}:"
  puts "  Total Revenue: $#{data[:revenue]}"
  puts "  Customers: #{data[:customers]}"
  puts "  AOV: $#{data[:aov].round(2)}"
  puts "  Revenue/Customer: $#{data[:revenue_per_customer].round(2)}"
end
 Customer Value by Country:
 US:
   Total Revenue: $25,340
   Customers: 612
   AOV: $37.38
   Revenue/Customer: $41.41
 GB:
   Total Revenue: $12,450
   Customers: 328
   AOV: $30.12
   Revenue/Customer: $37.96
```

## Revenue Attribution

Combine revenue reports with other filters to understand revenue attribution:

```ruby
 Revenue by traffic source (referrer)
referrers = ['google.com', 'facebook.com', 'twitter.com', '(direct)']

puts "Revenue by Traffic Source:"
referrers.each do |referrer|
  filter_value = referrer == '(direct)' ? '' : referrer

  response = client.reports.revenue(
    website_id,
    start_date,
    end_date,
    "UTC",
    "USD",
    filters: [
      { type: 'referrer', value: filter_value }
    ]
  )

  totals = response.data['total']
  source_display = referrer == '(direct)' ? 'Direct' : referrer

  puts "\n#{source_display}:"
  puts "  Revenue: $#{totals['sum']}"
  puts "  Transactions: #{totals['count']}"
  puts "  AOV: $#{totals['average'].round(2)}"
end
 Revenue by Traffic Source:
 google.com:
   Revenue: $15,670
   Transactions: 456
   AOV: $34.36
 Direct:
   Revenue: $18,920
   Transactions: 512
   AOV: $36.95
```

## Advanced Business Metrics

```ruby
 Calculate comprehensive business metrics
response = client.reports.revenue(
  website_id,
  start_date,
  end_date,
  "UTC",
  "USD"
)

totals = response.data['total']
days = ((Time.parse(end_date) - Time.parse(start_date)) / (24 * 60 * 60)).round

 Core metrics
total_revenue = totals['sum']
total_transactions = totals['count']
total_customers = totals['unique_count']
aov = totals['average']

 Calculated metrics
daily_revenue = total_revenue.to_f / days
daily_transactions = total_transactions.to_f / days
customer_ltv = total_revenue.to_f / total_customers
repeat_rate = ((total_transactions - total_customers).to_f / total_customers * 100).round(1)

puts "Business Metrics (#{days} days):"
puts "\nRevenue Metrics:"
puts "  Total Revenue: $#{total_revenue}"
puts "  Daily Revenue: $#{daily_revenue.round(2)}"
puts "  Monthly Run Rate: $#{(daily_revenue * 30).round(0)}"
puts "  Annual Run Rate: $#{(daily_revenue * 365).round(0)}"

puts "\nTransaction Metrics:"
puts "  Total Transactions: #{total_transactions}"
puts "  Daily Transactions: #{daily_transactions.round(1)}"
puts "  Average Order Value: $#{aov.round(2)}"

puts "\nCustomer Metrics:"
puts "  Total Customers: #{total_customers}"
puts "  Customer Lifetime Value: $#{customer_ltv.round(2)}"
puts "  Repeat Purchase Rate: #{repeat_rate}%"
 Business Metrics (90 days):
 Revenue Metrics:
   Total Revenue: $45,230
   Daily Revenue: $502.56
   Monthly Run Rate: $15,077
   Annual Run Rate: $183,434
 Transaction Metrics:
   Total Transactions: 1,234
   Daily Transactions: 13.7
   Average Order Value: $36.65
 Customer Metrics:
   Total Customers: 1,189
   Customer Lifetime Value: $38.04
   Repeat Purchase Rate: 3.8%
```

## Industry Benchmarks

**Average Order Value (AOV) by Industry:**
```ruby
 E-commerce: $50-100
 SaaS (Monthly): $20-50
 SaaS (Annual): $200-2,000
 Digital Products: $10-50
 Services: $100-1,000
```

**Conversion Rate Benchmarks:**
```ruby
 E-commerce: 1-3%
 SaaS: 3-5%
 Digital Products: 2-5%
 Services: 5-10%
```

**Mobile vs Desktop AOV:**
```ruby
 Mobile typically: 60-80% of desktop AOV
 Mobile revenue share: 30-50% of total
 Desktop typically: Higher AOV, fewer transactions
```

**Geographic Performance:**
```ruby
 US typically: Highest AOV in most industries
 EU: 70-90% of US AOV
 Asia: Varies widely (30-100% of US AOV)
 Consider local purchasing power and market maturity
```

