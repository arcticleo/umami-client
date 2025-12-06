# Rails Integration

The Umami Client gem provides comprehensive Rails integration for seamless analytics tracking in Ruby on Rails applications.

## Overview

Rails integration includes:
- ✅ **Automatic Configuration**: Configure via Rails config files
- ✅ **Railtie Integration**: Automatic setup and initialization
- 🚧 **Rack Middleware**: Automatic page view tracking (coming soon)
- 🚧 **View Helpers**: Client-side and server-side tracking helpers (coming soon)
- 🚧 **Controller Concerns**: DSL for tracking page views and custom events (coming soon)
- 🚧 **Rails Generators**: Easy setup and configuration (coming soon)
- 🚧 **Background Jobs**: AsyncJob integration for tracking (coming soon)
- 🚧 **Reports Helpers**: Common analytics patterns and dashboards (coming soon)

## Installation

Add the gem to your Rails application's Gemfile:

```ruby
gem 'umami-client'
```

Run bundle:

```bash
bundle install
```

The Rails integration will be automatically loaded when Rails is present. No manual setup required.

## Configuration

### Basic Configuration

The gem automatically integrates with Rails configuration. You can configure it in any of your Rails config files:

```ruby
# config/application.rb
module YourApp
  class Application < Rails::Application
    # Umami Cloud configuration
    config.umami_client.api_key = ENV['UMAMI_API_KEY']
    config.umami_client.base_url = "https://api.umami.is"
    config.umami_client.website_id = ENV['UMAMI_WEBSITE_ID']
  end
end
```

Or for self-hosted Umami:

```ruby
# config/application.rb
config.umami_client.username = ENV['UMAMI_USERNAME']
config.umami_client.password = ENV['UMAMI_PASSWORD']
config.umami_client.base_url = ENV['UMAMI_BASE_URL']
config.umami_client.website_id = ENV['UMAMI_WEBSITE_ID']
```

### Environment-Specific Configuration

Configure differently per environment:

```ruby
# config/environments/production.rb
Rails.application.configure do
  config.umami_client.api_key = ENV['UMAMI_API_KEY']
  config.umami_client.website_id = ENV['UMAMI_WEBSITE_ID']
end

# config/environments/development.rb
Rails.application.configure do
  # Disable tracking in development
  config.umami_client.disabled = true
end

# config/environments/test.rb
Rails.application.configure do
  # Always disable in test
  config.umami_client.disabled = true
end
```

### Available Configuration Options

All standard UmamiClient configuration options are available via `config.umami_client`:

**Authentication:**
- `api_key` - API key for Umami Cloud
- `username` - Username for self-hosted authentication
- `password` - Password for self-hosted authentication
- `base_url` - Umami instance URL

**Tracking:**
- `website_id` - Default website ID for tracking
- `default_hostname` - Default hostname for events
- `user_agent` - Custom user agent string

**Behavior:**
- `disabled` - Disable all tracking (default: `false`)
- `logger` - Custom logger instance

**Connection:**
- `timeout` - Request timeout in seconds (default: `30`)
- `max_retries` - Maximum retry attempts (default: `3`)
- `retry_delay` - Initial retry delay in seconds (default: `1`)
- `backoff_factor` - Exponential backoff multiplier (default: `2`)

**Rails-Specific:**
- `middleware_enabled` - Enable automatic middleware (default: `false`)
- `skip_paths` - Array/regex of paths to skip in middleware (default: `[]`)
- `skip_assets` - Skip asset requests in middleware (default: `true`)
- `async` - Use background jobs for tracking (default: `true`)

### Configuration via Initializer

You can also use a traditional initializer file:

```ruby
# config/initializers/umami_client.rb
UmamiClient.configure do |config|
  config.api_key = ENV['UMAMI_API_KEY']
  config.base_url = ENV['UMAMI_BASE_URL']
  config.website_id = ENV['UMAMI_WEBSITE_ID']
end
```

Both approaches work - use whichever fits your preference. The Rails config approach (`config.umami_client`) is more Rails-idiomatic.

### Configuration Validation

The gem automatically validates your configuration when Rails boots (unless `disabled: true` is set). This helps catch configuration errors early.

**Required Configuration:**
- **Authentication**: Either `api_key` OR (`username` AND `password`) must be provided
- **Base URL**: `base_url` must be provided

**Warnings:**
- If `website_id` is missing but `middleware_enabled` is true, a warning will be logged

**Example Validation Error:**

If you forget to configure authentication:

```
UmamiClient::ConfigurationError: UmamiClient configuration errors:
  - Either api_key or username/password must be configured
  - base_url must be configured
```

**Bypassing Validation:**

If you want to skip validation (e.g., in development where tracking is disabled):

```ruby
# config/environments/development.rb
config.umami_client.disabled = true  # Validation will be skipped
```

## Automatic Initialization

The gem uses a Rails Railtie to automatically:
- Load when Rails starts
- Configure from `config.umami_client` settings
- Register middleware (when enabled)
- Load rake tasks
- Make generators available
- Set up view helpers and controller concerns

**No manual setup required!** Just add the gem and configure it.

## Using the Client in Rails

Access the UmamiClient anywhere in your Rails application:

