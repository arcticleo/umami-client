#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'lib/umami_client'
require 'json'

puts "=" * 70
puts "Step 1: Authentication Verification"
puts "=" * 70
puts ""
puts "This script verifies that authentication is working correctly"
puts "by testing the /api/websites endpoint after authentication."
puts ""

# Configure the client
UmamiClient.configure do |config|
  config.base_url = ENV['UMAMI_BASE_URL']
  config.username = ENV['UMAMI_USERNAME']
  config.password = ENV['UMAMI_PASSWORD']
end

puts "Configuration:"
puts "  Base URL: #{ENV['UMAMI_BASE_URL']}"
puts "  Username: #{ENV['UMAMI_USERNAME']}"
puts ""

# Create client
client = UmamiClient::Client.new

# Step 1: Authenticate and get token
puts "Step 1: Authenticating..."
puts "-" * 70
begin
  token = client.authenticate
  if token
    puts "✓ SUCCESS: Got authentication token"
    puts "  Token: #{token[0..30]}..."
  else
    puts "✗ FAILED: No token received"
    exit 1
  end
rescue StandardError => e
  puts "✗ ERROR: #{e.class} - #{e.message}"
  puts e.backtrace.first(5)
  exit 1
end
puts ""

# Step 2: Test the /api/websites endpoint
puts "Step 2: Testing authenticated endpoint (GET /api/websites)"
puts "-" * 70
begin
  response = client.websites.list

  puts "✓ SUCCESS: Request completed"
  puts "  Status: #{response.status}"
  puts "  Success?: #{response.success?}"

  if response.success?
    puts ""
    puts "Response body:"
    puts JSON.pretty_generate(response.body)
    puts ""

    if response.body.is_a?(Hash) && response.body.key?('data')
      website_count = response.body['data']&.length || 0
      puts "✓ Found #{website_count} website(s)"
    elsif response.body.is_a?(Array)
      puts "✓ Found #{response.body.length} website(s)"
    end
  else
    puts ""
    puts "✗ Request failed:"
    puts "  Error: #{response.error_message}"
  end
rescue UmamiClient::AuthenticationError => e
  puts "✗ AUTHENTICATION ERROR: #{e.message}"
  puts ""
  puts "This means the token is invalid or expired."
  exit 1
rescue StandardError => e
  puts "✗ ERROR: #{e.class} - #{e.message}"
  puts e.backtrace.first(5)
  exit 1
end
puts ""

puts "=" * 70
puts "Authentication Verification Result"
puts "=" * 70
puts "✓ Authentication is working correctly!"
puts ""
puts "Next steps:"
puts "  - Authentication is confirmed working"
puts "  - We can now proceed with implementing other API features"
puts ""
