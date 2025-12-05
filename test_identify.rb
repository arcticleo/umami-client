#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'lib/umami_client'
require 'json'

puts "=" * 70
puts "Testing User Identification (Distinct IDs)"
puts "=" * 70
puts ""

# Configure the client
UmamiClient.configure do |config|
  config.base_url = ENV['UMAMI_BASE_URL']
  config.username = ENV['UMAMI_USERNAME']
  config.password = ENV['UMAMI_PASSWORD']
  config.website_id = ENV['UMAMI_WEBSITE_ID']
  config.default_hostname = ENV['UMAMI_HOSTNAME'] || "medlund.com"
end

puts "Configuration:"
puts "  Website ID: #{ENV['UMAMI_WEBSITE_ID']}"
puts "  Hostname: #{ENV['UMAMI_HOSTNAME'] || 'medlund.com'}"
puts ""

client = UmamiClient::Client.new

# Test 1: Simple identification
puts "Test 1: Simple user identification"
puts "-" * 70
begin
  response = client.events.identify("user_test_123")

  puts "✓ SUCCESS"
  puts "  Status: #{response.status}"
  puts "  Session ID: #{response.body['sessionId']}"
  puts "  Visit ID: #{response.body['visitId']}"
  puts ""
rescue StandardError => e
  puts "✗ ERROR: #{e.class} - #{e.message}"
  puts e.backtrace.first(3)
  exit 1
end

# Test 2: Identification with custom user properties
puts "Test 2: Identification with custom user data"
puts "-" * 70
begin
  response = client.events.identify(
    "user_john_doe",
    data: {
      email: "john@example.com",
      name: "John Doe",
      plan: "premium",
      signup_date: "2024-01-15",
      age: 35,
      active: true
    }
  )

  puts "✓ SUCCESS"
  puts "  Status: #{response.status}"
  puts "  Session ID: #{response.body['sessionId']}"
  puts "  Visit ID: #{response.body['visitId']}"
  puts ""
rescue StandardError => e
  puts "✗ ERROR: #{e.class} - #{e.message}"
  puts e.backtrace.first(3)
  exit 1
end

# Test 3: Track a pageview after identification
puts "Test 3: Track pageview after identifying user"
puts "-" * 70
begin
  # The same session ID should be returned
  response = client.events.track_pageview(
    "/dashboard",
    title: "Dashboard"
  )

  puts "✓ SUCCESS"
  puts "  Status: #{response.status}"
  puts "  Session ID: #{response.body['sessionId']} (should match previous)"
  puts ""
rescue StandardError => e
  puts "✗ ERROR: #{e.class} - #{e.message}"
  puts e.backtrace.first(3)
  exit 1
end

# Test 4: Validation - ID too long
puts "Test 4: Validation - unique_id exceeds 50 characters"
puts "-" * 70
begin
  long_id = "a" * 51
  response = client.events.identify(long_id)

  puts "✗ FAILED: Should have raised ValidationError"
  exit 1
rescue UmamiClient::ValidationError => e
  puts "✓ SUCCESS: Caught expected error"
  puts "  Error: #{e.message}"
  puts ""
end

# Test 5: Validation - empty ID
puts "Test 5: Validation - empty unique_id"
puts "-" * 70
begin
  response = client.events.identify("")

  puts "✗ FAILED: Should have raised ValidationError"
  exit 1
rescue UmamiClient::ValidationError => e
  puts "✓ SUCCESS: Caught expected error"
  puts "  Error: #{e.message}"
  puts ""
end

puts "=" * 70
puts "All Tests Passed!"
puts "=" * 70
puts ""
puts "Next steps:"
puts "  1. Check your Umami dashboard Sessions page"
puts "  2. Search for distinct IDs: 'user_test_123' or 'user_john_doe'"
puts "  3. You should see all events associated with these users"
puts ""
