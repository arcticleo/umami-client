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

Configure globally:

```ruby
require 'umami_client'

UmamiClient.configure do |config|
  config.username = "your-username"
  config.password = "your-password"
  config.base_url = "https://your-umami-instance.com"
end
```

Or create a client with custom configuration:

```ruby
client = UmamiClient.new(
  username: "your-username",
  password: "your-password",
  base_url: "https://your-umami-instance.com"
)
```

**Note:** The client automatically detects which authentication method to use based on the credentials provided. For self-hosted instances, the client will automatically authenticate and manage bearer tokens.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/yourusername/umami-client.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
