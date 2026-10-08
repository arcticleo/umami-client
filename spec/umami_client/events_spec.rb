# frozen_string_literal: true

RSpec.describe UmamiClient::Events do
  let(:base_url) { "https://umami.example.com" }
  let(:website_id) { "9ebabcf4-df61-4583-83b5-c5c0a8d06150" }

  before do
    UmamiClient.configure do |config|
      config.api_key = nil
      config.username = nil
      config.password = nil
      config.base_url = base_url
      config.website_id = website_id
      config.default_hostname = "example.com"
    end
  end

  let(:client) { UmamiClient::Client.new }

  let!(:send_request) do
    stub_request(:post, "#{base_url}/api/send")
      .to_return(status: 200, body: { cache: "token" }.to_json, headers: { "Content-Type" => "application/json" })
  end

  it "tracks a pageview without credentials" do
    client.events.track_pageview("/")

    expect(send_request).to have_been_requested
  end

  it "sends the visitor's address and browser when given" do
    client.events.track_pageview("/download", ip: "203.0.113.7", user_agent: "Safari/605.1.15")

    expect(send_request.with { |req|
      payload = JSON.parse(req.body)["payload"]
      payload["ip"] == "203.0.113.7" && payload["userAgent"] == "Safari/605.1.15" && payload["url"] == "/download"
    }).to have_been_requested
  end

  it "leaves the visitor fields out by default" do
    client.events.track_event("click")

    expect(send_request.with { |req|
      payload = JSON.parse(req.body)["payload"]
      !payload.key?("ip") && !payload.key?("userAgent")
    }).to have_been_requested
  end

  it "refuses API calls without credentials" do
    expect { client.websites.list }.to raise_error(UmamiClient::ConfigurationError)
  end
end
