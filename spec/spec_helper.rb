# frozen_string_literal: true

require "umami_client"
require "webmock/rspec"
VCR_AVAILABLE = begin
  require "vcr"
  true
rescue LoadError, NameError
  # VCR (via its `cgi` dep) is broken on Ruby 4.0+ until upstream fixes
  # CGI.parse. Specs that don't use VCR still run.
  false
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

# Configure WebMock
WebMock.disable_net_connect!(allow_localhost: true)

# Configure VCR
if VCR_AVAILABLE
  VCR.configure do |config|
    config.cassette_library_dir = "spec/fixtures/vcr_cassettes"
    config.hook_into :webmock
    config.configure_rspec_metadata!
  end
end
