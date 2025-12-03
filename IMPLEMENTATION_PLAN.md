# Umami Ruby Client - Implementation Plan

## Executive Summary

This plan outlines the development of `umami-client`, a Ruby gem for interacting with Umami Analytics. The gem will provide a pure Ruby HTTP client (no JavaScript wrapping needed) inspired by the `umami-python` project, enabling Ruby/Rails applications to:

- Track custom events and page views server-side
- Retrieve analytics data (pageviews, visitors, metrics)
- Manage websites, users, and teams
- Support both Umami Cloud and self-hosted instances

**Architecture Decision**: After analyzing Umami's architecture, we've determined that **mini_racer is NOT needed**. Umami provides a comprehensive REST API that can be accessed directly via HTTP. The JavaScript tracker is designed for browser environments and uses browser-specific APIs (`window`, `document`, `navigator`) that aren't applicable to server-side tracking. The Python client successfully uses direct HTTP calls, and our Ruby gem will follow the same approach.

---

## Phase 1: Project Foundation & Setup

### Goals
- Establish gem structure following Ruby best practices
- Set up development tooling (RuboCop, YARD, testing)
- Create basic project documentation
- Implement configuration system

### Tasks

#### 1.1: Initialize Gem Structure
- [ ] Run `bundle gem umami-client` to create standard gem structure
- [ ] Configure `umami-client.gemspec` with proper metadata:
  - Author, email, homepage
  - Description and summary
  - Required Ruby version (>= 3.0)
  - Dependencies: `faraday` (~> 2.0), `faraday-multipart` (~> 1.0)
  - Development dependencies: `minitest`, `rubocop`, `yard`, `webmock`, `vcr`
- [ ] Set up directory structure:
  ```
  lib/
    umami/
      client/
      models/
      errors.rb
      configuration.rb
      version.rb
    umami.rb
  test/
    fixtures/
    test_helper.rb
  ```
- [ ] Create `.rubocop.yml` with appropriate style rules
- [ ] Configure `.yardopts` for documentation generation

#### 1.2: Development Environment Setup
- [ ] Create `Rakefile` with tasks:
  - `rake test` - Run test suite
  - `rake rubocop` - Run linter
  - `rake yard` - Generate documentation
  - `rake build` - Build gem
- [ ] Set up GitHub Actions (or similar CI) workflow:
  - Run tests on multiple Ruby versions (3.0, 3.1, 3.2, 3.3)
  - Run RuboCop checks
  - Generate coverage reports
- [ ] Create `.env.example` for configuration examples
- [ ] Add `.gitignore` entries for common Ruby patterns

#### 1.3: Core Configuration System
- [ ] Implement `Umami::Configuration` class with:
  - `base_url` - Umami instance URL
  - `api_key` - For Umami Cloud authentication
  - `website_id` - Default website ID for tracking
  - `default_hostname` - Default hostname for events
  - `timeout` - HTTP request timeout
  - `logger` - Logger instance for debugging
  - `user_agent` - Custom User-Agent string
  - `disabled` - Flag to disable tracking (for testing)
- [ ] Implement module-level configuration:
  ```ruby
  Umami.configure do |config|
    config.base_url = "https://analytics.example.com"
    config.website_id = "xxx-xxx-xxx"
  end
  ```
- [ ] Add YARD documentation for all configuration options
- [ ] Write tests for configuration system

#### 1.4: Error Handling Foundation
- [ ] Create `Umami::Error` base class
- [ ] Define specific error classes:
  - `ConfigurationError` - Invalid configuration
  - `AuthenticationError` - Authentication failures
  - `ValidationError` - Invalid parameters
  - `APIError` - General API errors
  - `NetworkError` - Connection issues
  - `RateLimitError` - Rate limiting
- [ ] Add YARD documentation for all error classes

**Deliverables**:
- Working gem skeleton with proper structure
- Passing RuboCop checks
- Configuration system with tests
- Complete YARD documentation for foundation classes
- CI pipeline running successfully

**Definition of Done**:
- `rake test` passes with 100% coverage for Phase 1 code
- `rake rubocop` passes with no offenses
- `rake yard` generates documentation without warnings
- All Phase 1 classes have complete YARD documentation

---

## Phase 2: HTTP Client & Authentication

### Goals
- Implement HTTP client wrapper using Faraday
- Add authentication for self-hosted and cloud instances
- Create request/response handling
- Implement retry logic and error handling

### Tasks

#### 2.1: HTTP Client Implementation
- [ ] Create `Umami::Client::HTTPClient` class
- [ ] Configure Faraday with:
  - JSON request/response middleware
  - Timeout configuration
  - User-Agent header (required by Umami)
  - Error handling middleware
  - Logging middleware (optional, based on config)
