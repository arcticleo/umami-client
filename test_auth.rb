#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'lib/umami_client'

# Configure client with environment variables
UmamiClient.configure do |config|
  config.base_url = ENV['UMAMI_BASE_URL']
  config.username = ENV['UMAMI_USERNAME']
  config.password = ENV['UMAMI_PASSWORD']
end

puts "Testing authentication with:"
puts "Base URL: #{ENV['UMAMI_BASE_URL']}"
puts "Username: #{ENV['UMAMI_USERNAME']}"
puts ""

# Create a client instance
client = UmamiClient::Client.new

begin
  # Attempt to authenticate
  puts "Attempting to authenticate..."
  token = client.authenticate

  puts "✓ Authentication successful!"
  puts "Token received: #{token[0..20]}..." # Show first 20 chars
  puts ""
  puts "Authentication token has been stored in the client."

rescue StandardError => e
  puts "✗ Authentication failed!"
  puts "Error: #{e.message}"
  puts "Backtrace:" if ENV['DEBUG']
  puts e.backtrace.join("\n") if ENV['DEBUG']
  exit 1
end
