#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'lib/umami_client'
require 'json'

puts "=" * 70
puts "Demo: Events with Custom Data Properties"
puts "=" * 70
puts ""

# Configure the client
UmamiClient.configure do |config|
  config.base_url = ENV['UMAMI_BASE_URL']
  config.username = ENV['UMAMI_USERNAME']
  config.password = ENV['UMAMI_PASSWORD']
  config.website_id = "f5e53756-0264-435b-bb76-3a9b8fdcb176"
  config.default_hostname = "medlund.com"
end

client = UmamiClient::Client.new

# Identify the user
puts "1. Identifying user: test.properties@example.com"
client.events.identify(
  "test.properties@example.com",
  data: {
    user_type: "premium",
    country: "USA"
  }
)
puts "   ✓ Identified"
puts ""

# Track pageview with custom properties
puts "2. Track pageview with custom event data..."
response = client.events.track_event(
  "page_view",
  url: "/products",
  data: {
    product_category: "electronics",
    price_range: "high",
    in_stock: true,
    items_count: 25
  }
)
puts "   ✓ Tracked with properties"
puts ""

# Track a button click with properties
puts "3. Track button click with properties..."
response = client.events.track_event(
  "button_click",
  url: "/products",
  data: {
    button_name: "add_to_cart",
    product_id: "PROD123",
    product_price: 99.99,
    quantity: 2
  }
)
puts "   ✓ Tracked with properties"
puts ""

# Track form submission with properties
puts "4. Track form submit with properties..."
response = client.events.track_event(
  "form_submit",
  url: "/contact",
  data: {
    form_type: "contact",
    has_attachment: false,
    message_length: 250,
    response_time_ms: 1250
  }
)
puts "   ✓ Tracked with properties"
puts ""

puts "=" * 70
puts "Check your Umami dashboard:"
puts "  1. Go to Sessions and find: test.properties@example.com"
puts "  2. Look at the Properties column/tab for each event"
puts "  3. Or go to the Events page and click 'Event data' button"
puts "  4. You should see the custom properties we sent"
puts ""
