# frozen_string_literal: true

RSpec.describe 'UmamiClient::Stats filter handling' do
  let(:base_url) { 'https://api.umami.is' }
  let(:website_id) { 'abc-123' }
  let(:connection) { UmamiClient::Connection.new(api_key: 'test-key', base_url: base_url, timeout: 30) }
  let(:stats) { UmamiClient::Stats.new(connection: connection) }

  # Use absolute timestamps so we can match the URL precisely.
  let(:start_at) { 1_700_000_000_000 }
  let(:end_at)   { 1_700_086_400_000 }
  let(:start_time) { Time.at(start_at / 1000) }
  let(:end_time)   { Time.at(end_at / 1000) }

  let(:json_response) do
    { status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' } }
  end

  describe 'filters: kwarg' do
    it 'flattens a single-key filter into a top-level query param on summary' do
      stub = stub_request(:get, "#{base_url}/api/websites/#{website_id}/stats")
             .with(query: { startAt: start_at.to_s, endAt: end_at.to_s, country: 'SG' })
             .to_return(**json_response)

      stats.summary(website_id, start_time, end_time, filters: { country: 'SG' })

      expect(stub).to have_been_requested
    end

    it 'flattens multi-key filters on metrics' do
      stub = stub_request(:get, "#{base_url}/api/websites/#{website_id}/metrics")
             .with(query: hash_including(country: 'SG', device: 'mobile', type: 'url'))
             .to_return(**json_response)

      stats.metrics(website_id, start_time, end_time, 'url', filters: { country: 'SG', device: 'mobile' })

      expect(stub).to have_been_requested
    end

    it "does not send a nested 'filters' query param" do
      stub_request(:get, %r{api/websites}).to_return(**json_response)

      stats.summary(website_id, start_time, end_time, filters: { country: 'VN' })

      expect(WebMock).not_to have_requested(:get, /filters%5B/) # filters[ encoded
    end

    it 'is a no-op when filters is nil' do
      stub = stub_request(:get, "#{base_url}/api/websites/#{website_id}/stats")
             .with(query: { startAt: start_at.to_s, endAt: end_at.to_s })
             .to_return(**json_response)

      stats.summary(website_id, start_time, end_time)

      expect(stub).to have_been_requested
    end

    it 'is a no-op when filters is an empty hash' do
      stub = stub_request(:get, "#{base_url}/api/websites/#{website_id}/stats")
             .with(query: { startAt: start_at.to_s, endAt: end_at.to_s })
             .to_return(**json_response)

      stats.summary(website_id, start_time, end_time, filters: {})

      expect(stub).to have_been_requested
    end
  end
end
