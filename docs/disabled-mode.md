# Disabled Mode for Testing

When running tests, you typically don't want to make actual HTTP requests to Umami. Disabled mode allows you to skip all HTTP requests while still validating parameters and returning mock responses.

## Basic Usage

```ruby
 Disable tracking
UmamiClient.disable!

 All tracking methods now return mock responses without making HTTP requests
client = UmamiClient::Client.new
response = client.events.track_pageview("/test")
 => Returns a mock response with status 200 and fake sessionId/visitId

 Check if disabled
UmamiClient.disabled? # => true

 Re-enable tracking
UmamiClient.enable!
```

## Test Configuration

### Minitest

```ruby
 test/test_helper.rb
require 'umami_client'

 Disable tracking for all tests
UmamiClient.disable!

 Or configure via config
UmamiClient.configure do |config|
  config.disabled = true
end
```

### RSpec

```ruby
 spec/spec_helper.rb
require 'umami_client'

RSpec.configure do |config|
  # Disable tracking before the test suite runs
  config.before(:suite) do
    UmamiClient.disable!
  end
end
```

### Rails

```ruby
 config/environments/test.rb
Rails.application.configure do
  # Disable Umami tracking in test environment
  config.after_initialize do
    UmamiClient.disable!
  end
end
```

## With Logging

You can enable logging to see what would have been tracked:

```ruby
require 'logger'

UmamiClient.configure do |config|
  config.disabled = true
  config.logger = Logger.new($stdout)
end

client = UmamiClient::Client.new
client.events.track_pageview("/test")
 Logs: [Umami Disabled] Would have tracked event: url=/test
```

## How It Works

When disabled mode is enabled:

- ✅ **No HTTP requests** are made to Umami
- ✅ **Parameters are still validated** (raises errors for invalid input)
- ✅ **Mock responses returned** with realistic structure (200 status, sessionId, visitId)
- ✅ **Optional logging** shows what would have been tracked
- ✅ **All tracking methods work** (track_pageview, track_event, identify)

## Example Test

```ruby
require 'minitest/autorun'
require 'umami_client'

class MyFeatureTest < Minitest::Test
  def setup
    UmamiClient.configure do |config|
      config.base_url = "https://umami.example.com"
      config.website_id = "test-id"
      config.default_hostname = "example.com"
      config.disabled = true  # Disable for tests
    end

    @client = UmamiClient::Client.new
  end

  def test_tracks_signup_event
    # This won't make an actual HTTP request
    response = @client.events.track_event("user_signup")

    assert_equal 200, response.status
    assert response.body['sessionId']
    # Your app logic continues normally
  end
end
```

