# Admin Functions

The Admin API provides global administrative views across all resources in your self-hosted Umami instance. These endpoints are only available for admin users and provide complete visibility into users, websites, and teams.

## Important Notes

⚠️ **Self-Hosted Only**: Admin endpoints are **ONLY** available for self-hosted Umami instances. They are **NOT** available on Umami Cloud.

⚠️ **Admin Role Required**: You must authenticate with admin credentials (username/password) to access these endpoints.

⚠️ **Global Scope**: Unlike regular endpoints which show only resources you have access to, admin endpoints return **all** resources across the entire instance.

## Authentication

Admin endpoints require authentication with admin user credentials:

```ruby
client = UmamiClient::Client.new(
  username: "admin",
  password: "your-password",
  base_url: "https://analytics.example.com"
)
```

## List All Users

Get a global view of all users in the Umami instance.

```ruby
# List all users
response = client.admin.users

response.data["data"].each do |user|
  puts "#{user['username']} - #{user['role']}"
  puts "  Websites: #{user['_count']['websites']}"
  puts "  Created: #{user['createdAt']}"
end
```

### With Pagination

```ruby
# Get first page with 20 users
response = client.admin.users(page: 1, page_size: 20)

puts "Page: #{response.data['page']}"
puts "Page Size: #{response.data['pageSize']}"
puts "Total Count: #{response.data['count']}"
puts "Users on this page: #{response.data['data'].length}"
```

### Search Users

```ruby
# Search for users by username
response = client.admin.users(search: "john")

response.data["data"].each do |user|
  puts "Found: #{user['username']}"
end
```

### User Response Structure

```ruby
{
  "data" => [
    {
      "id" => "230d1341-58fd-4333-b983-b07d2f789c95",
      "username" => "admin",
      "role" => "admin",              # "admin", "user", or "view-only"
      "logoUrl" => nil,
      "displayName" => nil,
      "createdAt" => "2025-12-04T05:15:38.000Z",
      "updatedAt" => "2025-12-04T05:46:58.000Z",
      "deletedAt" => nil,
      "_count" => {
        "websites" => 5
      }
    }
  ],
  "count" => 10,                     # Total users in instance
  "page" => 1,
  "pageSize" => 20,
  "orderBy" => "createdAt"
}
```

## List All Websites

Get a global view of all websites in the Umami instance.

```ruby
# List all websites
response = client.admin.websites

response.data["data"].each do |website|
  owner = website['user']['username']
  team = website['team'] ? website['team']['name'] : 'No team'

  puts "#{website['name']} (#{website['domain']})"
  puts "  Owner: #{owner}"
  puts "  Team: #{team}"
  puts "  Created: #{website['createdAt']}"
end
```

### With Pagination

```ruby
# Get specific page
response = client.admin.websites(page: 2, page_size: 50)

response.data["data"].each do |website|
  puts "#{website['name']} - #{website['domain']}"
end
```

### Search Websites

```ruby
# Search by website name or domain
response = client.admin.websites(search: "example.com")

response.data["data"].each do |website|
  puts "Found: #{website['name']} - #{website['domain']}"
end
```

### Website Response Structure

```ruby
{
  "data" => [
    {
      "id" => "f5e53756-0264-435b-bb76-3a9b8fdcb176",
      "name" => "My Website",
      "domain" => "example.com",
      "shareId" => nil,
      "resetAt" => nil,
      "userId" => "41e2b680-648e-4b09-bcd7-3e2b10c06264",
      "teamId" => "2bb6bbad-d89d-49a6-a8d3-cc0572435056",
      "createdBy" => "41e2b680-648e-4b09-bcd7-3e2b10c06264",
      "createdAt" => "2024-11-29T03:34:17.000Z",
      "updatedAt" => "2024-11-29T03:34:17.000Z",
      "deletedAt" => nil,
      "user" => {                      # Website owner details
        "username" => "admin",
        "id" => "41e2b680-648e-4b09-bcd7-3e2b10c06264"
      },
      "team" => {                      # Team details (if assigned)
        "id" => "2bb6bbad-d89d-49a6-a8d3-cc0572435056",
        "name" => "Engineering",
        "members" => [...]
      }
    }
  ],
  "count" => 25,                       # Total websites in instance
  "page" => 1,
  "pageSize" => 20
}
```

## List All Teams

Get a global view of all teams in the Umami instance.