- [ ] Implement base HTTP methods:
  - `get(path, params = {})`
  - `post(path, body = {})`
  - `put(path, body = {})`
  - `delete(path, params = {})`
- [ ] Add automatic JSON parsing of responses
- [ ] Implement proper error handling with custom exceptions
- [ ] Add request/response logging for debugging
- [ ] Write comprehensive tests using WebMock
- [ ] Add YARD documentation for all methods

#### 2.2: Authentication System
- [x] ~~Create `Umami::Client::Auth` class~~ Implemented in `Connection` class
- [x] Implement self-hosted authentication:
  - `POST /api/auth/login` endpoint
  - Token storage and management
  - Automatic token inclusion in requests via `Authorization: Bearer <token>` header
  - ~~Token verification via `POST /api/auth/verify`~~ (deferred - not needed for basic functionality)
- [x] Implement Umami Cloud authentication:
  - API key configuration via `config.api_key`
  - Proper header formatting for cloud requests (`x-umami-api-key`)
- [x] Add token caching mechanism (in-memory via `@bearer_token`)
- [ ] Implement automatic re-authentication on 401 errors
- [x] Handle authentication errors gracefully
- [ ] Write tests for both auth methods using VCR for HTTP fixtures
- [x] Add YARD documentation for authentication flow

**Note**: Both authentication methods are now supported. The client automatically detects which method to use based on provided credentials (api_key vs username/password).

#### 2.3: Response Handling
- [ ] Create `Umami::Models::Response` wrapper class
- [ ] Implement response parsing:
  - Success responses (2xx)
  - Error responses (4xx, 5xx)
  - Extract error messages from response body
- [ ] Add response validation
- [ ] Implement pagination support (for list endpoints)
- [ ] Write tests for various response scenarios
- [ ] Add YARD documentation

#### 2.4: Retry Logic & Resilience
- [ ] Implement exponential backoff for retries
- [ ] Configure retry for:
  - Network errors
  - 5xx server errors
  - Rate limiting (429)
- [ ] Add configurable retry options:
  - `max_retries` (default: 3)
  - `retry_delay` (default: 1 second)
- [ ] Respect `Retry-After` header when present
- [ ] Write tests for retry scenarios
- [ ] Add YARD documentation

**Deliverables**:
- Fully functional HTTP client with authentication
- Comprehensive test suite with fixtures
- Complete YARD documentation
- Working authentication for both self-hosted and cloud

**Definition of Done**:
- All tests pass with 100% coverage
- RuboCop checks pass
- Can successfully authenticate with test Umami instance
- All public methods have YARD documentation
- Error handling covers all edge cases

---

## Phase 3: Event Tracking API

### Goals
- Implement server-side event tracking
- Support page views and custom events
- Add session identification
- Implement disabled mode for testing

### Tasks

#### 3.1: Event Tracking Core
- [ ] Create `Umami::Client::Events` class
- [ ] Implement `POST /api/send` endpoint wrapper
- [ ] Create `track_event` method:
  ```ruby
  def track_event(
    event_name,
    website_id: nil,
    hostname: nil,
    url: nil,
    referrer: nil,
    title: nil,
    data: {}
  )
  ```
- [ ] Generate required payload fields:
  - `website` - Website ID (from param or config)
  - `hostname` - Domain name (from param or config)
  - `url` - Page URL
  - `name` - Event name
  - `data` - Custom event properties (optional)
  - `type` - "event"
- [ ] Add automatic User-Agent header (required by Umami)
- [ ] Handle response: return `cache`, `sessionId`, `visitId`
- [ ] Validate event data constraints:
  - Numbers: max 4 decimal precision
  - Strings: 500 char limit
  - Arrays: convert to strings (500 char max)
  - Objects: 50 property max
- [ ] Write comprehensive tests
- [ ] Add YARD documentation with examples

#### 3.2: Page View Tracking
- [ ] Create `track_pageview` method:
  ```ruby
  def track_pageview(
    url,
    website_id: nil,
    hostname: nil,
    referrer: nil,
    title: nil,
    screen: nil,
    language: nil
  )
  ```
- [ ] Generate page view payload with:
  - All URL/page metadata
  - Browser-like fields (screen, language) if provided
  - Session tracking
- [ ] Add convenience method for Rails integration:
  ```ruby
  def track_request(request, title: nil, data: {})
  ```
  That extracts URL, referrer, user agent from Rack request
- [ ] Write tests including Rails request simulation
- [ ] Add YARD documentation

#### 3.3: Session Identification
- [ ] Implement `identify` method:
  ```ruby
  def identify(
    unique_id,
    data: {},
    website_id: nil
  )
  ```
