# Umami Client

A Ruby client library for the [Umami Analytics API](https://umami.is/docs/api).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'umami-client'
```

And then execute:

```bash
$ bundle install
```

Or install it yourself as:

```bash
$ gem install umami-client
```

## Usage

### Configuration

The client supports two authentication methods:

#### 1. Umami Cloud (API Key Authentication)

Configure globally:

```ruby
require 'umami_client'

UmamiClient.configure do |config|
  config.api_key = "your-api-key"
  config.base_url = "https://api.umami.is" # optional, defaults to this
end
```

Or create a client with custom configuration:

```ruby
client = UmamiClient.new(
  api_key: "your-api-key",
  base_url: "https://api.umami.is"
)
```

#### 2. Self-Hosted (Username/Password Authentication)

For self-hosted Umami instances, use your web interface login credentials:

Configure globally:

```ruby
require 'umami_client'

UmamiClient.configure do |config|
  config.username = "your-username"  # Same as web login
  config.password = "your-password"  # Same as web login
  config.base_url = "https://your-umami-instance.com"
end

# Or use environment variables:
# UMAMI_USERNAME=your-username
# UMAMI_PASSWORD=your-password
# UMAMI_BASE_URL=https://your-umami-instance.com
```

Or create a client with custom configuration:

```ruby
client = UmamiClient.new(
  username: "your-username",
  password: "your-password",
  base_url: "https://your-umami-instance.com"
)
```

**How it works:** The client automatically detects which authentication method to use based on the credentials provided. For self-hosted instances, the client calls `/api/auth/login` with your credentials, receives a bearer token, and manages it automatically for all subsequent requests.

### Environment Variables

You can use environment variables to configure the client:

**For Umami Cloud:**
```bash
UMAMI_API_KEY=your-api-key
UMAMI_BASE_URL=https://api.umami.is  # optional
```

**For Self-Hosted:**
```bash
UMAMI_USERNAME=your-username
UMAMI_PASSWORD=your-password
UMAMI_BASE_URL=https://your-umami-instance.com
```

Then configure without passing values:
```ruby
UmamiClient.configure do |config|
  config.api_key = ENV['UMAMI_API_KEY']           # for Cloud
  config.username = ENV['UMAMI_USERNAME']         # for self-hosted
  config.password = ENV['UMAMI_PASSWORD']         # for self-hosted
  config.base_url = ENV['UMAMI_BASE_URL']
end
```

## Event Tracking

### Track Pageviews

Track page views on your website:

```ruby
UmamiClient.configure do |config|
  config.base_url = "https://your-umami-instance.com"
  config.username = "your-username"
  config.password = "your-password"
  config.website_id = "your-website-id"
  config.default_hostname = "example.com"
end

client = UmamiClient::Client.new

# Simple pageview
client.events.track_pageview("/")

# Pageview with title
client.events.track_pageview("/products", title: "Products Page")

# Pageview with referrer
client.events.track_pageview(
  "/blog/post-1",
  title: "Blog Post",
  referrer: "https://google.com"
)
```

### Track Custom Events

Track custom events with optional data:

```ruby
# Simple event
client.events.track_event("button_click")

# Event with custom data
client.events.track_event(
  "purchase",
  url: "/checkout/complete",
  data: {
    amount: 99.99,
    currency: "USD",
    product_id: "prod_123"
  }
)
```

**Note:** Custom events with the `name` field may not show up in some Umami versions. For reliable tracking, use `track_pageview` instead.

### User Identification

Identify users to track their activity across sessions and devices. User properties are stored persistently and appear in the Properties column of the Session detail view in your Umami dashboard.

#### Basic Usage

```ruby
# Identify a user by unique ID (email, user ID, customer ID, etc.)
client.events.identify("user@example.com")

# Identify with custom user properties
client.events.identify(
  "user_12345",
  data: {
    name: "John Doe",
    email: "john@example.com",
    plan: "premium",
    signup_date: "2024-01-15",
    country: "USA",
    monthly_revenue: 99.99,
    is_verified: true
  }
)
```

#### When to Call Identify

**Call `identify` once per user session, typically:**

1. **After user login/authentication**
   ```ruby
   def after_sign_in(user)
     UmamiClient::Client.new.events.identify(
       user.email,
       data: {
         name: user.name,
         plan: user.subscription_plan,
         signup_date: user.created_at.to_date.to_s
       }
     )
   end
   ```

2. **After user registration**
   ```ruby
   def after_create_user(user)
     UmamiClient::Client.new.events.identify(
       user.id.to_s,
       data: {
         name: user.name,
         source: user.signup_source,
         plan: "free"
       }
     )
   end
   ```

3. **When user properties change** (optional - update important changes)
   ```ruby
   def after_upgrade_plan(user)
     UmamiClient::Client.new.events.identify(
       user.email,
       data: {
         plan: user.subscription_plan,
         upgraded_at: Time.now.to_s
       }
     )
   end
   ```

#### How Often to Call Identify

**DO:**
- ✅ Call once per session when the user logs in
- ✅ Call after registration to set initial user properties
- ✅ Call when important user properties change (plan upgrade, etc.)

**DON'T:**
- ❌ Call on every page view (it's not necessary - user ID persists automatically)
- ❌ Call multiple times in the same session with the same data
- ❌ Call for anonymous/unauthenticated users (unless you have a persistent anonymous ID)

#### User ID Persistence

Once you call `identify`, the user ID automatically persists across all subsequent events:

```ruby
client = UmamiClient::Client.new

# Identify the user once
client.events.identify("user@example.com", data: { name: "John" })

# All subsequent events automatically include the user ID
client.events.track_pageview("/dashboard")  # ← includes user ID
client.events.track_event("button_click")    # ← includes user ID
client.events.track_pageview("/settings")    # ← includes user ID

# Clear the user ID when done (e.g., on logout)
client.events.reset_user
```

#### Best Practices

1. **Use stable identifiers** - Use IDs that don't change (user ID, email, customer ID)
   ```ruby
   # Good
   identify(user.id.to_s)           # Database ID
   identify(user.email)              # Email address
   identify(user.stripe_customer_id) # External service ID

   # Avoid
   identify(user.session_token)      # Changes frequently
   identify(SecureRandom.uuid)       # Random, not persistent
   ```

2. **Keep user properties meaningful** - Store data you'll actually use for analysis
   ```ruby
   # Good - actionable properties
   identify(user.email, data: {
     plan: "premium",          # Segment by plan
     signup_date: "2024-01-15", # Cohort analysis
     country: "USA"             # Geographic analysis
   })

   # Too much - probably unnecessary
   identify(user.email, data: {
     favorite_color: "blue",
     pet_name: "Fluffy",
     shoe_size: 10
   })
   ```

3. **Don't send sensitive data** - User properties are stored in Umami
   ```ruby
   # Bad - don't send passwords, tokens, or PII you don't need
   identify(user.email, data: {
     password_hash: user.encrypted_password,  # ❌ Never
     ssn: user.social_security,               # ❌ Never
     credit_card: user.cc_last_4              # ❌ Be careful
   })
   ```

4. **Handle logout** - Clear user identification when users log out
   ```ruby
   def after_sign_out
     client = UmamiClient::Client.new
     client.events.reset_user  # Clears the user ID
   end
   ```

#### Rails Integration Example

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  after_action :identify_user, if: :user_signed_in?

  private

  def identify_user
    # Only identify once per session
    return if session[:umami_identified]

    umami_client.events.identify(
      current_user.email,
      data: {
        name: current_user.name,
        plan: current_user.subscription_plan,
        signup_date: current_user.created_at.to_date.to_s
      }
    )

    session[:umami_identified] = true
  end

  def umami_client
    @umami_client ||= UmamiClient::Client.new
  end
end
```

#### Viewing User Properties

In your Umami dashboard:
1. Navigate to **Sessions**
2. Click on a visitor to view their session details
3. The **Properties** column on the right shows all user properties
4. You can also search for users by their distinct ID

### Configuration Options

```ruby
UmamiClient.configure do |config|
  # Required
  config.base_url = "https://your-umami-instance.com"
  config.username = "your-username"
  config.password = "your-password"
  config.website_id = "your-website-id"
  config.default_hostname = "example.com"

  # Optional
  config.user_agent = "Mozilla/5.0 ..." # Default: Safari on macOS
  config.timeout = 30                    # Request timeout in seconds
  config.max_retries = 3                 # Max retry attempts
  config.retry_delay = 0.5               # Initial retry delay
  config.backoff_factor = 2              # Exponential backoff multiplier
end
```

### Custom User-Agent

The User-Agent string determines how Umami parses OS and device information. You can customize it:

```ruby
# Default (macOS Safari)
config.user_agent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.1 Safari/605.1.15"

# Windows Chrome
config.user_agent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

# iPhone Safari
config.user_agent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"
```

## Website Management

### List Websites

```ruby
client = UmamiClient::Client.new

# List all websites
websites = client.websites.list
websites.body["data"].each do |website|
  puts "#{website['name']}: #{website['id']}"
end

# Get specific website
website = client.websites.get("website-id")
puts website.body["name"]
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/yourusername/umami-client.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
