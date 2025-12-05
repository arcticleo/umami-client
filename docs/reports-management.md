# Reports Management

Reports are saved analytics queries that can be executed repeatedly with consistent parameters. The Reports API allows you to create, read, update, and delete reports programmatically.

## List Reports

Retrieve all reports for a website with optional type filtering and pagination:

```ruby
 List all reports
response = client.reports.list("website-id")
response.body['data'].each do |report|
  puts "#{report['name']} (#{report['type']})"
end

 Filter by report type
response = client.reports.list("website-id", type: "funnel")

 With pagination
response = client.reports.list(
  "website-id",
  page: 2,
  page_size: 50
)
```

**Available report types:**
- `attribution` - Marketing attribution analysis
- `breakdown` - Dimension breakdown (OS, country, device, browser)
- `funnel` - Conversion funnel tracking
- `goal` - Goal completion metrics
- `journey` - User journey/path analysis
- `retention` - User retention and cohort analysis
- `revenue` - Revenue tracking and metrics
- `utm` - UTM parameter campaign tracking


## Create Report

Create a new saved report with specific parameters:

```ruby
 Create a funnel report
response = client.reports.create(
  "website-id",
  "Signup Funnel",
  "funnel",
  {
    window: 30,  # 30-day conversion window
    steps: [
      { url: "/signup" },
      { url: "/confirm-email" },
      { url: "/welcome" }
    ]
  },
  description: "Track user signup completion"
)

puts "Created report: #{response.body['id']}"

 Create a breakdown report
response = client.reports.create(
  "website-id",
  "Traffic by Country",
  "breakdown",
  {
    type: "country",
    limit: 20
  },
  description: "Geographic traffic distribution"
)

 Create a goal report
response = client.reports.create(
  "website-id",
  "Purchase Conversions",
  "goal",
  {
    url: "/thank-you",
    type: "pageview"
  },
  description: "Track completed purchases"
)
```


## Get Report

Retrieve full details of a specific report:

```ruby
response = client.reports.get("report-id")

report = response.body
puts "Report: #{report['name']}"
puts "Type: #{report['type']}"
puts "Description: #{report['description']}"
puts "Parameters: #{report['parameters']}"
puts "Created: #{report['createdAt']}"
puts "Updated: #{report['updatedAt']}"
```


## Update Report

Modify an existing report's name, description, or parameters:

```ruby
 Update funnel window and steps
response = client.reports.update(
  "report-id",
  "Updated Signup Funnel",
  "funnel",
  {
    window: 60,  # Changed to 60 days
    steps: [
      { url: "/signup" },
      { url: "/confirm-email" },
      { url: "/welcome" },
      { url: "/onboarding-complete" }  # Added step
    ]
  },
  description: "Extended funnel with onboarding"
)

puts "Updated: #{response.body['name']}"
```

**Note:** When updating, you must provide all parameters (name, type, parameters), not just the fields you want to change.


## Delete Report

Permanently remove a report:

```ruby
response = client.reports.delete("report-id")
puts "Deleted: #{response.body['ok']}"  # => true
```


## Complete Example

Here's a complete workflow for managing reports:

```ruby
 Create a retention report
create_response = client.reports.create(
  website_id,
  "30-Day User Retention",
  "retention",
  {
    period: 30,
    cohortStart: (Time.now - 90.days).to_i * 1000,
    cohortEnd: Time.now.to_i * 1000
  },
  description: "Monthly retention cohort analysis"
)

report_id = create_response.body['id']
puts "Created report: #{report_id}"

 List all retention reports
list_response = client.reports.list(website_id, type: "retention")
puts "\nRetention Reports:"
list_response.body['data'].each do |report|
  puts "  - #{report['name']} (created #{report['createdAt']})"
end

 Get full report details
get_response = client.reports.get(report_id)
puts "\nReport Details:"
puts "  Name: #{get_response.body['name']}"
puts "  Parameters: #{get_response.body['parameters']}"

 Update the report
update_response = client.reports.update(
  report_id,
  "90-Day User Retention",
  "retention",
  {
    period: 90,  # Extended to 90 days
    cohortStart: (Time.now - 180.days).to_i * 1000,
    cohortEnd: Time.now.to_i * 1000
  },
  description: "Quarterly retention cohort analysis"
)
puts "\nUpdated to: #{update_response.body['name']}"

 Clean up - delete the report
delete_response = client.reports.delete(report_id)
puts "\nDeleted: #{delete_response.body['ok']}"
```


## Report Parameters by Type

Each report type has specific parameter requirements. Here are common patterns:

**Funnel Reports:**
```ruby
parameters: {
  window: 30,           # Conversion window in days
  steps: [              # Array of funnel steps
    { url: "/step1" },
    { url: "/step2" }
  ]
}
```

**Breakdown Reports:**
```ruby
parameters: {
  type: "country",      # Dimension: country, os, browser, device
  limit: 20             # Number of results
}
```

**Goal Reports:**
```ruby
parameters: {
  url: "/success",      # Goal URL
  type: "pageview"      # Goal type: pageview or event
}
```

**Journey Reports:**
```ruby
parameters: {
  start: "/home",       # Journey start point
  end: "/checkout"      # Journey end point
}
```

**Retention Reports:**
```ruby
parameters: {
  period: 30,           # Retention period in days
  cohortStart: 1700000000000,  # Cohort start (milliseconds)
  cohortEnd: 1702000000000     # Cohort end (milliseconds)
}
```

**Attribution Reports:**
```ruby
parameters: {
  model: "first-click"  # Attribution model
}
```

**Revenue Reports:**
```ruby
parameters: {
  currency: "USD"       # Revenue currency
}
```

**UTM Reports:**
```ruby
parameters: {
  type: "utm_source"    # UTM parameter: utm_source, utm_medium, utm_campaign
}
```


