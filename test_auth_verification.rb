#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'lib/umami_client'
require 'json'

puts "Authentication Verification Test"
puts "=" * 60
puts ""

UmamiClient.configure do |config|
  config.base_url = ENV['UMAMI_BASE_URL']
  config.username = ENV['UMAMI_USERNAME']
  config.password = ENV['UMAMI_PASSWORD']
end

client = UmamiClient::Client.new

puts "1. Authenticating..."
token = client.authenticate
puts "   ✓ Got token: #{token[0..30]}..."
puts ""

puts "2. Testing authenticated endpoints..."
puts ""

# Test /api/me (current user info)
puts "   a) GET /api/me"
begin
  response = client.connection.get("/api/me")
  puts "      Status: #{response.status}"
  if response.success?
    puts "      ✓ SUCCESS"
    puts "      User: #{response.body.inspect}"
  else
    puts "      ✗ FAILED: #{response.error_message}"
  end
rescue StandardError => e
  puts "      ✗ ERROR: #{e.class} - #{e.message}"
end
puts ""

# Test /api/websites
puts "   b) GET /api/websites"
begin
  response = client.connection.get("/api/websites")
  puts "      Status: #{response.status}"
  if response.success?
    puts "      ✓ SUCCESS"
    puts "      Websites count: #{response.body['count']}"
    puts "      Data: #{response.body.inspect}"
  else
    puts "      ✗ FAILED: #{response.error_message}"
  end
rescue StandardError => e
  puts "      ✗ ERROR: #{e.class} - #{e.message}"
end
puts ""

# Test /api/teams
puts "   c) GET /api/teams"
begin
  response = client.connection.get("/api/teams")
  puts "      Status: #{response.status}"
  if response.success?
    puts "      ✓ SUCCESS"
    puts "      Response: #{response.body.inspect}"
  else
    puts "      ✗ FAILED: #{response.error_message}"
  end
rescue StandardError => e
  puts "      ✗ ERROR: #{e.class} - #{e.message}"
end
puts ""

puts "=" * 60
puts "Summary:"
puts "  - Authentication: #{token ? 'Working (got token)' : 'Failed'}"
puts "  - Authenticated endpoints: Check results above"
puts ""
puts "If all endpoints return 401/403 or empty data:"
puts "  - The token is valid but the user has no permissions"
puts "  - The user might need admin role or team membership"