- [ ] Associate unique ID with session
- [ ] Attach custom data to session
- [ ] Handle ID persistence across requests
- [ ] Write tests for identification
- [ ] Add YARD documentation

#### 3.4: Disabled Mode for Testing
- [ ] Implement disabled mode that:
  - Skips HTTP requests when `Umami.configuration.disabled = true`
  - Still validates all parameters
  - Returns mock responses with proper structure
  - Logs what would have been tracked (if logger configured)
- [ ] Add convenience methods:
  ```ruby
  Umami.disable!
  Umami.enable!
  Umami.disabled?
  ```
- [ ] Create test helper for RSpec/Minitest:
  ```ruby
  # test/test_helper.rb
  Umami.disable!

  # spec/spec_helper.rb
  RSpec.configure do |config|
    config.before(:suite) { Umami.disable! }
  end
  ```
- [ ] Write tests verifying no HTTP calls when disabled
- [ ] Add YARD documentation

#### 3.5: Batch Event Tracking (Nice to Have)
- [ ] Implement `track_events` for batch tracking:
  ```ruby
  def track_events(events)
  ```
- [ ] Queue events and send in batch
- [ ] Handle partial failures
- [ ] Write tests
- [ ] Add YARD documentation

**Deliverables**:
- Full event tracking capability
- Rails integration helpers
- Disabled mode for testing
- Comprehensive test suite
- Complete YARD documentation

**Definition of Done**:
- All tests pass with 100% coverage
- RuboCop checks pass
- Can track events to test Umami instance
- Disabled mode works correctly in tests
- All public methods have YARD documentation with examples
- Rails integration tested with request mocks

---

## Phase 4: Analytics Retrieval API

### Goals
- Retrieve website statistics
- Access real-time data
- Query metrics and events
- Support filtering and date ranges

### Tasks

#### 4.1: Website Management
- [ ] Create `Umami::Client::Websites` class
- [ ] Implement endpoints:
  - `GET /api/websites` - List all websites
  - `GET /api/websites/:id` - Get website details
  - `POST /api/websites` - Create website
  - `PUT /api/websites/:id` - Update website
  - `DELETE /api/websites/:id` - Delete website
- [ ] Create `Umami::Models::Website` model with attributes:
  - `id`, `name`, `domain`, `shareId`, `createdAt`
- [ ] Write tests for all endpoints
- [ ] Add YARD documentation

#### 4.2: Website Statistics
- [ ] Create `Umami::Client::Stats` class
- [ ] Implement statistics endpoints:
  - `GET /api/websites/:websiteId/stats` - Summary statistics
  - `GET /api/websites/:websiteId/pageviews` - Pageview time series
  - `GET /api/websites/:websiteId/metrics` - Aggregated metrics
  - `GET /api/websites/:websiteId/metrics/expanded` - Expanded metrics
  - `GET /api/websites/:websiteId/events/series` - Event time series
- [ ] Support query parameters:
  - `startAt` / `endAt` - Date range (timestamps in ms)
  - `unit` - Time unit (minute, hour, day, month, year)
  - `timezone` - Timezone for data
  - `url` - Filter by URL
  - `referrer` - Filter by referrer
  - `country` - Filter by country
  - `device` - Filter by device type
  - `browser` - Filter by browser
  - `os` - Filter by OS
- [ ] Create model classes for responses:
  - `Umami::Models::Stats` - Summary stats
  - `Umami::Models::Pageviews` - Time series data
  - `Umami::Models::Metric` - Metric data
- [ ] Add convenience methods for common queries:
  ```ruby
  def today_stats(website_id)
  def yesterday_stats(website_id)
  def last_7_days(website_id)
  def last_30_days(website_id)
  ```
- [ ] Write comprehensive tests
- [ ] Add YARD documentation with examples

#### 4.3: Real-time Data
- [ ] Implement real-time endpoint:
  - `GET /api/websites/:websiteId/active` - Active users
- [ ] Create `Umami::Models::ActiveUsers` model
- [ ] Add convenience method:
  ```ruby
  def active_users(website_id)
  ```
- [ ] Write tests
- [ ] Add YARD documentation

#### 4.4: Event Queries
- [ ] Create `Umami::Client::EventData` class
- [ ] Implement event data retrieval (if available in API)
- [ ] Support filtering and pagination
- [ ] Create appropriate model classes
- [ ] Write tests
- [ ] Add YARD documentation

#### 4.5: Reports (Advanced)
- [ ] Implement reports endpoints if available:
  - Funnel reports
  - Journey reports
  - Retention reports
  - Goal reports
