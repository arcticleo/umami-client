# User Management

User management endpoints are only available on **self-hosted Umami instances** for users with **admin privileges**. These features are not available on Umami Cloud.

The User Management API allows administrators to:
- List all users with pagination and search
- Get current user information
- Get specific user details
- Create new users with different roles
- Update user credentials and roles
- Delete users
- View user's websites and teams

## Get Current User

Retrieve information about the currently authenticated user based on the auth token:

```ruby
response = client.users.me

if response.success?
  user = response.data['user']
  puts "Logged in as: #{user['username']}"
  puts "Role: #{user['role']}"
  puts "Admin: #{user['isAdmin']}"
  puts "User ID: #{user['id']}"
end
```

**Response structure:**
```ruby
{
  "user" => {
    "id" => "41e2b680-648e-4b09-bcd7-3e2b10c06264",
    "username" => "admin",
    "role" => "admin",
    "isAdmin" => true,
    "createdAt" => "2024-11-29T05:29:57.000Z"
  },
  # Additional auth keys may be included
}
```

## List All Users

List all users with optional pagination and search filtering:

```ruby
# Get all users (default pagination)
response = client.users.list

if response.success?
  users = response.data['data']
  puts "Total users: #{response.data['count']}"

  users.each do |user|
    puts "#{user['username']} (#{user['role']})"
  end
end
```

### Pagination

```ruby
# Get page 2 with 50 users per page
response = client.users.list(page: 2, page_size: 50)

puts "Found #{response.data['data'].length} users"
puts "Total count: #{response.data['count']}"
```

### Search Users

```ruby
# Search for users by username
response = client.users.list(search: "admin")

if response.success?
  matching_users = response.data['data']
  puts "Found #{matching_users.length} user(s) matching 'admin'"

  matching_users.each do |user|
    puts "  - #{user['username']} (#{user['role']})"
  end
end
```

**Parameters:**
- `search` (String, optional) - Search keyword to filter users by username
- `page` (Integer, optional) - Page number (default: 1)
- `page_size` (Integer, optional) - Results per page (default: 20)

## Get User by ID

Retrieve detailed information about a specific user:

```ruby
user_id = "41e2b680-648e-4b09-bcd7-3e2b10c06264"
response = client.users.get(user_id)

if response.success?
  puts "Username: #{response.data['username']}"
  puts "Role: #{response.data['role']}"
  puts "User ID: #{response.data['id']}"
  puts "Created: #{response.data['createdAt']}"
end
```

**Response structure:**
```ruby
{
  "id" => "41e2b680-648e-4b09-bcd7-3e2b10c06264",
  "username" => "admin",
  "role" => "admin",
  "createdAt" => "2024-11-29T05:29:57.000Z"
}
```

## Create User

Create a new user account with specified credentials and role:

```ruby
response = client.users.create(
  "john_admin",
  "secure_password_123",
  "admin"
)

if response.success?
  puts "User created successfully!"
  puts "Username: #{response.data['username']}"
  puts "Role: #{response.data['role']}"
  puts "User ID: #{response.data['id']}"
end
```

### User Roles

Umami supports three user roles:

1. **`admin`** - Full access to all features and settings
2. **`user`** - Can manage their own websites and view analytics
3. **`view-only`** - Read-only access to analytics data

```ruby
# Create an admin user
client.users.create("admin_user", "password", "admin")

# Create a regular user
client.users.create("regular_user", "password", "user")

# Create a view-only user
client.users.create("viewer", "password", "view-only")
```

### Custom User ID (Optional)

You can optionally specify a custom UUID for the user:

```ruby
require 'securerandom'

custom_id = SecureRandom.uuid

response = client.users.create(
  "custom_user",
  "password",
  "user",
  id: custom_id
)
```

## Update User

Update a user's username, password, or role. At least one parameter must be provided:

### Change Username

```ruby
response = client.users.update(
  user_id,
  username: "new_username"
)

if response.success?
  puts "Username updated to: #{response.data['username']}"
end
```

### Change Password

```ruby
response = client.users.update(
  user_id,
  password: "new_secure_password"
)

if response.success?
  puts "Password updated successfully"
end
```

### Change Role

