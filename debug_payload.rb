#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'lib/umami_client'
require 'json'

puts "=" * 70
puts "Debug: Inspecting Actual Payload Sent to Umami"
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

# First, identify the user
puts "1. Identifying user..."
client.events.identify("debug.test@example.com", data: { role: "admin" })
puts ""

# Now let's manually construct and inspect what we're sending
puts "2. Building a test event payload to inspect..."
puts ""

# Simulate what track_event does internally
event_name = "test_event"
url = "/test"
data = {
  string_prop: "hello",
  number_prop: 42,
  bool_prop: true,
  nested: { key: "value" }
}

# This is what we're building in track_event
payload = {
  type: "event",
  payload: {
    website: "f5e53756-0264-435b-bb76-3a9b8fdcb176",
    hostname: "medlund.com",
    url: url,
    name: event_name,
    screen: "1920x1080",
    language: "en-US",
    id: "debug.test@example.com",
    data: data
  }
}

puts "Payload structure we're sending:"
puts JSON.pretty_generate(payload)
puts ""

# Now actually send it
puts "3. Sending the event..."
response = client.events.track_event(
  "test_event",
  url: "/test",
  data: {
    string_prop: "hello",
    number_prop: 42,
    bool_prop: true
  }
)

puts "✓ Response received"
puts "  Status: #{response.status}"
puts "  Body: #{JSON.pretty_generate(response.body)}"
puts ""

puts "=" * 70
puts "Next steps:"
puts "  1. Check if the payload structure above looks correct"
puts "  2. Go to Umami dashboard > Websites > View"
puts "  3. Click the 'Events' tab (not Sessions)"
puts "  4. Look for 'test_event' in the events list"
puts "  5. Click on it - does it show the properties there?"
puts ""
