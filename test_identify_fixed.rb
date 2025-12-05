#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'lib/umami_client'
require 'json'

puts "=" * 70
puts "Testing Fixed Identify with type: 'identify'"
puts "=" * 70
puts ""

UmamiClient.configure do |config|
  config.base_url = ENV['UMAMI_BASE_URL']
  config.username = ENV['UMAMI_USERNAME']
  config.password = ENV['UMAMI_PASSWORD']
  config.website_id = "f5e53756-0264-435b-bb76-3a9b8fdcb176"
  config.default_hostname = "medlund.com"
end

client = UmamiClient::Client.new

# Test 1: Identify with user properties
puts "1. Identifying user with properties (using type: 'identify')..."
user_email = "fixed.test@example.com"

response = client.events.identify(
  user_email,
  data: {
    name: "Fixed Test User",
    plan: "enterprise",
    signup_date: "2024-12-04",
    country: "Sweden",
    verified: true,
    monthly_revenue: 299.99
  }
)

puts "   ✓ Identified"
puts "   Status: #{response.status}"
puts "   Session ID: #{response.body['sessionId']}"
puts ""

# Test 2: Track a pageview after identification
puts "2. Tracking pageview after identification..."
response = client.events.track_pageview(
  "/dashboard",
  title: "Dashboard - Fixed Test"
)
puts "   ✓ Tracked"
puts "   Session ID: #{response.body['sessionId']}"
puts ""

# Test 3: Another pageview
puts "3. Tracking another pageview..."
response = client.events.track_pageview(
  "/settings",
  title: "Settings - Fixed Test"
)
puts "   ✓ Tracked"
puts "   Session ID: #{response.body['sessionId']}"
puts ""

puts "=" * 70
puts "Now check your Umami dashboard:"
puts "  1. Go to Sessions"
puts "  2. Find: #{user_email}"
puts "  3. Click to view the session detail"
puts "  4. Check if the Properties column now shows:"
puts "     - name: Fixed Test User"
puts "     - plan: enterprise"
puts "     - signup_date: 2024-12-04"
puts "     - country: Sweden"
puts "     - verified: true"
puts "     - monthly_revenue: 299.99"
puts ""
puts "The key change: We now use type: 'identify' instead of type: 'event'"
puts "=" * 70