```ruby
# Note: API requires username field even when updating role
response = client.users.update(
  user_id,
  username: current_username,  # Must include current username
  role: "admin"
)

if response.success?
  puts "Role updated to: #{response.data['role']}"
end
```

### Update Multiple Fields

```ruby
response = client.users.update(
  user_id,
  username: "updated_username",
  password: "new_password",
  role: "user"
)
```

**Parameters:**
- `user_id` (String, required) - User's UUID
- `username` (String, optional) - New username
- `password` (String, optional) - New password
- `role` (String, optional) - New role: "admin", "user", or "view-only"

**Note:** The Umami API requires the username parameter even when only updating the role. This is an API requirement, not a client limitation.

## Delete User

Permanently remove a user account. This action cannot be undone:

```ruby
response = client.users.delete(user_id)

if response.success?
  puts "User deleted successfully"
else
  puts "Failed to delete user: #{response.error}"
end
```

**Warning:** Deleting a user is permanent and cannot be undone. Consider:
- Backing up user data before deletion
- Reassigning user's websites to another user
- Removing user from teams first

## Get User's Websites

Retrieve all websites owned by a specific user:

```ruby
response = client.users.websites(user_id)

if response.success?
  websites = response.data['data']
  puts "Total websites: #{websites.length}"

  websites.each do |website|
    puts "#{website['name']}: #{website['domain']}"
  end
end
```

### Include Team Websites

```ruby
# Include websites from teams the user is a member of
response = client.users.websites(
  user_id,
  include_teams: true
)
```

### Pagination and Search

```ruby
# Search and paginate user's websites
response = client.users.websites(
  user_id,
  search: "blog",
  page: 1,
  page_size: 10
)
```

**Parameters:**
- `user_id` (String, required) - User's UUID
- `search` (String, optional) - Search keyword
- `page` (Integer, optional) - Page number
- `page_size` (Integer, optional) - Results per page
- `include_teams` (Boolean, optional) - Include team-owned websites

## Get User's Teams

Retrieve all teams the user is a member of:

```ruby
response = client.users.teams(user_id)

if response.success?
  teams = response.data['data']
  puts "Total teams: #{teams.length}"

  teams.each do |team|
    puts "Team: #{team['name']}"
    puts "  ID: #{team['id']}"
    puts "  Members: #{team['teamUser']&.length || 0}"
  end
end
```

### With Pagination

```ruby
response = client.users.teams(
  user_id,
  page: 1,
  page_size: 20
)
```

**Parameters:**
- `user_id` (String, required) - User's UUID
- `page` (Integer, optional) - Page number
- `page_size` (Integer, optional) - Results per page

## Using the User Model

The `UmamiClient::User` model provides a convenient object-oriented interface for working with user data:

```ruby
response = client.users.me

if response.success?
  user_data = response.data['user']
  user = UmamiClient::User.new(user_data)

  puts "Username: #{user.username}"
  puts "Role: #{user.role}"
  puts "Created: #{user.created_at}"
  puts "Website count: #{user.website_count}" if user.website_count

  # Role checking methods
  if user.admin?
    puts "User has admin privileges"
  elsif user.user?
    puts "User is a regular user"
  elsif user.view_only?
    puts "User has view-only access"
  end

  # Convert to hash
  user_hash = user.to_h

  # String representation
  puts user.to_s
  # => #<UmamiClient::User id=... username=admin role=admin>
end
```

### User Model Methods

**Attributes:**
- `id` - User's UUID
- `username` - Username
- `role` - User role (admin, user, view-only)
- `created_at` - Creation timestamp (Time object)
- `website_count` - Number of websites owned (may be nil)

**Methods:**
- `admin?` - Returns true if user has admin role
- `user?` - Returns true if user has user role
- `view_only?` - Returns true if user has view-only role
- `to_h` - Convert to hash representation
- `to_s` - String representation
- `inspect` - Detailed inspection (same as to_s)

## Complete User Management Example

Here's a comprehensive example demonstrating common user management workflows:

