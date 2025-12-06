# Umami Client

A Ruby client library for the [Umami Analytics API](https://umami.is/docs/api).

## Table of Contents

### [Installation](docs/installation.md)

### [Usage](docs/usage.md)

- [Configuration](docs/usage.md#configuration)
- [Environment Variables](docs/usage.md#environment-variables)

### Tracking Features

#### [Event Tracking](docs/event-tracking.md)

- [Track Pageviews](docs/event-tracking.md#track-pageviews)
- [Track Custom Events](docs/event-tracking.md#track-custom-events)
- [User Identification](docs/event-tracking.md#user-identification)
- [Configuration Options](docs/event-tracking.md#configuration-options)
- [Custom User-Agent](docs/event-tracking.md#custom-user-agent)

#### [Links and Pixels](docs/links-pixels.md)

- [Overview](docs/links-pixels.md#overview)
- [Links API](docs/links-pixels.md#links-api)
  - [Creating Short Links](docs/links-pixels.md#creating-short-links)
  - [Listing Links](docs/links-pixels.md#listing-links)
  - [Getting Link Details](docs/links-pixels.md#getting-link-details)
  - [Updating Links](docs/links-pixels.md#updating-links)
  - [Deleting Links](docs/links-pixels.md#deleting-links)
- [Pixels API](docs/links-pixels.md#pixels-api)
  - [Creating Tracking Pixels](docs/links-pixels.md#creating-tracking-pixels)
  - [Listing Pixels](docs/links-pixels.md#listing-pixels)
  - [Getting Pixel Details](docs/links-pixels.md#getting-pixel-details)
  - [Updating Pixels](docs/links-pixels.md#updating-pixels)
  - [Deleting Pixels](docs/links-pixels.md#deleting-pixels)
- [Complete Examples](docs/links-pixels.md#complete-examples)
- [Best Practices](docs/links-pixels.md#best-practices)

### Data & Analytics

#### [Website Management](docs/website-management.md)

- [List Websites](docs/website-management.md#list-websites)
- [Get Website Details](docs/website-management.md#get-website-details)
- [Create Website](docs/website-management.md#create-website)
- [Update Website](docs/website-management.md#update-website)
- [Delete Website](docs/website-management.md#delete-website)
- [Reset Website Data](docs/website-management.md#reset-website-data)
- [Using the Website Model](docs/website-management.md#using-the-website-model)
- [Complete Example](docs/website-management.md#complete-example)

#### [Website Statistics](docs/website-statistics.md)

- [Active Visitors](docs/website-statistics.md#active-visitors)
- [Summary Statistics](docs/website-statistics.md#summary-statistics)
- [Pageviews Time Series](docs/website-statistics.md#pageviews-time-series)
- [Metrics](docs/website-statistics.md#metrics)
- [Event Series](docs/website-statistics.md#event-series)
- [Complete Dashboard Example](docs/website-statistics.md#complete-dashboard-example)
- [Time Handling](docs/website-statistics.md#time-handling)

#### [Session Queries](docs/session-queries.md)

- [Finding Sessions by Distinct ID](docs/session-queries.md#finding-sessions-by-distinct-id)
- [List Sessions](docs/session-queries.md#list-sessions)
- [Session Details](docs/session-queries.md#session-details)
- [Session Activity](docs/session-queries.md#session-activity)
- [Session Properties](docs/session-queries.md#session-properties)
- [Session Statistics](docs/session-queries.md#session-statistics)
- [Weekly Session Patterns](docs/session-queries.md#weekly-session-patterns)
- [Session Property Names](docs/session-queries.md#session-property-names)
- [Session Property Values](docs/session-queries.md#session-property-values)
- [Complete Visitor Tracking Example](docs/session-queries.md#complete-visitor-tracking-example)

#### [Reports Management](docs/reports-management.md)

- [List Reports](docs/reports-management.md#list-reports)
- [Create Report](docs/reports-management.md#create-report)
- [Get Report](docs/reports-management.md#get-report)
- [Update Report](docs/reports-management.md#update-report)
- [Delete Report](docs/reports-management.md#delete-report)
- [Complete Example](docs/reports-management.md#complete-example)
- [Report Parameters by Type](docs/reports-management.md#report-parameters-by-type)

#### [Executing Funnel Reports](docs/funnel-reports.md)

- [Basic Funnel Analysis](docs/funnel-reports.md#basic-funnel-analysis)
- [Funnel Step Types](docs/funnel-reports.md#funnel-step-types)
- [E-commerce Checkout Funnel](docs/funnel-reports.md#e-commerce-checkout-funnel)
- [Onboarding Funnel](docs/funnel-reports.md#onboarding-funnel)
- [Conversion Windows](docs/funnel-reports.md#conversion-windows)
- [Filtering Funnels](docs/funnel-reports.md#filtering-funnels)
- [Common Funnel Patterns](docs/funnel-reports.md#common-funnel-patterns)
- [Complete Funnel Analysis Example](docs/funnel-reports.md#complete-funnel-analysis-example)

#### [Executing Journey Reports](docs/journey-reports.md)

- [Basic Journey Analysis](docs/journey-reports.md#basic-journey-analysis)
- [Journey vs Funnel](docs/journey-reports.md#journey-vs-funnel)
- [Finding Paths to a Destination](docs/journey-reports.md#finding-paths-to-a-destination)
- [Journey Step Lengths](docs/journey-reports.md#journey-step-lengths)
- [Content Discovery Journey](docs/journey-reports.md#content-discovery-journey)
- [E-commerce Shopping Journey](docs/journey-reports.md#e-commerce-shopping-journey)
- [Event-Based Journeys](docs/journey-reports.md#event-based-journeys)
- [Segmented Journey Analysis](docs/journey-reports.md#segmented-journey-analysis)
- [Geographic Journey Differences](docs/journey-reports.md#geographic-journey-differences)
- [Complete Journey Analysis Example](docs/journey-reports.md#complete-journey-analysis-example)
- [Use Cases for Journey Reports](docs/journey-reports.md#use-cases-for-journey-reports)

#### [Executing Retention Reports](docs/retention-reports.md)

- [Basic Retention Analysis](docs/retention-reports.md#basic-retention-analysis)
- [Understanding Retention Data](docs/retention-reports.md#understanding-retention-data)
- [Key Retention Milestones](docs/retention-reports.md#key-retention-milestones)
- [Cohort Analysis](docs/retention-reports.md#cohort-analysis)
- [Retention by Device](docs/retention-reports.md#retention-by-device)
- [Geographic Retention Differences](docs/retention-reports.md#geographic-retention-differences)
- [Retention Curve Visualization](docs/retention-reports.md#retention-curve-visualization)
- [Timezone Considerations](docs/retention-reports.md#timezone-considerations)
- [Retention Benchmarks by Industry](docs/retention-reports.md#retention-benchmarks-by-industry)
- [Complete Retention Analysis Example](docs/retention-reports.md#complete-retention-analysis-example)
- [Retention Improvement Strategies](docs/retention-reports.md#retention-improvement-strategies)

#### [Executing Goal Reports](docs/goal-reports.md)

- [Basic Goal Tracking](docs/goal-reports.md#basic-goal-tracking)
- [Goals vs Funnels](docs/goal-reports.md#goals-vs-funnels)
- [Path-Based Goals](docs/goal-reports.md#path-based-goals)
- [Event-Based Goals](docs/goal-reports.md#event-based-goals)
- [Segmented Goal Tracking](docs/goal-reports.md#segmented-goal-tracking)
- [Mobile vs Desktop Goal Performance](docs/goal-reports.md#mobile-vs-desktop-goal-performance)
- [Multiple Goal Tracking](docs/goal-reports.md#multiple-goal-tracking)
- [Weekly Goal Monitoring](docs/goal-reports.md#weekly-goal-monitoring)
- [Common Goal Patterns](docs/goal-reports.md#common-goal-patterns)
- [Goal Benchmarks by Industry](docs/goal-reports.md#goal-benchmarks-by-industry)
- [Complete Goal Analysis Example](docs/goal-reports.md#complete-goal-analysis-example)
- [Goal Optimization Tips](docs/goal-reports.md#goal-optimization-tips)

#### [Executing Attribution Reports](docs/attribution-reports.md)

- [Understanding Attribution Models](docs/attribution-reports.md#understanding-attribution-models)
- [Basic Attribution Analysis](docs/attribution-reports.md#basic-attribution-analysis)
- [Attribution Response Structure](docs/attribution-reports.md#attribution-response-structure)
- [Comparing Attribution Models](docs/attribution-reports.md#comparing-attribution-models)
- [UTM Campaign Attribution](docs/attribution-reports.md#utm-campaign-attribution)
- [Paid Advertising Attribution](docs/attribution-reports.md#paid-advertising-attribution)
- [Segmented Attribution](docs/attribution-reports.md#segmented-attribution)
- [Geographic Attribution](docs/attribution-reports.md#geographic-attribution)
- [Complete Attribution Dashboard](docs/attribution-reports.md#complete-attribution-dashboard)
- [Marketing ROI Calculation](docs/attribution-reports.md#marketing-roi-calculation)
- [Attribution Best Practices](docs/attribution-reports.md#attribution-best-practices)
- [Common Attribution Patterns](docs/attribution-reports.md#common-attribution-patterns)

#### [Executing Breakdown Reports](docs/breakdown-reports.md)

- [Basic Usage](docs/breakdown-reports.md#basic-usage)
- [Available Dimensions](docs/breakdown-reports.md#available-dimensions)
- [Single Dimension Breakdowns](docs/breakdown-reports.md#single-dimension-breakdowns)
- [Multi-Dimension Breakdowns](docs/breakdown-reports.md#multi-dimension-breakdowns)
- [Filtered Breakdowns](docs/breakdown-reports.md#filtered-breakdowns)
- [Advanced Analysis Patterns](docs/breakdown-reports.md#advanced-analysis-patterns)
- [Business Intelligence Use Cases](docs/breakdown-reports.md#business-intelligence-use-cases)
- [Industry Benchmarks](docs/breakdown-reports.md#industry-benchmarks)

#### [Executing Revenue Reports](docs/revenue-reports.md)

- [Basic Usage](docs/revenue-reports.md#basic-usage)
- [Response Structure](docs/revenue-reports.md#response-structure)
- [Currency Support](docs/revenue-reports.md#currency-support)
- [Time-Series Analysis](docs/revenue-reports.md#time-series-analysis)
- [Geographic Revenue Analysis](docs/revenue-reports.md#geographic-revenue-analysis)
- [Device-Specific Revenue](docs/revenue-reports.md#device-specific-revenue)
- [Country-Specific Analysis](docs/revenue-reports.md#country-specific-analysis)
- [Segmented Revenue Analysis](docs/revenue-reports.md#segmented-revenue-analysis)
- [Period Comparison](docs/revenue-reports.md#period-comparison)
- [Revenue Growth Tracking](docs/revenue-reports.md#revenue-growth-tracking)
- [Customer Segmentation by Value](docs/revenue-reports.md#customer-segmentation-by-value)
- [Revenue Attribution](docs/revenue-reports.md#revenue-attribution)
- [Advanced Business Metrics](docs/revenue-reports.md#advanced-business-metrics)
- [Industry Benchmarks](docs/revenue-reports.md#industry-benchmarks)

#### [Executing UTM Reports](docs/utm-reports.md)

- [Basic Usage](docs/utm-reports.md#basic-usage)
- [UTM Parameters Overview](docs/utm-reports.md#utm-parameters-overview)
- [Traffic Source Analysis](docs/utm-reports.md#traffic-source-analysis)
- [Campaign Performance](docs/utm-reports.md#campaign-performance)
- [Medium Effectiveness](docs/utm-reports.md#medium-effectiveness)
- [Device-Specific Campaign Performance](docs/utm-reports.md#device-specific-campaign-performance)
- [Geographic Campaign Analysis](docs/utm-reports.md#geographic-campaign-analysis)
- [Content Variation Testing (A/B Testing)](docs/utm-reports.md#content-variation-testing-ab-testing)
- [Keyword Analysis (Paid Search)](docs/utm-reports.md#keyword-analysis-paid-search)
- [Multi-Channel Attribution](docs/utm-reports.md#multi-channel-attribution)
- [Period Comparison](docs/utm-reports.md#period-comparison)
- [ROI Analysis](docs/utm-reports.md#roi-analysis)
- [Source Quality Scoring](docs/utm-reports.md#source-quality-scoring)
- [Best Practices for UTM Tracking](docs/utm-reports.md#best-practices-for-utm-tracking)
- [Common UTM Patterns](docs/utm-reports.md#common-utm-patterns)
- [Industry Benchmarks](docs/utm-reports.md#industry-benchmarks)

### Administrative

#### [User Management](docs/user-management.md)

- [Get Current User](docs/user-management.md#get-current-user)
- [List All Users](docs/user-management.md#list-all-users)
- [Get User by ID](docs/user-management.md#get-user-by-id)
- [Create User](docs/user-management.md#create-user)
- [Update User](docs/user-management.md#update-user)
- [Delete User](docs/user-management.md#delete-user)
- [Get User's Websites](docs/user-management.md#get-users-websites)
- [Get User's Teams](docs/user-management.md#get-users-teams)
- [Using the User Model](docs/user-management.md#using-the-user-model)
- [Complete User Management Example](docs/user-management.md#complete-user-management-example)
- [Error Handling](docs/user-management.md#error-handling)
- [Best Practices](docs/user-management.md#best-practices)
- [Limitations](docs/user-management.md#limitations)
- [Common Use Cases](docs/user-management.md#common-use-cases)

#### [Team Management](docs/team-management.md)

- [Overview](docs/team-management.md#overview)
- [Team Roles](docs/team-management.md#team-roles)
- [Creating Teams](docs/team-management.md#creating-teams)
- [Listing Teams](docs/team-management.md#listing-teams)
- [Getting Team Details](docs/team-management.md#getting-team-details)
- [Updating Teams](docs/team-management.md#updating-teams)
- [Deleting Teams](docs/team-management.md#deleting-teams)
- [Joining Teams](docs/team-management.md#joining-teams)
- [Managing Team Members](docs/team-management.md#managing-team-members)
- [Team Model](docs/team-management.md#team-model)
- [Known Issues](docs/team-management.md#known-issues)
- [Complete Examples](docs/team-management.md#complete-examples)
- [Best Practices](docs/team-management.md#best-practices)
- [Common Use Cases](docs/team-management.md#common-use-cases)

### Development & Testing

#### [Disabled Mode for Testing](docs/disabled-mode.md)

- [Basic Usage](docs/disabled-mode.md#basic-usage)
- [Test Configuration](docs/disabled-mode.md#test-configuration)
- [With Logging](docs/disabled-mode.md#with-logging)
- [How It Works](docs/disabled-mode.md#how-it-works)
- [Example Test](docs/disabled-mode.md#example-test)

#### [Development](docs/development.md)

#### [Contributing](docs/contributing.md)

#### [License](docs/license.md)