- [ ] Create model classes for each report type
- [ ] Write tests
- [ ] Add YARD documentation

**Deliverables**:
- Complete analytics retrieval API
- Model classes for all response types
- Convenience methods for common queries
- Comprehensive test suite
- Complete YARD documentation

**Definition of Done**:
- All tests pass with 100% coverage
- RuboCop checks pass
- Can retrieve analytics from test Umami instance
- All public methods have YARD documentation with examples
- Model classes properly parse all response fields

---

## Phase 5: Advanced Features & Management APIs

### Goals
- Implement user management
- Add team management
- Support session queries
- Implement administrative functions

### Tasks

#### 5.1: User Management
- [ ] Create `Umami::Client::Users` class
- [ ] Implement endpoints:
  - `GET /api/users` - List users
  - `GET /api/users/:id` - Get user
  - `POST /api/users` - Create user
  - `PUT /api/users/:id` - Update user
  - `DELETE /api/users/:id` - Delete user
  - `GET /api/me` - Current user info
- [ ] Create `Umami::Models::User` model
- [ ] Write tests
- [ ] Add YARD documentation

#### 5.2: Team Management
- [ ] Create `Umami::Client::Teams` class
- [ ] Implement endpoints:
  - `GET /api/teams` - List teams
  - `GET /api/teams/:id` - Get team
  - `POST /api/teams` - Create team
  - `PUT /api/teams/:id` - Update team
  - `DELETE /api/teams/:id` - Delete team
  - Team member management
- [ ] Create `Umami::Models::Team` model
- [ ] Write tests
- [ ] Add YARD documentation

#### 5.3: Session Management
- [ ] Create `Umami::Client::Sessions` class
- [ ] Implement session queries:
  - `GET /api/websites/:websiteId/sessions` - List sessions
  - `GET /api/sessions/:id` - Session details
  - Session filtering and pagination
- [ ] Create `Umami::Models::Session` model
- [ ] Write tests
- [ ] Add YARD documentation

#### 5.4: Links & Pixels (If Available)
- [ ] Create `Umami::Client::Links` class for link tracking
- [ ] Create `Umami::Client::Pixels` class for pixel tracking
- [ ] Implement relevant endpoints
- [ ] Create model classes
- [ ] Write tests
- [ ] Add YARD documentation

#### 5.5: Admin Functions
- [ ] Create `Umami::Client::Admin` class
- [ ] Implement admin-only endpoints
- [ ] Add proper permission checking
- [ ] Write tests
- [ ] Add YARD documentation

**Deliverables**:
- Complete management API coverage
- All model classes for responses
- Comprehensive test suite
- Complete YARD documentation

**Definition of Done**:
- All tests pass with 100% coverage
- RuboCop checks pass
- All management operations work on test instance
- All public methods have YARD documentation
- Proper error handling for permission issues

---

## Phase 6: Rails Integration & Middleware

### Goals
- Create Rails integration gem/plugin
- Implement Rack middleware for automatic tracking
- Add Rails generators
- Create view helpers

### Tasks

#### 6.1: Rails Integration Setup
- [ ] Create `lib/umami/rails.rb` for Rails-specific code
- [ ] Create Railtie for automatic configuration
- [ ] Add engine for mounting if needed
- [ ] Set up Rails generators structure

#### 6.2: Rack Middleware
- [ ] Create `Umami::Middleware::Tracker` Rack middleware:
  ```ruby
  class Tracker
    def initialize(app, options = {})
    def call(env)
  end
  ```
- [ ] Implement automatic page view tracking:
  - Extract URL, referrer, user agent from request
  - Track page view on each request
  - Handle exceptions gracefully
  - Skip tracking for assets, health checks
- [ ] Add configuration options:
  - `skip_paths` - Paths to skip (regex/array)
  - `skip_assets` - Skip asset requests (default: true)
  - `async` - Async tracking (default: true)
  - `before_track` - Callback hook
  - `after_track` - Callback hook
- [ ] Implement async tracking (background job):
  - Queue tracking to avoid blocking requests
  - Support ActiveJob or inline execution
- [ ] Write tests for middleware
- [ ] Add YARD documentation

#### 6.3: Rails Generators
- [ ] Create `rails generate umami:install` generator:
  - Generate `config/initializers/umami.rb`
  - Add configuration template with comments
  - Add middleware to application.rb (optional)
- [ ] Create `rails generate umami:config` generator:
  - Interactive configuration setup
  - Validate Umami connection
  - Test event tracking
- [ ] Write tests for generators
- [ ] Add YARD documentation

