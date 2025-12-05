#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'lib/umami_client'
require 'json'

puts "=" * 70
puts "Demo: User Session with Identification"
puts "=" * 70
puts ""
puts "This script simulates a user browsing your site with tracking."
puts "Check your Umami dashboard Sessions page to see the results!"
puts ""

# Configure the client
UmamiClient.configure do |config|
  config.base_url = ENV['UMAMI_BASE_URL']
  config.username = ENV['UMAMI_USERNAME']
  config.password = ENV['UMAMI_PASSWORD']
  config.website_id = "f5e53756-0264-435b-bb76-3a9b8fdcb176" # from your website
  config.default_hostname = "medlund.com"
end

client = UmamiClient::Client.new

# User information
user_email = "demo.user@example.com"
user_name = "Demo User"

puts "Simulating user session for: #{user_email}"
puts "-" * 70
puts ""

# Step 1: User lands on homepage
puts "1. User visits homepage..."
response = client.events.track_pageview(
  "/",
  title: "Home - medlund.com",
  referrer: "https://google.com"
)
puts "   ✓ Tracked (Session: #{response.body['sessionId'][0..8]}...)"
sleep 0.5

# Step 2: User identifies (logs in or signs up)
puts "2. User logs in and gets identified..."
response = client.events.identify(
  user_email,
  data: {
    name: user_name,
    plan: "premium",
    signup_date: "2024-11-01",
    country: "USA",
    verified: true
  }
)
puts "   ✓ Identified (Session: #{response.body['sessionId'][0..8]}...)"
sleep 0.5

# Step 3: User browses to about page
puts "3. User visits about page..."
response = client.events.track_pageview(
  "/about",
  title: "About - medlund.com",
  referrer: "https://medlund.com/"
)
puts "   ✓ Tracked (Session: #{response.body['sessionId'][0..8]}...)"
sleep 0.5

# Step 4: User views blog
puts "4. User visits blog..."
response = client.events.track_pageview(
  "/blog",
  title: "Blog - medlund.com"
)
puts "   ✓ Tracked (Session: #{response.body['sessionId'][0..8]}...)"
sleep 0.5

# Step 5: User reads a specific blog post
puts "5. User reads blog post..."
response = client.events.track_pageview(
  "/blog/welcome-to-my-site",
  title: "Welcome to My Site - Blog - medlund.com"
)
puts "   ✓ Tracked (Session: #{response.body['sessionId'][0..8]}...)"
sleep 0.5

# Step 6: User tracks a custom event (button click)
puts "6. User clicks 'Subscribe' button..."
response = client.events.track_event(
  "subscribe_click",
  url: "/blog/welcome-to-my-site",
  data: {
    button_location: "blog_post_footer",
    post_title: "Welcome to My Site"
  }
)
puts "   ✓ Tracked event (Session: #{response.body['sessionId'][0..8]}...)"
sleep 0.5

# Step 7: User visits contact page
puts "7. User visits contact page..."
response = client.events.track_pageview(
  "/contact",
  title: "Contact - medlund.com"
)
puts "   ✓ Tracked (Session: #{response.body['sessionId'][0..8]}...)"
sleep 0.5

# Step 8: User submits contact form (custom event)
puts "8. User submits contact form..."
response = client.events.track_event(
  "contact_form_submit",
  url: "/contact",
  data: {
    form_name: "contact",
    message_length: 250,
    subject: "General inquiry"
  }
)
puts "   ✓ Tracked event (Session: #{response.body['sessionId'][0..8]}...)"

puts ""
puts "=" * 70
puts "Session Complete!"
puts "=" * 70
puts ""
puts "Now go to your Umami dashboard and:"
puts "  1. Navigate to: Sessions page"
puts "  2. Look for visitor with email: #{user_email}"
puts "  3. Click on their avatar to see the full session"
puts "  4. You should see all 6 pageviews and 2 custom events"
puts "  5. Check the Properties tab to see the custom user data"
puts ""
puts "You can also:"
puts "  - Search for '#{user_email}' in the Sessions search"
puts "  - View the Events page to see custom events"
puts "  - See all the page paths visited"
puts ""
