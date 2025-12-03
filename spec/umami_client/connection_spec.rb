# frozen_string_literal: true

RSpec.describe UmamiClient::Connection do
  let(:api_key) { "test-api-key" }
  let(:base_url) { "https://api.umami.is" }
  let(:timeout) { 30 }
  let(:connection) { described_class.new(api_key: api_key, base_url: base_url, timeout: timeout) }

  describe "#initialize" do
    it "sets the api_key" do
      expect(connection.api_key).to eq(api_key)
    end

    it "sets the base_url" do
      expect(connection.base_url).to eq(base_url)
    end

    it "sets the timeout" do
      expect(connection.timeout).to eq(timeout)
    end
  end

  describe "#get" do
    it "performs a GET request" do
      stub_request(:get, "#{base_url}/test")
        .with(headers: { "x-umami-api-key" => api_key })
        .to_return(status: 200, body: '{"success": true}', headers: { "Content-Type" => "application/json" })

      response = connection.get("/test")
      expect(response["success"]).to be true
    end

    it "includes query parameters" do
      stub_request(:get, "#{base_url}/test?foo=bar")
        .with(headers: { "x-umami-api-key" => api_key })
        .to_return(status: 200, body: '{"success": true}', headers: { "Content-Type" => "application/json" })

      response = connection.get("/test", { foo: "bar" })
      expect(response["success"]).to be true
    end
  end

  describe "#post" do
    it "performs a POST request with body" do
      stub_request(:post, "#{base_url}/test")
        .with(
          headers: { "x-umami-api-key" => api_key, "Content-Type" => "application/json" },
          body: '{"name":"test"}'
        )
        .to_return(status: 200, body: '{"id": 1}', headers: { "Content-Type" => "application/json" })

      response = connection.post("/test", { name: "test" })
      expect(response["id"]).to eq(1)
    end
  end

  describe "error handling" do
    it "raises AuthenticationError on 401" do
      stub_request(:get, "#{base_url}/test")
        .to_return(status: 401, body: '{"message": "Unauthorized"}', headers: { "Content-Type" => "application/json" })

      expect { connection.get("/test") }.to raise_error(UmamiClient::AuthenticationError, /Unauthorized/)
    end

    it "raises BadRequestError on 400" do
      stub_request(:get, "#{base_url}/test")
        .to_return(status: 400, body: '{"message": "Bad request"}', headers: { "Content-Type" => "application/json" })

      expect { connection.get("/test") }.to raise_error(UmamiClient::BadRequestError, /Bad request/)
    end

    it "raises NotFoundError on 404" do
      stub_request(:get, "#{base_url}/test")
        .to_return(status: 404, body: '{"message": "Not found"}', headers: { "Content-Type" => "application/json" })

      expect { connection.get("/test") }.to raise_error(UmamiClient::NotFoundError, /Not found/)
    end

    it "raises RateLimitError on 429" do
      stub_request(:get, "#{base_url}/test")
        .to_return(status: 429, body: '{"message": "Rate limit exceeded"}', headers: { "Content-Type" => "application/json" })

      expect { connection.get("/test") }.to raise_error(UmamiClient::RateLimitError, /Rate limit exceeded/)
    end

    it "raises ServerError on 500" do
      stub_request(:get, "#{base_url}/test")
        .to_return(status: 500, body: '{"message": "Internal server error"}', headers: { "Content-Type" => "application/json" })

      expect { connection.get("/test") }.to raise_error(UmamiClient::ServerError, /Internal server error/)
    end

    it "raises NetworkError on connection failure" do
      stub_request(:get, "#{base_url}/test").to_raise(Faraday::ConnectionFailed.new("Failed to connect"))

      expect { connection.get("/test") }.to raise_error(UmamiClient::NetworkError, /Connection failed/)
    end
  end
end