```ruby
require 'umami_client'

# Initialize client with admin credentials
client = UmamiClient::Client.new(
  username: ENV['UMAMI_USERNAME'],
  password: ENV['UMAMI_PASSWORD'],
  base_url: ENV['UMAMI_BASE_URL']
)

# Authenticate
client.authenticate

# 1. Get current user info
me_response = client.users.me
current_user = UmamiClient::User.new(me_response.data['user'])
puts "Logged in as: #{current_user.username} (#{current_user.role})"

# 2. List all users
puts "\nAll Users:"
users_response = client.users.list
users_response.data['data'].each do |user_data|
  user = UmamiClient::User.new(user_data)
  puts "  - #{user.username} (#{user.role})"
end

# 3. Search for specific users
search_response = client.users.list(search: "admin")
puts "\nAdmin users: #{search_response.data['count']}"

# 4. Create a new user
new_user_response = client.users.create(
  "analytics_team",
  "secure_password_123",
  "user"
)

if new_user_response.success?
  new_user = UmamiClient::User.new(new_user_response.data)
  puts "\nCreated user: #{new_user.username}"
  user_id = new_user.id

  # 5. Update the user's role
  update_response = client.users.update(
    user_id,
    username: new_user.username,
    role: "admin"
  )

  if update_response.success?
    puts "Updated role to: #{update_response.data['role']}"
  end

  # 6. Get user's websites
  websites_response = client.users.websites(user_id)
  puts "\nUser's websites: #{websites_response.data['data'].length}"

  # 7. Get user's teams
  teams_response = client.users.teams(user_id)
  puts "User's teams: #{teams_response.data['data'].length}"

  # 8. Delete the test user
  if client.users.delete(user_id).success?
    puts "\nTest user deleted"
  end
end
```

## Error Handling

All user management operations include proper validation and error handling:

```ruby
begin
  # Missing required parameter
  response = client.users.get(nil)
rescue UmamiClient::ValidationError => e
  puts "Validation error: #{e.message}"
  # => "user_id is required"
end

begin
  # Invalid role
  response = client.users.create(
    "user",
    "password",
    "invalid_role"
  )
rescue UmamiClient::ValidationError => e
  puts "Validation error: #{e.message}"
  # => "role must be one of: admin, user, view-only"
end

begin
  # Update without any parameters
  response = client.users.update(user_id)
rescue UmamiClient::ValidationError => e
  puts "Validation error: #{e.message}"
  # => "at least one of username, password, or role must be provided"
end
```

## Best Practices

### 1. Use Strong Passwords

```ruby
require 'securerandom'

# Generate secure random password
password = SecureRandom.base64(24)

client.users.create(username, password, role)
```

### 2. Verify User Permissions

```ruby
me_response = client.users.me
current_user = UmamiClient::User.new(me_response.data['user'])

unless current_user.admin?
  puts "Error: Admin privileges required"
  exit 1
end
```

### 3. Audit User Changes

```ruby
# Log user management actions
def create_user_with_audit(client, username, password, role)
  response = client.users.create(username, password, role)

  if response.success?
    user = response.data
    puts "[AUDIT] User created: #{user['username']} (#{user['role']}) at #{Time.now}"
    user
  else
    puts "[AUDIT] Failed to create user: #{response.error}"
    nil
  end
end
```

### 4. Bulk User Operations

```ruby
# Create multiple users from CSV
require 'csv'

CSV.foreach('users.csv', headers: true) do |row|
  response = client.users.create(
    row['username'],
    row['password'],
    row['role']
  )

  if response.success?
    puts "✓ Created: #{row['username']}"
  else
    puts "✗ Failed: #{row['username']} - #{response.error}"
  end
end
```

### 5. Role-Based Access Control

```ruby
def get_user_with_permission_check(client, user_id)
  # Get current user
  me = client.users.me.data['user']
  current_user = UmamiClient::User.new(me)

  # Get target user
  target_user_response = client.users.get(user_id)

  if current_user.admin?
    # Admins can view all users
    target_user_response.data
  elsif current_user.id == user_id
    # Users can view their own profile
    target_user_response.data
  else
    puts "Error: Insufficient permissions"
    nil
  end
end
```

## Limitations

### Self-Hosted Only

User management endpoints are only available on self-hosted Umami instances. If you try to use these endpoints on Umami Cloud, you'll receive an error:

```ruby
# On Umami Cloud (won't work)
client = UmamiClient::Client.new(
  api_key: "your-cloud-api-key",
  base_url: "https://api.umami.is"
)

response = client.users.list
# This will fail - user management requires self-hosted instance
```

### Admin Privileges Required

Most user management endpoints (create, update, delete, list) require admin privileges:

