# Country Trust Scoring

`UmamiClient::CountryTrust` computes a heuristic "legit traffic" score (0.000–1.000) per country for a given website and date window. Higher = more human-like, lower = bot-suspicious. Useful for ranking traffic sources and adjusting visitor counts for UA-spoofing scrapers.

Scores are heuristic, not ground truth. Use them for relative ranking and rough adjustment, not for SLA reporting.

## Basic Usage

```ruby
client = UmamiClient.new
scorer = UmamiClient::CountryTrust.new(client: client, website_id: "your-website-id")

rows = scorer.compute(
  window_start: Time.now - 30 * 86400,
  window_end:   Time.now,
  top_n:        30
)

rows.each do |row|
  puts "#{row[:country_code]}: #{row[:score]}"
end
```

Each row in the returned array includes the composite `score`, six sub-scores, the raw signals used to compute them, and a `low_confidence` flag for countries below the visit threshold.

## Signals

The composite score is a weighted average of six sub-scores, each clamped to 0..1:

| Sub-score | What it measures | Bot signature |
|---|---|---|
| `temporal_sub` | Peak-hour traffic / trough-hour traffic over 24h | Flat distribution (ratio ≤ 2.0) |
| `depth_sub` | Pageviews per visit | Single-page hits |
| `ios_sub` | Share of iOS users | Near-zero iOS (bots rarely spoof iOS) |
| `duration_sub` | Seconds per visit | Sub-second sessions |
| `diversity_sub` | 1 − top browser share | 99%+ one browser |
| `repeat_sub` | Visits per visitor (inverted) | High revisit count |

The `temporal` signal is the most discriminating — humans browse during waking hours, automated traffic runs flat across all 24. The `ios` signal is the next sharpest because UA-spoofing scrapers almost always fake desktop, not mobile.

## Default Weights and Benchmarks

```ruby
DEFAULT_WEIGHTS = {
  temporal:  0.35,
  depth:     0.20,
  ios:       0.20,
  duration:  0.10,
  diversity: 0.10,
  repeat:    0.05
}

DEFAULT_BENCHMARKS = {
  duration:       120.0, # seconds per visit
  depth:            5.0, # pageviews per visit
  ios:              0.15, # iOS share threshold
  diversity:        0.40, # share of non-top browser
  repeat_max:       2.5,  # visits/visitor above this trends bot-like
  repeat_range:     1.5,
  temporal_floor:   2.0, # peak/trough at or below this = flat = bots
  temporal_range:   2.0  # ceiling: floor + range = 4.0 → score 1.0
}
```

Defaults are tuned against luxury-real-estate traffic. They generalize reasonably to most content sites, but you can override per-instance.

## Custom Weights and Benchmarks

Partial overrides merge into the defaults — you only need to declare the keys you want to change.

```ruby
# Penalize flat hourly patterns harder
scorer = UmamiClient::CountryTrust.new(
  client: client,
  website_id: "your-website-id",
  benchmarks: { temporal_floor: 3.0 }
)

# Different traffic profile — weight engagement signals higher
scorer = UmamiClient::CountryTrust.new(
  client: client,
  website_id: "your-website-id",
  weights:    { depth: 0.30, duration: 0.20, temporal: 0.20 },
  benchmarks: { duration: 60.0 }
)
```

## Confidence Threshold

Countries with fewer than `min_visits_for_confidence` visits in the window (default 100) get `low_confidence: true` in the returned row. Their scores are still computed but should be treated as noisy.

```ruby
scorer = UmamiClient::CountryTrust.new(
  client: client,
  website_id: "your-website-id",
  min_visits_for_confidence: 500
)
```

## Timezone

The `temporal` signal depends on bucketing traffic by hour-of-day, which requires a timezone. Default is `"America/New_York"`. Override if your audience is regional:

```ruby
scorer = UmamiClient::CountryTrust.new(
  client: client,
  website_id: "your-website-id",
  timezone: "Europe/Stockholm"
)
```

## Returned Fields

Each row in the result:

| Field | Type | Description |
|---|---|---|
| `country_code` | String | ISO 3166-1 alpha-2, e.g. `"US"` |
| `score` | Float | Composite 0.000-1.000 |
| `temporal_sub` … `repeat_sub` | Float | Six individual sub-scores |
| `visits` | Integer | Raw visit count in the window |
| `visitors` | Integer | Raw unique visitor count |
| `sec_per_visit` | Float | Average session duration in seconds |
| `pv_per_visit` | Float | Pageviews per visit |
| `visits_per_visitor` | Float | Repeat-visit ratio |
| `ios_share` | Float | Fraction of OS metrics that are iOS |
| `top_browser_share` | Float | Fraction of pageviews from the single most-used browser |
| `peak_trough_ratio` | Float | Hour-of-day max / max(hour-of-day min, 1) |
| `low_confidence` | Boolean | True if `visits < min_visits_for_confidence` |
| `window_start`, `window_end` | Time | Echoed from the `compute` call |

## API Calls per Country

Each row requires four queries against the Umami API:

1. `stats.summary` (filtered by country)
2. `stats.metrics(type: "os")` (filtered by country, for iOS share)
3. `stats.metrics(type: "browser")` (filtered by country, for diversity)
4. `sessions.weekly` (filtered by country, for temporal pattern)

Plus one initial `stats.metrics(type: "country")` to enumerate the top N. So scoring 30 countries is ~121 API calls. Each is fast (~100ms), but consider caching the result rather than running it per request — a daily refresh is usually plenty.