#### 6.4: View Helpers
- [ ] Create `Umami::Rails::Helpers` module:
  ```ruby
  def umami_script_tag(website_id = nil, **options)
  def umami_track_event(event_name, data = {})
  def umami_identify(user_id, data = {})
  ```
- [ ] Generate JavaScript tracker snippet
- [ ] Add data attributes for auto-tracking
- [ ] Support server-side tracking fallback
- [ ] Write tests for helpers
- [ ] Add YARD documentation

#### 6.5: Controller Concerns
- [ ] Create `Umami::Rails::Trackable` concern:
  ```ruby
  module Trackable
    extend ActiveSupport::Concern

    included do
      after_action :track_page_view
    end

    def track_event(name, data = {})
    def track_page_view
  end
  ```
- [ ] Add DSL for tracking configuration:
  ```ruby
  class ArticlesController < ApplicationController
    include Umami::Rails::Trackable

    track_events only: [:show, :index]
    track_event :article_view, on: :show
  end
  ```
- [ ] Write tests for concern
- [ ] Add YARD documentation

#### 6.6: Background Job Integration
- [ ] Create `Umami::TrackEventJob` ActiveJob:
  ```ruby
  class TrackEventJob < ApplicationJob
    def perform(event_name, data = {})
  end
  ```
- [ ] Support ActiveJob
- [ ] Add retry logic
- [ ] Write tests
- [ ] Add YARD documentation

**Deliverables**:
- Full Rails integration
- Rack middleware for automatic tracking
- Rails generators for easy setup
- View helpers and controller concerns
- Background job support
- Comprehensive test suite
- Complete YARD documentation

**Definition of Done**:
- All tests pass with 100% coverage
- RuboCop checks pass
- Generators work correctly in test Rails app
- Middleware tracks requests properly
- Helpers generate correct HTML/JavaScript
- All public APIs have YARD documentation
- Example Rails app demonstrates integration

---

## Phase 7: Documentation & Examples

### Goals
- Create comprehensive README
- Write usage guides
- Build example applications
- Generate API documentation

### Tasks

#### 7.1: README & Getting Started
- [ ] Write comprehensive README.md:
  - Project description
  - Installation instructions
  - Quick start guide
  - Basic usage examples
  - Configuration options
  - Rails integration guide
  - Links to full documentation
  - Contributing guidelines
  - License information
- [ ] Create CHANGELOG.md
- [ ] Create CONTRIBUTING.md
- [ ] Create CODE_OF_CONDUCT.md
- [ ] Add badges (build status, gem version, coverage)

#### 7.2: Usage Guides
- [ ] Create `docs/` directory with guides:
  - `01-installation.md` - Installation and setup
  - `02-configuration.md` - Configuration options
  - `03-authentication.md` - Authentication guide
  - `04-tracking-events.md` - Event tracking guide
  - `05-retrieving-stats.md` - Analytics retrieval
  - `06-rails-integration.md` - Rails integration guide
  - `07-testing.md` - Testing with Umami client
  - `08-advanced.md` - Advanced usage patterns
  - `09-api-reference.md` - Complete API reference
- [ ] Add code examples to each guide
- [ ] Create troubleshooting section
- [ ] Add FAQ

#### 7.3: Example Applications
- [ ] Create `examples/` directory with:
  - `simple_ruby/` - Plain Ruby example
  - `rails_app/` - Complete Rails integration example
  - `sinatra_app/` - Sinatra integration example
  - `active_job_integration/` - Background job example
- [ ] Document each example in its own README
- [ ] Ensure examples run successfully
- [ ] Add to CI to verify examples stay working

#### 7.4: API Documentation
- [ ] Run `yard doc` to generate full API documentation
- [ ] Review all YARD docs for completeness
- [ ] Add examples to all public methods
- [ ] Fix any YARD warnings
- [ ] Publish docs to GitHub Pages or RubyDoc.info
- [ ] Add link to README

#### 7.5: Video & Visual Documentation
- [ ] Create architecture diagram
- [ ] Create flow diagrams for:
  - Authentication flow
  - Event tracking flow
  - Rails middleware flow
- [ ] Add diagrams to relevant docs
- [ ] Consider creating video tutorial (optional)

**Deliverables**:
- Comprehensive documentation
- Multiple example applications
- Published API documentation
- Visual diagrams
- Contributing guidelines

**Definition of Done**:
- README is clear and complete
- All guides are written with examples
- Example applications run successfully
- YARD documentation is 100% complete
- All links work correctly
- Documentation is published online

---

## Phase 8: Testing, Polish & Release

### Goals
- Achieve 100% test coverage
- Performance testing and optimization
- Security audit
- Prepare for release

### Tasks

