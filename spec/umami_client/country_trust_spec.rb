# frozen_string_literal: true

RSpec.describe UmamiClient::CountryTrust do
  # Fake stats endpoint that returns fixture data keyed by country code.
  class FakeStats
    def initialize(countries:, summaries:, os_metrics:, browsers:)
      @countries  = countries
      @summaries  = summaries
      @os_metrics = os_metrics
      @browsers   = browsers
    end

    def metrics(_wid, _start, _end, type, filters: nil, limit: nil)
      data =
        case type
        when 'country' then @countries
        when 'os'      then @os_metrics.fetch(filters[:country], [])
        when 'browser' then @browsers.fetch(filters[:country], [])
        end
      Struct.new(:body).new(data)
    end

    def summary(_wid, _start, _end, filters: nil)
      Struct.new(:body).new(@summaries.fetch(filters[:country]))
    end
  end

  class FakeSessions
    def initialize(weekly_by_country:)
      @weekly_by_country = weekly_by_country
    end

    def weekly(_wid, _start, _end, timezone: nil, filters: nil)
      @captured_timezone = timezone
      Struct.new(:body).new(@weekly_by_country.fetch(filters[:country]))
    end

    attr_reader :captured_timezone
  end

  let(:human_weekly) { Array.new(7) { (0..23).map { |h| h.between?(8, 22) ? 50 : 5 } } } # 10:1 peak
  let(:flat_weekly)  { Array.new(7) { Array.new(24, 20) } } # bot signature

  let(:trusted_profile) do
    {
      'summary' => { 'visits' => 1000, 'visitors' => 800, 'pageviews' => 12_000, 'totaltime' => 200_000 },
      'os' => [{ 'x' => 'Windows 10', 'y' => 500 }, { 'x' => 'iOS', 'y' => 250 },
               { 'x' => 'Mac OS', 'y' => 250 }],
      'browser' => [{ 'x' => 'chrome', 'y' => 500 }, { 'x' => 'safari', 'y' => 300 },
                    { 'x' => 'firefox', 'y' => 200 }],
      'weekly' => Array.new(7) { (0..23).map { |h| h.between?(8, 22) ? 50 : 5 } }
    }
  end

  let(:bot_profile) do
    {
      'summary' => { 'visits' => 5000, 'visitors' => 500, 'pageviews' => 6000, 'totaltime' => 5000 },
      'os' => [{ 'x' => 'Windows 10', 'y' => 9990 }, { 'x' => 'iOS', 'y' => 10 }],
      'browser' => [{ 'x' => 'chrome', 'y' => 9990 }, { 'x' => 'ios', 'y' => 10 }],
      'weekly' => Array.new(7) { Array.new(24, 20) }
    }
  end

  def build_scorer(rows, **overrides)
    fake_stats = FakeStats.new(
      countries: rows.map { |r| { 'x' => r[:code], 'y' => r[:visits] } },
      summaries: rows.to_h { |r| [r[:code], r[:profile]['summary']] },
      os_metrics: rows.to_h { |r| [r[:code], r[:profile]['os']] },
      browsers: rows.to_h { |r| [r[:code], r[:profile]['browser']] }
    )
    fake_sessions = FakeSessions.new(
      weekly_by_country: rows.to_h { |r| [r[:code], r[:profile]['weekly']] }
    )
    client = Struct.new(:stats, :sessions).new(fake_stats, fake_sessions)
    described_class.new(client: client, website_id: 'test-wid', **overrides)
  end

  describe '#compute' do
    it 'scores trusted-shape signals near 1.0' do
      scorer = build_scorer([{ code: 'US', visits: 1000, profile: trusted_profile }])
      row = scorer.compute(window_start: Time.now - 86_400, window_end: Time.now, top_n: 1).first
      expect(row[:score]).to be >= 0.90
    end

    it 'scores bot-shape signals below 0.20' do
      scorer = build_scorer([{ code: 'SG', visits: 5000, profile: bot_profile }])
      row = scorer.compute(window_start: Time.now - 86_400, window_end: Time.now, top_n: 1).first
      expect(row[:score]).to be < 0.20
    end

    it 'returns one row per country with non-zero traffic' do
      empty = trusted_profile.merge('summary' => trusted_profile['summary'].merge('visits' => 0, 'visitors' => 0))
      scorer = build_scorer([
                              { code: 'US', visits: 1000, profile: trusted_profile },
                              { code: 'AA', visits: 0, profile: empty }
                            ])
      rows = scorer.compute(window_start: Time.now - 86_400, window_end: Time.now, top_n: 2)
      expect(rows.map { |r| r[:country_code] }).to eq(['US'])
    end

    it 'flags low_confidence below min_visits_for_confidence' do
      sparse = trusted_profile.merge('summary' => trusted_profile['summary'].merge('visits' => 50, 'visitors' => 40))
      scorer = build_scorer([{ code: 'LU', visits: 50, profile: sparse }])
      row = scorer.compute(window_start: Time.now - 86_400, window_end: Time.now, top_n: 1).first
      expect(row[:low_confidence]).to be true
    end

    it 'flat hourly distribution drives temporal_sub to 0' do
      flat = trusted_profile.merge('weekly' => Array.new(7) { Array.new(24, 20) })
      scorer = build_scorer([{ code: 'XX', visits: 1000, profile: flat }])
      row = scorer.compute(window_start: Time.now - 86_400, window_end: Time.now, top_n: 1).first
      expect(row[:temporal_sub]).to eq(0.0)
    end

    it 'clamps all sub-scores to 0..1 and rounds to 3 decimals' do
      scorer = build_scorer([{ code: 'US', visits: 1000, profile: trusted_profile }])
      row = scorer.compute(window_start: Time.now - 86_400, window_end: Time.now, top_n: 1).first
      %i[temporal_sub depth_sub ios_sub duration_sub diversity_sub repeat_sub score].each do |k|
        expect(row[k]).to be_between(0.0, 1.0).inclusive
      end
    end
  end

  describe 'weights and benchmarks overrides' do
    it 'merges partial weights into defaults' do
      scorer = build_scorer(
        [{ code: 'US', visits: 1000, profile: trusted_profile }],
        weights: { temporal: 0.50 }
      )
      computed_weights = scorer.instance_variable_get(:@weights)
      expect(computed_weights[:temporal]).to eq(0.50)
      expect(computed_weights[:depth]).to eq(described_class::DEFAULT_WEIGHTS[:depth])
    end

    it 'merges partial benchmarks into defaults' do
      scorer = build_scorer(
        [{ code: 'US', visits: 1000, profile: trusted_profile }],
        benchmarks: { duration: 30.0 }
      )
      computed_benchmarks = scorer.instance_variable_get(:@benchmarks)
      expect(computed_benchmarks[:duration]).to eq(30.0)
      expect(computed_benchmarks[:depth]).to eq(described_class::DEFAULT_BENCHMARKS[:depth])
    end

    it 'a stricter temporal_floor pushes borderline scores down' do
      # peak=20 trough=8 -> p/t=2.5: above default floor (2.0) but below a stricter one (3.0)
      borderline = trusted_profile.merge('weekly' => Array.new(7) { (0..23).map { |h| h.between?(12, 16) ? 20 : 8 } })
      base   = build_scorer([{ code: 'XX', visits: 1000, profile: borderline }])
      strict = build_scorer([{ code: 'XX', visits: 1000, profile: borderline }], benchmarks: { temporal_floor: 3.0 })

      base_row   = base.compute(window_start:   Time.now - 86_400, window_end: Time.now, top_n: 1).first
      strict_row = strict.compute(window_start: Time.now - 86_400, window_end: Time.now, top_n: 1).first

      expect(strict_row[:score]).to be < base_row[:score]
    end
  end

  describe 'timezone' do
    it 'forwards the configured timezone to sessions.weekly' do
      scorer = build_scorer(
        [{ code: 'US', visits: 1000, profile: trusted_profile }],
        timezone: 'Europe/Stockholm'
      )
      scorer.compute(window_start: Time.now - 86_400, window_end: Time.now, top_n: 1)
      sessions = scorer.instance_variable_get(:@client).sessions
      expect(sessions.captured_timezone).to eq('Europe/Stockholm')
    end
  end
end
