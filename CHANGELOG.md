# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- `UmamiClient::CountryTrust` — heuristic "legit traffic" scorer per country. Weighted composite of six sub-signals (temporal hourly pattern, pageview depth, iOS share, session duration, browser diversity, repeat-visit ratio). Configurable weights, benchmarks, confidence threshold, and timezone. See `docs/country-trust.md`.
- Initial gem structure
- Configuration system
- Error classes
- Basic Client class

### Fixed
- Railtie no longer registers a `rake_tasks` block that referenced an undefined `root` or a `generators` block that required non-existent files. Both were placeholders for unshipped features and blocked `bin/rails test` / `bin/rails generate` in host apps.
- `filters:` kwarg on GET-style endpoints (`Stats#summary`, `Stats#pageviews`, `Stats#metrics`, `Stats#events_series`, the filtered `Sessions#*` methods, and the filtered `EventData#*` methods) now flattens into the query string as top-level keys (e.g. `country=SG`) rather than nested `filters[country]=SG`, which Umami's API rejects silently.

## [0.1.0] - 2025-12-03

- Initial release