```ruby
# List all teams
response = client.admin.teams

response.data["data"].each do |team|
  member_count = team['_count']['members']
  website_count = team['_count']['websites']

  puts "#{team['name']}"
  puts "  Members: #{member_count}"
  puts "  Websites: #{website_count}"
  puts "  Created: #{team['createdAt']}"
end
```

### With Pagination

```ruby
# Get specific page
response = client.admin.teams(page: 1, page_size: 10)

response.data["data"].each do |team|
  puts "#{team['name']} - #{team['_count']['members']} members"
end
```

### Search Teams

```ruby
# Search by team name
response = client.admin.teams(search: "engineering")

response.data["data"].each do |team|
  puts "Found: #{team['name']}"
end
```

### Team Response Structure

```ruby
{
  "data" => [
    {
      "id" => "f7e8163c-7f09-4a0d-9551-090844610bfb",
      "name" => "Engineering",
      "accessCode" => "team_rrE8IjKannACm9M6",
      "logoUrl" => nil,
      "createdAt" => "2025-12-05T20:42:43.000Z",
      "updatedAt" => "2025-12-05T20:42:44.000Z",
      "deletedAt" => nil,
      "members" => [                   # Team member details
        {
          "id" => "406f6e5b-a749-44de-b820-afed8a048930",
          "teamId" => "f7e8163c-7f09-4a0d-9551-090844610bfb",
          "userId" => "41e2b680-648e-4b09-bcd7-3e2b10c06264",
          "role" => "team-owner",
          "createdAt" => "2025-12-05T20:42:43.000Z",
          "updatedAt" => "2025-12-05T20:42:43.000Z",
          "user" => {
            "id" => "41e2b680-648e-4b09-bcd7-3e2b10c06264",
            "username" => "admin"
          }
        }
      ],
      "_count" => {
        "websites" => 3,
        "members" => 5
      }
    }
  ],
  "count" => 8,                        # Total teams in instance
  "page" => 1,
  "pageSize" => 20
}
```

## Complete Admin Dashboard Example

```ruby
require "umami_client"

# Authenticate as admin
client = UmamiClient::Client.new(
  username: ENV["UMAMI_USERNAME"],
  password: ENV["UMAMI_PASSWORD"],
  base_url: ENV["UMAMI_BASE_URL"]
)

# Get overview statistics
users = client.admin.users
websites = client.admin.websites
teams = client.admin.teams

puts "UMAMI INSTANCE OVERVIEW"
puts "=" * 50
puts "Users: #{users.data['count']}"
puts "Websites: #{websites.data['count']}"
puts "Teams: #{teams.data['count']}"
puts

# Show recent users
puts "RECENT USERS"
puts "-" * 50
client.admin.users(page: 1, page_size: 5).data["data"].each do |user|
  website_count = user['_count']['websites']
  puts "#{user['username']} (#{user['role']}) - #{website_count} websites"
end
puts

# Show website distribution by team
puts "WEBSITES BY TEAM"
puts "-" * 50
team_websites = Hash.new(0)
websites.data["data"].each do |website|
  if website['team']
    team_websites[website['team']['name']] += 1
  else
    team_websites['No Team'] += 1
  end
end

team_websites.sort_by { |_, count| -count }.each do |team_name, count|
  puts "#{team_name}: #{count} websites"
end
puts

# Show team membership
puts "TEAM MEMBERSHIP"
puts "-" * 50
teams.data["data"].each do |team|
  member_count = team['_count']['members']
  website_count = team['_count']['websites']
  puts "#{team['name']}: #{member_count} members, #{website_count} websites"
end
```

Output:
```
UMAMI INSTANCE OVERVIEW
==================================================
Users: 12
Websites: 25
Teams: 8

RECENT USERS
--------------------------------------------------
admin (admin) - 5 websites
john_doe (user) - 3 websites
jane_smith (user) - 2 websites
bob_wilson (view-only) - 0 websites
alice_jones (user) - 4 websites

WEBSITES BY TEAM
--------------------------------------------------
Engineering: 10 websites
Marketing: 8 websites
Sales: 5 websites
No Team: 2 websites

TEAM MEMBERSHIP
--------------------------------------------------
Engineering: 5 members, 10 websites
Marketing: 3 members, 8 websites
Sales: 4 members, 5 websites
```

## Error Handling

```ruby
begin
  response = client.admin.users

  if response.success?
    users = response.data["data"]
    puts "Found #{users.length} users"
  else
    puts "Error: #{response.status}"
  end

rescue UmamiClient::AuthenticationError => e
  puts "Authentication failed: #{e.message}"
  puts "Make sure you're using admin credentials"

rescue UmamiClient::Error => e
  puts "API error: #{e.message}"
  puts "Admin endpoints only work on self-hosted instances"
end
```