#### 8.1: Test Coverage & Quality
- [ ] Review test coverage report
- [ ] Add missing tests to reach 100% coverage
- [ ] Add integration tests with real Umami instance
- [ ] Add performance benchmarks
- [ ] Test on multiple Ruby versions (3.0, 3.1, 3.2, 3.3)
- [ ] Test on multiple platforms (Linux, macOS, Windows)
- [ ] Fix any flaky tests
- [ ] Ensure all tests pass consistently

#### 8.2: Performance Optimization
- [ ] Profile gem performance
- [ ] Optimize HTTP client configuration
- [ ] Implement connection pooling if needed
- [ ] Add caching where appropriate
- [ ] Benchmark against umami-python for reference
- [ ] Document performance characteristics

#### 8.3: Security Review
- [ ] Review authentication implementation
- [ ] Audit token storage and handling
- [ ] Check for injection vulnerabilities
- [ ] Review error messages (no sensitive data leaks)
- [ ] Validate input sanitization
- [ ] Run Bundler Audit for dependency issues
- [ ] Consider security scanning tools (Brakeman, etc.)

#### 8.4: Code Quality & Polish
- [ ] Run RuboCop and fix all offenses
- [ ] Review all public APIs for consistency
- [ ] Ensure consistent naming conventions
- [ ] Add deprecation warnings if needed
- [ ] Review and improve error messages
- [ ] Add helpful debug logging
- [ ] Clean up any TODO comments

#### 8.5: Versioning & Changelog
- [ ] Choose version number (suggest 0.1.0 for initial release)
- [ ] Update version in `lib/umami/version.rb`
- [ ] Update CHANGELOG.md with all changes
- [ ] Tag release in git
- [ ] Create GitHub release with notes

#### 8.6: Gem Publishing
- [ ] Update gemspec with final details
- [ ] Build gem: `gem build umami-client.gemspec`
- [ ] Test gem installation locally
- [ ] Push to RubyGems.org: `gem push umami-client-1.0.0.gem`
- [ ] Verify gem page on RubyGems.org
- [ ] Test installation from RubyGems

#### 8.7: Post-Release
- [ ] Announce on social media/forums
- [ ] Submit to Ruby Weekly
- [ ] Add to Awesome Ruby lists
- [ ] Monitor for issues/bug reports
- [ ] Plan next version features

**Deliverables**:
- Production-ready gem
- 100% test coverage
- Published on RubyGems.org
- Release announcement
- Bug tracking system ready

**Definition of Done**:
- All tests pass on all supported Ruby versions
- 100% test coverage achieved
- RuboCop passes with no offenses
- Security review complete with no issues
- Gem successfully published to RubyGems.org
- Documentation is live and accessible
- GitHub release created
- Initial users can install and use gem successfully

---

## Architecture Overview

### Technology Stack

**Core Dependencies:**
- **Faraday** (~> 2.0) - HTTP client with middleware support
- **Faraday-Multipart** (~> 1.0) - Multipart form support if needed

**Development Dependencies:**
- **Minitest** - Testing framework (or RSpec if preferred)
- **WebMock** - HTTP request stubbing for tests
- **VCR** - Record and replay HTTP interactions
- **RuboCop** - Code style and linting
- **YARD** - Documentation generation
- **SimpleCov** - Test coverage reporting

**Optional Dependencies:**
- **ActiveSupport** - For Rails integration helpers (if not in Rails app)
- **Rails** - For Rails-specific features (generators, middleware)

### Module Structure

```ruby
Umami
├── Configuration          # Configuration management
├── Client                 # Main client classes
│   ├── HTTPClient        # HTTP wrapper with Faraday
│   ├── Auth              # Authentication handling
│   ├── Events            # Event tracking
│   ├── Stats             # Analytics retrieval
│   ├── Websites          # Website management
│   ├── Users             # User management
│   ├── Teams             # Team management
│   ├── Sessions          # Session queries
│   ├── Links             # Link tracking
│   ├── Pixels            # Pixel tracking
│   └── Admin             # Admin functions
├── Models                 # Response models
│   ├── Response          # Base response wrapper
│   ├── Website           # Website model
│   ├── User              # User model
│   ├── Team              # Team model
│   ├── Session           # Session model
│   ├── Stats             # Statistics model
│   ├── Pageviews         # Pageviews model
│   └── ActiveUsers       # Active users model
├── Errors                 # Custom exceptions
│   ├── Error             # Base error
│   ├── ConfigurationError
│   ├── AuthenticationError
│   ├── ValidationError
│   ├── APIError
│   ├── NetworkError
│   └── RateLimitError
└── Rails                  # Rails integration (optional)
    ├── Middleware
    │   └── Tracker       # Rack middleware
    ├── Helpers           # View helpers
    ├── Trackable         # Controller concern
    └── Generators        # Rails generators
```