```ruby
# In controllers
class ArticlesController < ApplicationController
  def show
    @article = Article.find(params[:id])

    # Track custom event
    client = UmamiClient::Client.new
    client.events.send(
      website_id: ENV['UMAMI_WEBSITE_ID'],
      url: request.url,
      title: @article.title,
      name: 'article_view',
      data: { category: @article.category }
    )
  end
end

# In models
class User < ApplicationRecord
  after_create :track_signup

  private

  def track_signup
    client = UmamiClient::Client.new
    client.events.send(
      website_id: ENV['UMAMI_WEBSITE_ID'],
      url: '/signup',
      name: 'user_signup',
      data: { plan: plan, source: referral_source }
    )
  end
end

# In background jobs
class AnalyticsJob < ApplicationJob
  def perform(event_name, data)
    client = UmamiClient::Client.new
    client.events.send(
      website_id: ENV['UMAMI_WEBSITE_ID'],
      name: event_name,
      data: data
    )
  end
end
```

## Rack Middleware

🚧 **Coming Soon** - Automatic page view tracking via Rack middleware

The middleware will automatically track page views for every request, with options to:
- Skip specific paths (assets, health checks, etc.)
- Track asynchronously via background jobs
- Add custom data via callbacks
- Filter sensitive information

## View Helpers

🚧 **Coming Soon** - View helpers for client-side and server-side tracking

Helpers will include:
- `umami_script_tag` - JavaScript tracker integration
- `umami_event_attributes` - Data attributes for automatic tracking
- `umami_track_event` - Server-side event tracking
- `umami_identify` - User identification
- And more...

## Controller Concerns

🚧 **Coming Soon** - Controller concern for easy tracking

The `Trackable` concern will provide:
- Automatic page view tracking
- Custom event tracking DSL
- Conditional tracking (if/unless)
- User context integration
- And more...

## Rails Generators

🚧 **Coming Soon** - Generators for easy setup

Generators will include:
- `rails generate umami_client:install` - Create initializer
- `rails generate umami_client:config` - Interactive setup
- `rails generate umami_client:views` - Tracking script partials
- `rails generate umami_client:dashboard` - Analytics dashboard
- And more...

## Background Job Integration

🚧 **Coming Soon** - ActiveJob integration for async tracking

Background job features will include:
- `UmamiClient::TrackEventJob` - Async event tracking
- `UmamiClient::TrackPageViewJob` - Async page view tracking
- Automatic retry logic
- Integration with middleware and concerns

## Reports Helpers

🚧 **Coming Soon** - Helpers for common analytics patterns

Reports helpers will include:
- Pre-configured funnel helpers (signup, checkout, onboarding)
- Common goal helpers (e-commerce, SaaS, content)
- Retention analysis helpers
- Visualization helpers (tables, charts, heatmaps)
- And more...

## Testing

Disable tracking in your test environment:

```ruby
# config/environments/test.rb
Rails.application.configure do
  config.umami_client.disabled = true
end
```

Or use the disabled mode in specific tests:

```ruby
RSpec.describe ArticlesController do
  before do
    UmamiClient.disable!
  end

  after do
    UmamiClient.enable!
  end

  it "tracks article views" do
    # Tracking is disabled, no HTTP requests made
    get :show, params: { id: 1 }
    expect(response).to be_successful
  end
end
```

## Best Practices

### 1. Use Environment Variables

Store credentials in environment variables, never commit them:

```ruby
# config/application.rb
config.umami_client.api_key = ENV['UMAMI_API_KEY']
config.umami_client.website_id = ENV['UMAMI_WEBSITE_ID']
```

### 2. Disable in Development/Test

Avoid unnecessary tracking and external requests:

```ruby
# config/environments/development.rb
config.umami_client.disabled = true

# config/environments/test.rb
config.umami_client.disabled = true
```

### 3. Use Background Jobs

Track events asynchronously to avoid blocking requests:

```ruby
config.umami_client.async = true
```

### 4. Monitor Errors

Add error handling for tracking failures:

```ruby
def track_event(name, data)
  client = UmamiClient::Client.new
  client.events.send(name: name, data: data)
rescue UmamiClient::Error => e
  Rails.logger.error "Umami tracking failed: #{e.message}"
  # Don't let tracking errors break the app
end
```

## Troubleshooting

### Railtie Not Loading

Make sure Rails is present when the gem loads. The Railtie only loads when `Rails::Railtie` is defined.

### Configuration Validation Errors

If Rails fails to boot with a `UmamiClient::ConfigurationError`:

1. **Check authentication**: Make sure you've set either `api_key` OR both `username` and `password`
2. **Check base_url**: Make sure `base_url` is set
3. **Check environment variables**: Verify ENV vars are loaded (try `puts ENV['UMAMI_API_KEY']` in the config file)
4. **Disable temporarily**: Set `config.umami_client.disabled = true` to bypass validation during setup

Example fix:

```ruby
# config/application.rb
config.umami_client.api_key = ENV['UMAMI_API_KEY']  # Make sure this ENV var exists!
config.umami_client.base_url = ENV['UMAMI_BASE_URL']  # And this one too!
```

### Configuration Not Applied

Check that you're configuring in the right place:
- `config/application.rb` for all environments
- `config/environments/*.rb` for environment-specific settings
- Configuration is applied during Rails initialization

### Tracking Not Working

Check the configuration:

```ruby
# In rails console
Rails.application.config.umami_client
# => #<ActiveSupport::OrderedOptions ...>

UmamiClient.configuration.disabled?
# => false (should be false for tracking to work)

UmamiClient.configuration.api_key
# => "your-api-key"
```

## Related Documentation

- [Installation](installation.md) - General installation instructions
- [Usage](usage.md) - Basic usage and configuration
- [Event Tracking](event-tracking.md) - Tracking events and page views
- [Disabled Mode](disabled-mode.md) - Testing with tracking disabled

---

**Note**: This documentation is being built incrementally. Sections marked with 🚧 are planned features that will be added in future updates. Check back as new features are implemented!
