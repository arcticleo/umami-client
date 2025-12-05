# Team Management

The Teams API allows you to manage collaborative teams in Umami Analytics. Teams enable multiple users to share access to websites and work together on analytics.

**Requirements:**
- Umami v2.0.0 or later
- Self-hosted instance (Teams not available on Umami Cloud)
- Admin or appropriate team permissions

## Table of Contents

- [Overview](#overview)
- [Team Roles](#team-roles)
- [Creating Teams](#creating-teams)
- [Listing Teams](#listing-teams)
- [Getting Team Details](#getting-team-details)
- [Updating Teams](#updating-teams)
- [Deleting Teams](#deleting-teams)
- [Joining Teams](#joining-teams)
- [Managing Team Members](#managing-team-members)
- [Team Model](#team-model)
- [Known Issues](#known-issues)
- [Complete Examples](#complete-examples)

## Overview

Teams in Umami allow:
- Sharing website access with multiple users
- Collaborative analytics management
- Role-based access control
- Secure team invitations via access codes

## Team Roles

Teams support four distinct roles with different permissions:

| Role | Value | Permissions |
|------|-------|-------------|
| Owner | `team-owner` | Full control - manage team, websites, and members |
| Manager | `team-manager` | Manage members and edit team settings |
| Member | `team-member` | Access team websites, limited modifications |
| View-Only | `team-view-only` | Read-only access to team analytics |

## Creating Teams

Create a new team for collaborative work:

```ruby
require 'umami_client'

client = UmamiClient::Client.new(
  username: 'admin',
  password: 'password',
  base_url: 'https://analytics.example.com'
)

# Create a team
response = client.teams.create("Marketing Team")

if response.success?
  # Create returns array: [team_object, team_user_object]
  team_data = response.data[0]

  puts "Team created!"
  puts "Team ID: #{team_data['id']}"
  puts "Access Code: #{team_data['accessCode']}"
  puts "Share this code with team members to invite them"
end
```

### Validation Rules

- **Name**: Required, max 50 characters
- **Access Code**: Auto-generated in format `team_XXXXXXXXXXXXXXXX`

## Listing Teams

Get all teams for the authenticated user:

```ruby
# List all teams
response = client.teams.list

teams = response.data['data']
puts "You belong to #{teams.length} team(s):"

teams.each do |team|
  puts "\nTeam: #{team['name']}"
  puts "  ID: #{team['id']}"
  puts "  Access Code: #{team['accessCode']}"
  puts "  Members: #{team['teamUser'].length}"
  puts "  Websites: #{team['_count']['website']}"
end
```

### With Pagination

```ruby
# Get specific page
response = client.teams.list(page: 2, page_size: 10)

puts "Page #{response.data['page']} of teams"
puts "Total: #{response.data['count']}"
```

## Getting Team Details

Retrieve detailed information about a specific team:

```ruby
team_id = "your-team-id"

response = client.teams.get(team_id)

if response.success?
  team = response.data

  puts "Team: #{team['name']}"
  puts "Created: #{team['createdAt']}"
  puts "\nMembers:"

  team['teamUser'].each do |member|
    user = member['user']
    puts "  - #{user['username']} (#{member['role']})"
  end
end
```

### Using Team Model

```ruby
response = client.teams.get(team_id)
team = UmamiClient::Team.new(response.data)

puts "Team: #{team.name}"
puts "Members: #{team.member_count}"
puts "Websites: #{team.website_count}"
puts "Has members? #{team.has_members?}"

# Filter members by role
puts "\nOwners:"
team.owners.each do |owner|
  puts "  - #{owner['user']['username']}"
end

puts "\nManagers:"
team.managers.each do |manager|
  puts "  - #{manager['user']['username']}"
end
```

## Updating Teams

Update team name or regenerate access code:

### Update Name

```ruby
team_id = "your-team-id"

response = client.teams.update(team_id, name: "New Team Name")

if response.success?
  puts "Team renamed to: #{response.data['name']}"
end
```

### Regenerate Access Code

```ruby
require 'securerandom'

# Generate new access code
new_code = "team_#{SecureRandom.hex(8)}"

response = client.teams.update(team_id, access_code: new_code)

if response.success?
  puts "New access code: #{response.data['accessCode']}"
  puts "Share this with new team members"
end
```

### Update Both

```ruby
response = client.teams.update(
  team_id,
  name: "Updated Team Name",
  access_code: "team_newsecretcode"
)
```

## Deleting Teams

Permanently remove a team (requires owner or manager role):

```ruby
team_id = "your-team-id"

response = client.teams.delete(team_id)

if response.success?
  puts "Team deleted successfully"
else
  puts "Error: #{response.error_message}"
end
```

**⚠️ Warning**: Deletion is permanent and cannot be undone.

## Joining Teams

Join an existing team using an access code:

```ruby
# User receives access code from team owner
access_code = "team_abc123def456"

response = client.teams.join(access_code)

if response.success?
  team_user = response.data
  puts "Successfully joined team!"
  puts "Your role: #{team_user['role']}"
else
  puts "Failed to join: #{response.error_message}"
end
```

### Common Join Errors

- **Team not found**: Invalid or expired access code
- **Already a member**: User is already on the team
- **No permission**: Team is private or requires approval

## Managing Team Members

### List Team Members

```ruby
team_id = "your-team-id"

response = client.teams.list_members(team_id)

members = response.data['data']
puts "Team has #{members.length} member(s):"

members.each do |member|
  user = member['user']
  puts "  #{user['username']} - #{member['role']}"
end
```

### Add Team Member

```ruby
team_id = "your-team-id"
user_id = "user-to-add-id"

# Add as regular member
response = client.teams.add_member(team_id, user_id, "team-member")

if response.success?
  puts "User added to team"
else
  puts "Error: #{response.error_message}"
end
```

### Add with Different Roles

```ruby
# Add as manager
client.teams.add_member(team_id, user_id, "team-manager")

# Add as view-only
client.teams.add_member(team_id, user_id, "team-view-only")

# Add as owner
client.teams.add_member(team_id, user_id, "team-owner")
```

### Get Team Member Details

```ruby
team_id = "your-team-id"
user_id = "member-user-id"

response = client.teams.get_member(team_id, user_id)

if response.success?
  member = response.data
  puts "Role: #{member['role']}"
  puts "Joined: #{member['createdAt']}"
end
```

### Update Member Role

```ruby
team_id = "your-team-id"
user_id = "member-user-id"

# Promote to manager
response = client.teams.update_member(team_id, user_id, "team-manager")

if response.success?
  puts "Member promoted to manager"
end
```

### Remove Team Member

```ruby
team_id = "your-team-id"
user_id = "member-to-remove-id"

response = client.teams.remove_member(team_id, user_id)

if response.success?
  puts "Member removed from team"
end
```

## Team Model

The `UmamiClient::Team` model provides a convenient wrapper for team data:

### Attributes

```ruby
team = UmamiClient::Team.new(team_data)

# Basic attributes
team.id             # => "uuid"
team.name           # => "Team Name"
team.access_code    # => "team_abc123"
team.created_at     # => Time object
team.updated_at     # => Time object

# Counts
team.member_count   # => 5
team.website_count  # => 3

# Members array
team.members        # => Array of member hashes
```

### Helper Methods

```ruby
# Check if team has members/websites
team.has_members?    # => true
team.has_websites?   # => true

# Filter members by role
team.owners              # => Array of owner members
team.managers            # => Array of manager members
team.regular_members     # => Array of regular members
team.view_only_members   # => Array of view-only members

# Conversions
team.to_h       # => Hash representation
team.to_s       # => "#<UmamiClient::Team id=... name=... members=5>"
```

### Example: Team Report

```ruby
response = client.teams.get(team_id)
team = UmamiClient::Team.new(response.data)

puts "=" * 60
puts "TEAM REPORT: #{team.name}"
puts "=" * 60
puts "Created: #{team.created_at.strftime('%Y-%m-%d')}"
puts "Access Code: #{team.access_code}"
puts "\nStatistics:"
puts "  Members: #{team.member_count}"
puts "  Websites: #{team.website_count}"

puts "\nOwnership Structure:"
puts "  Owners: #{team.owners.length}"
puts "  Managers: #{team.managers.length}"
puts "  Members: #{team.regular_members.length}"
puts "  View-Only: #{team.view_only_members.length}"

puts "\nTeam Owners:"
team.owners.each do |owner|
  user = owner['user']
  puts "  - #{user['username']} (since #{owner['createdAt']})"
end
```

## Known Issues

### `/api/teams` Endpoint Returns 405

**Issue**: The standard `/api/teams` endpoint returns a 405 Method Not Allowed error.

**Workaround**: The gem automatically uses `/api/users/{user_id}/teams` instead when calling `client.teams.list()`.

**Reference**: [GitHub Issue #3195](https://github.com/umami-software/umami/issues/3195)

**Impact**: No action required - the gem handles this automatically.

## Complete Examples

### Example 1: Create Team and Invite Members

```ruby
require 'umami_client'

client = UmamiClient::Client.new(
  username: 'admin',
  password: 'password',
  base_url: 'https://analytics.example.com'
)

# Step 1: Create team
puts "Creating team..."
response = client.teams.create("Product Analytics Team")
team_data = response.data[0]
team_id = team_data['id']
access_code = team_data['accessCode']

puts "✓ Team created"
puts "  Team ID: #{team_id}"
puts "  Access Code: #{access_code}"

# Step 2: Get list of users to invite
puts "\nFetching users..."
users_response = client.users.list
users = users_response.data['data']

# Step 3: Add specific users to team
users_to_add = users.select { |u| u['username'] != 'admin' }

puts "\nAdding #{users_to_add.length} users to team..."
users_to_add.each do |user|
  response = client.teams.add_member(team_id, user['id'], 'team-member')

  if response.success?
    puts "  ✓ Added #{user['username']}"
  else
    puts "  ✗ Failed to add #{user['username']}: #{response.error_message}"
  end
end

# Step 4: Verify team setup
puts "\nVerifying team setup..."
response = client.teams.get(team_id)
team = UmamiClient::Team.new(response.data)

puts "✓ Team '#{team.name}' has #{team.member_count} members"
```

### Example 2: Team Member Management Dashboard

```ruby
require 'umami_client'

client = UmamiClient::Client.new(
  username: 'admin',
  password: 'password',
  base_url: 'https://analytics.example.com'
)

# Get all teams
teams_response = client.teams.list
teams = teams_response.data['data']

puts "=" * 60
puts "TEAM MANAGEMENT DASHBOARD"
puts "=" * 60

teams.each_with_index do |team_data, index|
  team = UmamiClient::Team.new(team_data)

  puts "\n#{index + 1}. #{team.name}"
  puts "   Access Code: #{team.access_code}"
  puts "   Members: #{team.member_count} | Websites: #{team.website_count}"

  if team.has_members?
    puts "\n   Team Structure:"

    if team.owners.any?
      puts "   Owners (#{team.owners.length}):"
      team.owners.each do |owner|
        puts "     - #{owner['user']['username']}"
      end
    end

    if team.managers.any?
      puts "   Managers (#{team.managers.length}):"
      team.managers.each do |manager|
        puts "     - #{manager['user']['username']}"
      end
    end

    if team.regular_members.any?
      puts "   Members (#{team.regular_members.length}):"
      team.regular_members.each do |member|
        puts "     - #{member['user']['username']}"
      end
    end
  end

  puts "   " + "-" * 56
end

puts "\nTotal Teams: #{teams.length}"
```

### Example 3: Promote User to Manager

```ruby
require 'umami_client'

def promote_to_manager(client, team_id, username)
  # Find user by username
  users_response = client.users.list(search: username)
  users = users_response.data['data']

  if users.empty?
    puts "User '#{username}' not found"
    return false
  end

  user = users.first
  user_id = user['id']

  # Check if user is team member
  members_response = client.teams.list_members(team_id)
  members = members_response.data['data']
  member = members.find { |m| m['userId'] == user_id }

  unless member
    puts "User '#{username}' is not a member of this team"
    return false
  end

  current_role = member['role']

  if current_role == 'team-manager' || current_role == 'team-owner'
    puts "User '#{username}' is already a #{current_role}"
    return false
  end

  # Promote to manager
  response = client.teams.update_member(team_id, user_id, 'team-manager')

  if response.success?
    puts "✓ Promoted #{username} from #{current_role} to team-manager"
    true
  else
    puts "✗ Failed to promote: #{response.error_message}"
    false
  end
end

# Usage
client = UmamiClient::Client.new(
  username: 'admin',
  password: 'password',
  base_url: 'https://analytics.example.com'
)

team_id = "your-team-id"
promote_to_manager(client, team_id, "john_doe")
```

### Example 4: Bulk Team Member Operations

```ruby
require 'umami_client'

class TeamManager
  def initialize(client, team_id)
    @client = client
    @team_id = team_id
  end

  def add_members(user_ids, role: 'team-member')
    results = { success: [], failed: [] }

    user_ids.each do |user_id|
      response = @client.teams.add_member(@team_id, user_id, role)

      if response.success?
        results[:success] << user_id
      else
        results[:failed] << { user_id: user_id, error: response.error_message }
      end
    end

    results
  end

  def remove_members(user_ids)
    results = { success: [], failed: [] }

    user_ids.each do |user_id|
      response = @client.teams.remove_member(@team_id, user_id)

      if response.success?
        results[:success] << user_id
      else
        results[:failed] << { user_id: user_id, error: response.error_message }
      end
    end

    results
  end

  def update_roles(role_map)
    results = { success: [], failed: [] }

    role_map.each do |user_id, new_role|
      response = @client.teams.update_member(@team_id, user_id, new_role)

      if response.success?
        results[:success] << { user_id: user_id, role: new_role }
      else
        results[:failed] << { user_id: user_id, error: response.error_message }
      end
    end

    results
  end
end

# Usage
client = UmamiClient::Client.new(
  username: 'admin',
  password: 'password',
  base_url: 'https://analytics.example.com'
)

team_id = "your-team-id"
manager = TeamManager.new(client, team_id)

# Add multiple members
user_ids = ["user-1-id", "user-2-id", "user-3-id"]
results = manager.add_members(user_ids, role: 'team-member')

puts "Added: #{results[:success].length}"
puts "Failed: #{results[:failed].length}"

# Update multiple roles
role_updates = {
  "user-1-id" => "team-manager",
  "user-2-id" => "team-member"
}
results = manager.update_roles(role_updates)

puts "Updated: #{results[:success].length} roles"
```

## Best Practices

### 1. Access Code Security

```ruby
# Regenerate access codes periodically
def rotate_access_code(client, team_id)
  new_code = "team_#{SecureRandom.hex(8)}"
  client.teams.update(team_id, access_code: new_code)
end

# Schedule rotation (e.g., monthly)
rotate_access_code(client, team_id)
```

### 2. Role-Based Access

```ruby
# Always use principle of least privilege
def add_user_with_appropriate_role(client, team_id, user_id, user_type)
  role = case user_type
  when :admin then 'team-manager'
  when :analyst then 'team-member'
  when :viewer then 'team-view-only'
  else 'team-member'
  end

  client.teams.add_member(team_id, user_id, role)
end
```

### 3. Error Handling

```ruby
# Always handle errors gracefully
def safe_team_operation
  response = client.teams.create("New Team")

  if response.success?
    team_data = response.data[0]
    yield team_data if block_given?
  else
    Rails.logger.error("Team creation failed: #{response.error_message}")
    nil
  end
rescue UmamiClient::Error => e
  Rails.logger.error("API error: #{e.message}")
  nil
end
```

### 4. Audit Logging

```ruby
# Log all team membership changes
def add_member_with_audit(client, team_id, user_id, role, admin_user)
  response = client.teams.add_member(team_id, user_id, role)

  if response.success?
    AuditLog.create(
      action: 'team_member_added',
      team_id: team_id,
      user_id: user_id,
      role: role,
      performed_by: admin_user.id,
      timestamp: Time.now
    )
  end

  response
end
```

## Common Use Cases

### Team Onboarding Workflow

```ruby
# 1. Create team for new project
team_response = client.teams.create("Project Alpha Analytics")
team_data = team_response.data[0]
team_id = team_data['id']

# 2. Add project members with appropriate roles
project_lead = "user-lead-id"
developers = ["user-dev1-id", "user-dev2-id"]
stakeholders = ["user-stake1-id", "user-stake2-id"]

client.teams.add_member(team_id, project_lead, 'team-manager')

developers.each do |dev_id|
  client.teams.add_member(team_id, dev_id, 'team-member')
end

stakeholders.each do |stake_id|
  client.teams.add_member(team_id, stake_id, 'team-view-only')
end

# 3. Share access code with team
puts "Project Alpha team created!"
puts "Access code: #{team_data['accessCode']}"
puts "Share this code with the team to join"
```

### Team Cleanup

```ruby
# Remove inactive team members
def cleanup_inactive_members(client, team_id, days: 90)
  response = client.teams.list_members(team_id)
  members = response.data['data']

  cutoff_date = Time.now - (days * 24 * 60 * 60)

  members.each do |member|
    created_at = Time.parse(member['createdAt'])

    # Skip owners and recent members
    next if member['role'] == 'team-owner'
    next if created_at > cutoff_date

    # Check if member has recent activity (implement your logic)
    if member_inactive?(member['userId'])
      response = client.teams.remove_member(team_id, member['userId'])
      puts "Removed inactive member: #{member['user']['username']}"
    end
  end
end
```

## Version Requirements

- **Umami v2.0.0+**: Teams feature introduced
- **Umami v2.10.0+**: Enhanced team management (recommended)
- **Umami v2.11.3+**: Team Manager role added

Check your Umami version before using Teams API features.

## Related Documentation

- [User Management](user-management.md) - Managing user accounts
- [Website Management](website-management.md) - Managing websites
- [Installation](installation.md) - Getting started
- [Usage Guide](usage.md) - Basic client usage

## Support

For issues or questions:
- Check [GitHub Issues](https://github.com/umami-software/umami/issues?q=teams)
- Review [Umami Teams Documentation](https://umami.is/docs/teams)
- Report bugs in the gem repository