### Design Principles

1. **Pure Ruby HTTP Client**: No JavaScript wrapping. Direct HTTP calls to Umami API using Faraday.

2. **Inspired by umami-python**: Follow similar API design and feature set for familiarity across languages.

3. **Rails-Friendly**: Seamless integration with Rails while remaining framework-agnostic.

4. **Test-Friendly**: Built-in disabled mode for testing without hitting real API.

5. **Well-Documented**: Complete YARD documentation with examples for every public method.

6. **Idiomatic Ruby**: Follow Ruby conventions and style guidelines (RuboCop).

7. **Comprehensive Testing**: 100% test coverage with unit and integration tests.

8. **Error Handling**: Clear, specific exceptions with helpful error messages.

9. **Performance**: Efficient HTTP client with connection reuse, retries, and optional async tracking.

10. **Extensible**: Easy to add new endpoints as Umami API evolves.

---

## Testing Strategy

### Test Types

1. **Unit Tests**: Test individual methods and classes in isolation
   - Configuration
   - Model classes
   - Error handling
   - Validation logic

2. **Integration Tests**: Test API interactions with mocked HTTP
   - Use WebMock to stub HTTP requests
   - Test authentication flow
   - Test all API endpoints
   - Test error scenarios

3. **Fixture Tests**: Use VCR for recorded HTTP interactions
   - Record real API responses
   - Replay for consistent testing
   - Update when API changes

4. **Rails Integration Tests**: Test Rails-specific features
   - Middleware functionality
   - View helpers
   - Controller concerns
   - Generators

5. **End-to-End Tests**: Test against real Umami instance (optional)
   - Run in CI with test Umami server
   - Verify actual tracking works
   - Only for critical flows

### Test Organization

```
test/
├── test_helper.rb              # Test configuration
├── fixtures/                   # Test data and VCR cassettes
├── unit/
│   ├── configuration_test.rb
│   ├── errors_test.rb
│   └── models/
├── integration/
│   ├── auth_test.rb
│   ├── events_test.rb
│   ├── stats_test.rb
│   └── websites_test.rb
└── rails/
    ├── middleware_test.rb
    ├── helpers_test.rb
    └── generators_test.rb
```

### Coverage Goals

- **100% Coverage**: All code paths tested
- **Edge Cases**: Test error conditions, edge cases, invalid inputs
- **Documentation Examples**: All YARD examples must be tested
- **Performance**: Benchmark critical paths

---

## Quality Standards

### RuboCop Configuration

- Follow Ruby Style Guide
- Maximum line length: 120 characters
- Document all public methods with YARD
- Use consistent naming conventions
- Prefer readability over cleverness

### YARD Documentation Requirements

Every public method must have:
- Description of what it does
- `@param` tags for all parameters
- `@return` tag for return value
- `@raise` tags for exceptions
- `@example` with working code example
- `@see` tags for related methods

Example:
```ruby
# Tracks a custom event to Umami Analytics.
#
# @param event_name [String] the name of the event to track
# @param website_id [String, nil] the website ID (uses default if not provided)
# @param data [Hash] custom properties to attach to the event
# @return [Hash] response containing sessionId, visitId, and cache
# @raise [ValidationError] if event_name is empty or data exceeds limits
# @raise [APIError] if the API request fails
#
# @example Track a simple event
#   Umami.track_event('button_click')
#
# @example Track an event with custom data
#   Umami.track_event('purchase', data: { amount: 99.99, currency: 'USD' })
#
def track_event(event_name, website_id: nil, data: {})
  # ...
end
```

### Git Commit Standards

- Use conventional commits format
- Examples:
  - `feat: add event tracking API`
  - `fix: handle authentication errors properly`
  - `docs: update Rails integration guide`
  - `test: add tests for stats retrieval`
  - `refactor: simplify HTTP client initialization`

---

## Risk Assessment & Mitigation

### Technical Risks

1. **API Changes**: Umami API may change between versions
   - **Mitigation**: Version lock in tests, monitor Umami releases, add API version detection

2. **Authentication Complexity**: Different auth for self-hosted vs cloud
   - **Mitigation**: Clear documentation, automatic detection, helpful error messages

3. **Rate Limiting**: Umami may rate limit requests
   - **Mitigation**: Implement retry logic, respect Retry-After, add backoff

4. **Ruby Version Compatibility**: Support multiple Ruby versions
   - **Mitigation**: Test on 3.0, 3.1, 3.2, 3.3 in CI, avoid version-specific features

