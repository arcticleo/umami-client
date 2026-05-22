# frozen_string_literal: true

module UmamiClient
  # Composite "legit traffic" scorer for a website's country-level breakdowns.
  #
  # Pulls per-country signals over a window via the Stats and Sessions APIs,
  # derives six sub-scores (each clamped 0..1), and combines them into a single
  # composite score (also 0..1). Scores are heuristic, not ground truth — they
  # are useful for ranking and rough adjustment, not for SLA reporting.
  #
  # Signals (and why each one matters):
  #   - temporal:  ratio of peak hour to trough hour over a 24h cycle. Real
  #                humans cluster around waking hours; bots run flat across all
  #                24 hours. The most discriminating single signal.
  #   - depth:     pageviews per visit. Humans browse; bots hit one URL.
  #   - ios:       iOS share specifically (not "mobile"). Bots almost never
  #                spoof iOS even when they fake desktop UAs.
  #   - duration:  seconds per visit. Easily skewed by outliers, so weighted
  #                modestly.
  #   - diversity: 1 - share of the top browser. Bots cluster in one UA.
  #   - repeat:    visits per visitor. Bots either flood (>2.5) or look one-off.
  #
  # Defaults are tuned against luxury-real-estate traffic. Override via the
  # `weights:` and `benchmarks:` kwargs as needed. Partial overrides merge into
  # the defaults — you don't need to redeclare every key.
  #
  # @example
  #   client = UmamiClient.new
  #   scorer = UmamiClient::CountryTrust.new(client: client, website_id: "abc-123")
  #   rows   = scorer.compute(window_start: 30.days.ago, window_end: Time.now, top_n: 30)
  #   rows.each { |r| puts "#{r[:country_code]} #{r[:score]}" }
  class CountryTrust
    DEFAULT_WEIGHTS = {
      temporal: 0.35,
      depth: 0.20,
      ios: 0.20,
      duration: 0.10,
      diversity: 0.10,
      repeat: 0.05
    }.freeze

    DEFAULT_BENCHMARKS = {
      duration: 120.0, # seconds per visit (unhurried browsing)
      depth: 5.0, # pageviews per visit
      ios: 0.15, # iOS share
      diversity: 0.40, # share of non-top browser
      repeat_max: 2.5, # visits/visitor above this trends bot-like
      repeat_range: 1.5,
      temporal_floor: 2.0, # peak/trough ratios at or below this = flat = bots
      temporal_range: 2.0  # ceiling: floor + range = 4.0 -> score 1.0
    }.freeze

    DEFAULT_MIN_VISITS_FOR_CONFIDENCE = 100
    DEFAULT_TIMEZONE = 'America/New_York'

    def initialize(client:, website_id:,
                   weights: {},
                   benchmarks: {},
                   min_visits_for_confidence: DEFAULT_MIN_VISITS_FOR_CONFIDENCE,
                   timezone: DEFAULT_TIMEZONE)
      @client = client
      @website_id = website_id
      @weights = DEFAULT_WEIGHTS.merge(weights)
      @benchmarks = DEFAULT_BENCHMARKS.merge(benchmarks)
      @min_visits_for_confidence = min_visits_for_confidence
      @timezone = timezone
    end

    # Returns an Array of Hashes ready to persist or display, one per country with
    # non-zero traffic in the window. Each row contains the composite score, the
    # six sub-scores, the raw signal values, and a low_confidence flag for
    # countries with fewer than min_visits_for_confidence visits.
    def compute(window_start:, window_end:, top_n: 30)
      countries = top_countries(window_start, window_end, top_n)

      countries.filter_map do |country_code|
        signals = collect_signals(country_code, window_start, window_end)
        next nil if signals.nil?

        score_attrs(country_code, signals, window_start, window_end)
      end
    end

    private

    attr_reader :client, :website_id, :weights, :benchmarks,
                :min_visits_for_confidence, :timezone

    def top_countries(window_start, window_end, limit)
      client.stats.metrics(website_id, window_start, window_end, 'country', limit: limit)
            .body.map { |row| row['x'] }
    end

    def collect_signals(country_code, window_start, window_end)
      summary = client.stats.summary(
        website_id, window_start, window_end,
        filters: { country: country_code }
      ).body
      visits   = summary['visits'].to_i
      visitors = summary['visitors'].to_i
      return nil if visits.zero? || visitors.zero?

      pageviews = summary['pageviews'].to_i
      totaltime = summary['totaltime'].to_i

      {
        visits: visits,
        visitors: visitors,
        sec_per_visit: totaltime.to_f / visits,
        pv_per_visit: pageviews.to_f / visits,
        visits_per_visitor: visits.to_f / visitors,
        ios_share: os_share(country_code, window_start, window_end, 'iOS'),
        top_browser_share: top_share(country_code, window_start, window_end, 'browser'),
        peak_trough_ratio: peak_trough_ratio(country_code, window_start, window_end)
      }
    end

    def os_share(country_code, window_start, window_end, os_name)
      rows = client.stats.metrics(
        website_id, window_start, window_end, 'os',
        filters: { country: country_code }, limit: 10
      ).body
      total = rows.sum { |r| r['y'].to_i }.to_f
      return 0.0 if total.zero?

      match = rows.find { |r| r['x'] == os_name }
      match ? match['y'].to_i / total : 0.0
    end

    def top_share(country_code, window_start, window_end, type)
      rows = client.stats.metrics(
        website_id, window_start, window_end, type,
        filters: { country: country_code }, limit: 10
      ).body
      total = rows.sum { |r| r['y'].to_i }.to_f
      return 0.0 if total.zero?

      rows.first['y'].to_i / total
    end

    # Collapses the 7x24 weekly matrix into a 24-element hour profile, then
    # returns max_hour / max(min_hour, 1). Higher = more diurnal = more human.
    def peak_trough_ratio(country_code, window_start, window_end)
      weekly = client.sessions.weekly(
        website_id, window_start, window_end,
        timezone: timezone, filters: { country: country_code }
      ).body
      return 1.0 unless weekly.is_a?(Array) && weekly.any?

      by_hour = Array.new(24, 0)
      weekly.each do |day|
        next unless day.is_a?(Array)

        day.each_with_index { |v, h| by_hour[h] += v.to_i if h < 24 }
      end
      return 1.0 if by_hour.sum.zero?

      peak   = by_hour.max
      trough = [by_hour.min, 1].max
      peak.to_f / trough
    end

    def score_attrs(country_code, signals, window_start, window_end)
      subs = {
        temporal: clamp((signals[:peak_trough_ratio] - benchmarks[:temporal_floor]) / benchmarks[:temporal_range]),
        depth: clamp(signals[:pv_per_visit] / benchmarks[:depth]),
        ios: clamp(signals[:ios_share] / benchmarks[:ios]),
        duration: clamp(signals[:sec_per_visit] / benchmarks[:duration]),
        diversity: clamp((1.0 - signals[:top_browser_share]) / benchmarks[:diversity]),
        repeat: clamp((benchmarks[:repeat_max] - signals[:visits_per_visitor]) / benchmarks[:repeat_range])
      }
      total = weights.sum { |k, w| w * subs[k] }

      {
        country_code: country_code,
        score: total.round(3),
        temporal_sub: subs[:temporal].round(3),
        depth_sub: subs[:depth].round(3),
        ios_sub: subs[:ios].round(3),
        duration_sub: subs[:duration].round(3),
        diversity_sub: subs[:diversity].round(3),
        repeat_sub: subs[:repeat].round(3),
        visits: signals[:visits],
        visitors: signals[:visitors],
        sec_per_visit: signals[:sec_per_visit].round(2),
        pv_per_visit: signals[:pv_per_visit].round(2),
        visits_per_visitor: signals[:visits_per_visitor].round(2),
        ios_share: signals[:ios_share].round(3),
        top_browser_share: signals[:top_browser_share].round(3),
        peak_trough_ratio: signals[:peak_trough_ratio].round(2),
        low_confidence: signals[:visits] < min_visits_for_confidence,
        window_start: window_start,
        window_end: window_end
      }
    end

    def clamp(value)
      return 0.0 if value.nil? || (value.respond_to?(:nan?) && value.nan?)

      [[value, 0.0].max, 1.0].min
    end
  end
end