## Best Practices

### 1. Use Pagination for Large Instances

```ruby
# Don't load all users at once
page = 1
all_users = []

loop do
  response = client.admin.users(page: page, page_size: 100)
  users = response.data["data"]

  break if users.empty?

  all_users.concat(users)
  break if all_users.length >= response.data["count"]

  page += 1
end
```

### 2. Cache Results for Dashboards

```ruby
# Cache admin data for 5 minutes
require "redis"

redis = Redis.new
cache_key = "admin:dashboard"

dashboard_data = redis.get(cache_key)

if dashboard_data.nil?
  users = client.admin.users
  websites = client.admin.websites
  teams = client.admin.teams

  dashboard_data = {
    users: users.data,
    websites: websites.data,
    teams: teams.data,
    cached_at: Time.now
  }.to_json

  redis.setex(cache_key, 300, dashboard_data)  # 5 minutes
end

data = JSON.parse(dashboard_data)
```

### 3. Monitor Instance Health

```ruby
# Check for inactive users
users = client.admin.users(page_size: 100).data["data"]

inactive_users = users.select do |user|
  user['_count']['websites'] == 0
end

if inactive_users.any?
  puts "Found #{inactive_users.length} users with no websites"
  inactive_users.each do |user|
    puts "  - #{user['username']}"
  end
end

# Check for orphaned websites
websites = client.admin.websites.data["data"]

orphaned = websites.select do |website|
  website['team'].nil? && website['user'].nil?
end

puts "Found #{orphaned.length} orphaned websites"
```

## Limitations

1. **Self-Hosted Only**: Admin endpoints do not work with Umami Cloud
2. **Admin Role Required**: Regular users and view-only users cannot access these endpoints
3. **No Modification**: These endpoints are read-only; use regular APIs to modify resources
4. **Rate Limiting**: Large instances may require pagination to avoid timeouts

## Common Use Cases

### 1. User Audit Report

```ruby
users = client.admin.users.data["data"]

puts "USER AUDIT REPORT"
puts "Generated: #{Time.now}"
puts "=" * 70

users.each do |user|
  puts "\n#{user['username']} (#{user['role']})"
  puts "  ID: #{user['id']}"
  puts "  Created: #{user['createdAt']}"
  puts "  Updated: #{user['updatedAt']}"
  puts "  Websites: #{user['_count']['websites']}"
end
```

### 2. Resource Allocation Dashboard

```ruby
# Show which teams have most resources
teams = client.admin.teams.data["data"]

puts "RESOURCE ALLOCATION"
puts "=" * 70

teams.sort_by { |t| -t['_count']['websites'] }.each do |team|
  members = team['_count']['members']
  websites = team['_count']['websites']
  ratio = websites.to_f / members

  puts "#{team['name']}"
  puts "  Members: #{members}"
  puts "  Websites: #{websites}"
  puts "  Websites per member: #{ratio.round(2)}"
  puts
end
```

### 3. Growth Tracking

```ruby
# Track instance growth over time
users = client.admin.users.data["data"]
websites = client.admin.websites.data["data"]
teams = client.admin.teams.data["data"]

# Group by month
require "date"

users_by_month = Hash.new(0)
websites_by_month = Hash.new(0)
teams_by_month = Hash.new(0)

users.each do |user|
  month = Date.parse(user['createdAt']).strftime("%Y-%m")
  users_by_month[month] += 1
end

websites.each do |website|
  month = Date.parse(website['createdAt']).strftime("%Y-%m")
  websites_by_month[month] += 1
end

teams.each do |team|
  month = Date.parse(team['createdAt']).strftime("%Y-%m")
  teams_by_month[month] += 1
end

puts "GROWTH REPORT"
puts "=" * 70
puts "Month       | Users | Websites | Teams"
puts "-" * 70

all_months = (users_by_month.keys + websites_by_month.keys + teams_by_month.keys).uniq.sort

all_months.each do |month|
  puts sprintf("%-11s | %5d | %8d | %5d",
    month,
    users_by_month[month],
    websites_by_month[month],
    teams_by_month[month]
  )
end
```

## Related Documentation

- [User Management](user-management.md) - Manage individual users
- [Team Management](team-management.md) - Manage teams
- [Website Management](website-management.md) - Manage websites