5. **Rails Compatibility**: Support multiple Rails versions
   - **Mitigation**: Test with Rails 6.1, 7.0, 7.1, make Rails optional

### Project Risks

1. **Scope Creep**: Too many features delay release
   - **Mitigation**: Focus on Phase 1-3 for v0.1.0, defer advanced features to v0.2.0+

2. **Testing Burden**: Achieving 100% coverage is time-consuming
   - **Mitigation**: Write tests alongside implementation, use TDD approach

3. **Documentation Effort**: Comprehensive docs take significant time
   - **Mitigation**: Document as you code, use YARD examples as tests

4. **Maintenance**: Keeping up with Umami updates
   - **Mitigation**: Set up monitoring for Umami releases, active community engagement

---

## Success Criteria

### Version 0.1.0 (MVP)
- ✅ Event tracking (Phase 3)
- ✅ Authentication (Phase 2)
- ✅ Basic stats retrieval (Phase 4 core)
- ✅ Configuration system (Phase 1)
- ✅ Test coverage > 90%
- ✅ RuboCop passing
- ✅ YARD documentation complete
- ✅ Published to RubyGems.org

### Version 0.2.0
- ✅ Rails integration (Phase 6)
- ✅ Complete stats API (Phase 4 all)
- ✅ Management APIs (Phase 5)
- ✅ Example applications (Phase 7)
- ✅ Test coverage = 100%

### Version 1.0.0 (Stable)
- ✅ All planned features complete
- ✅ Used in production by multiple projects
- ✅ No critical bugs for 3+ months
- ✅ Comprehensive documentation
- ✅ Active maintenance commitment

---

## Timeline Estimates

**Note**: These are rough estimates assuming part-time development (10-15 hours/week)

- **Phase 1**: 1 week - Foundation and setup
- **Phase 2**: 1 week - HTTP client and authentication
- **Phase 3**: 1-2 weeks - Event tracking (core functionality)
- **Phase 4**: 2 weeks - Analytics retrieval
- **Phase 5**: 1-2 weeks - Management APIs
- **Phase 6**: 2 weeks - Rails integration
- **Phase 7**: 1 week - Documentation and examples
- **Phase 8**: 1 week - Testing, polish, release

**Total**: 10-13 weeks for complete implementation

**MVP (v0.1.0)**: Phases 1-3 + basic Phase 4 = 4-5 weeks

---

## Next Steps

1. **Review and Approve Plan**: Stakeholder review of this implementation plan
2. **Set Up Repository**: Initialize git repo, create GitHub repository
3. **Configure Development Environment**: Ruby, bundler, editor setup
4. **Begin Phase 1**: Start with gem initialization and foundation
5. **Establish Test Umami Instance**: Set up test server for development/testing
6. **Create Project Board**: Track progress using GitHub Issues/Projects

---

## Appendix: Umami API Reference Summary

### Authentication Endpoints
- `POST /api/auth/login` - Login with username/password
- `POST /api/auth/verify` - Verify token validity

### Tracking Endpoint
- `POST /api/send` - Send events and pageviews (no auth required)

### Website Endpoints
- `GET /api/websites` - List websites
- `GET /api/websites/:id` - Get website
- `POST /api/websites` - Create website
- `PUT /api/websites/:id` - Update website
- `DELETE /api/websites/:id` - Delete website

### Statistics Endpoints
- `GET /api/websites/:websiteId/active` - Active users
- `GET /api/websites/:websiteId/stats` - Summary stats
- `GET /api/websites/:websiteId/pageviews` - Pageview time series
- `GET /api/websites/:websiteId/metrics` - Aggregated metrics
- `GET /api/websites/:websiteId/metrics/expanded` - Expanded metrics
- `GET /api/websites/:websiteId/events/series` - Event time series

### User Endpoints
- `GET /api/users` - List users
- `GET /api/users/:id` - Get user
- `POST /api/users` - Create user
- `PUT /api/users/:id` - Update user
- `DELETE /api/users/:id` - Delete user
- `GET /api/me` - Current user

### Team Endpoints
- `GET /api/teams` - List teams
- `GET /api/teams/:id` - Get team
- `POST /api/teams` - Create team
- `PUT /api/teams/:id` - Update team
- `DELETE /api/teams/:id` - Delete team

### Session Endpoints
- `GET /api/websites/:websiteId/sessions` - List sessions
- `GET /api/sessions/:id` - Session details

### Other Endpoints
- Admin endpoints (various)
- Links endpoints
- Pixels endpoints
- Reports endpoints

---

## Revision History

- **2025-12-03**: Initial plan created
- **Version**: 1.0
- **Author**: Claude (Anthropic)
- **Status**: Ready for review and approval