```ruby
# Non-admin users can only access:
client.users.me              # Get their own user info
client.users.get(own_id)     # Get their own details
client.users.websites(own_id) # Get their own websites
client.users.teams(own_id)   # Get their own teams
```

### API Quirks

The Umami API has some quirks you should be aware of:

1. **Username required on updates**: When updating a user's role, you must also provide the username parameter even if you're not changing it.

2. **Case sensitivity**: Usernames are case-sensitive.

3. **Password requirements**: There may be password complexity requirements on your Umami instance.

## Common Use Cases

### 1. User Onboarding Dashboard

```ruby
def create_onboarding_dashboard
  # Get all new users (created in last 7 days)
  all_users = client.users.list.data['data']

  new_users = all_users.select do |user_data|
    created_at = Time.parse(user_data['createdAt'])
    created_at > (Time.now - 7 * 24 * 60 * 60)
  end

  puts "New users in last 7 days: #{new_users.length}"

  new_users.each do |user_data|
    user = UmamiClient::User.new(user_data)
    websites = client.users.websites(user.id).data['data']

    puts "  #{user.username} (#{user.role})"
    puts "    Websites: #{websites.length}"
    puts "    Created: #{user.created_at.strftime('%Y-%m-%d')}"
  end
end
```

### 2. Automated User Provisioning

```ruby
def provision_user_from_signup(email, name)
  # Generate username from email
  username = email.split('@').first

  # Generate secure random password
  password = SecureRandom.base64(24)

  # Create user
  response = client.users.create(username, password, "user")

  if response.success?
    user = response.data

    # Send welcome email with credentials
    send_welcome_email(email, username, password)

    # Log to audit trail
    puts "[PROVISIONING] User #{username} created for #{email}"

    user
  else
    puts "[ERROR] Failed to provision user: #{response.error}"
    nil
  end
end
```

### 3. Role Migration Script

```ruby
# Upgrade all 'user' roles to 'admin'
def upgrade_users_to_admin
  response = client.users.list
  users = response.data['data']

  users.each do |user_data|
    user = UmamiClient::User.new(user_data)

    if user.user?
      update_response = client.users.update(
        user.id,
        username: user.username,
        role: "admin"
      )

      if update_response.success?
        puts "✓ Upgraded #{user.username} to admin"
      else
        puts "✗ Failed to upgrade #{user.username}"
      end
    end
  end
end
```

### 4. User Activity Report

```ruby
def generate_user_activity_report
  users_response = client.users.list
  users = users_response.data['data']

  report = users.map do |user_data|
    user = UmamiClient::User.new(user_data)
    websites = client.users.websites(user.id).data['data']
    teams = client.users.teams(user.id).data['data']

    {
      username: user.username,
      role: user.role,
      created_at: user.created_at,
      websites_count: websites.length,
      teams_count: teams.length,
      is_admin: user.admin?
    }
  end

  # Sort by website count
  report.sort_by! { |r| -r[:websites_count] }

  puts "\nUser Activity Report"
  puts "=" * 80
  report.each do |r|
    puts "#{r[:username].ljust(20)} #{r[:role].ljust(10)} " \
         "Websites: #{r[:websites_count]}  Teams: #{r[:teams_count]}"
  end
end
```

### 5. Security Audit

```ruby
def perform_security_audit
  users_response = client.users.list
  users = users_response.data['data']

  puts "\nSecurity Audit Report"
  puts "=" * 80

  # Count by role
  role_counts = users.group_by { |u| u['role'] }
                     .transform_values(&:count)

  puts "\nUsers by role:"
  role_counts.each { |role, count| puts "  #{role}: #{count}" }

  # Find admin users
  admin_users = users.select { |u| UmamiClient::User.new(u).admin? }

  puts "\nAdmin users (#{admin_users.length}):"
  admin_users.each do |user_data|
    user = UmamiClient::User.new(user_data)
    puts "  - #{user.username} (created #{user.created_at.strftime('%Y-%m-%d')})"
  end

  # Find recently created users
  recent_users = users.select do |user_data|
    created_at = Time.parse(user_data['createdAt'])
    created_at > (Time.now - 30 * 24 * 60 * 60)
  end

  puts "\nRecently created users (last 30 days): #{recent_users.length}"
end
```
