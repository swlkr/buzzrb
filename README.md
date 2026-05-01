# Buzz

Ruby client for the [Buzz/Freewheel Advertiser API v2](https://docs.freewheel.tv/docs/buzz-advertiser-api).

## Installation

Requires Ruby 3.0+.

Add to your Gemfile:

```ruby
gem "buzzrb"
```

Or install directly:

```
gem install buzzrb
```

## Quickstart

```ruby
require "buzz"

Buzz.configure do |c|
  c.buzz_key  = "my-buzz-key"
  c.email     = "user@example.com"
  c.password  = "secret"
end

client = Buzz::Client.new
campaigns = client.campaigns.list.to_a
```

Authentication happens automatically on the first request. You can also pass credentials directly:

```ruby
client = Buzz::Client.new(
  buzz_key: "my-buzz-key",
  email:    "user@example.com",
  password: "secret"
)
```

## Features

### CRUD Operations

Every resource (`advertisers`, `campaigns`, `line_items`, `creatives`, `segments`, `targeting`, `creative_assets`) supports the same interface:

```ruby
# Create
campaign = client.campaigns.create(
  advertiser_id: 1,
  campaign_name: "Summer 2026"
)

# Read
campaign = client.campaigns.find(42)

# Update
client.campaigns.update(42, campaign_name: "Fall 2026")

# Delete
client.campaigns.delete(42)
```

### Pagination

`list` returns an `Enumerable` paginator that follows next-page links automatically:

```ruby
# Iterate through all results
client.line_items.list(advertiser_id: 1).each do |item|
  puts item["line_item_name"]
end

# Or page by page
client.line_items.list.each_page do |page|
  puts "Got #{page.results.size} results"
end
```

### Reporting

Query spend, impression, and performance data:

```ruby
# Query performance data
rows = client.reporting.query(
  dimensions: ["campaign", "date"],
  metrics: ["impressions", "clicks", "spend"]
)
rows.each { |r| puts "#{r['campaign_name']}: $#{r['spend']}" }
```

Manage saved report definitions:

```ruby
# List saved reports
client.reporting.list.each { |r| puts r["report_name"] }

# Create a saved report
client.reporting.create(
  report_name: "Daily Spend",
  dimensions: ["campaign", "date"],
  metrics: ["spend", "impressions"]
)

# Find / delete
report = client.reporting.find(1)
client.reporting.delete(1)
```

### Search

```ruby
results = client.search(query: "acme", types: [:campaign, :line_item])
```

### Error Handling

All API errors raise typed exceptions under `Buzz::Error`:

```ruby
begin
  client.campaigns.find(999)
rescue Buzz::NotFoundError => e
  puts e.message
  puts e.status  # => 404
rescue Buzz::RateLimitError => e
  sleep e.retry_after
  retry
rescue Buzz::ValidationError, Buzz::AuthenticationError, Buzz::ServerError => e
  puts "#{e.class}: #{e.message}"
end
```

### Configuration Options

| Option | Default | Description |
|---|---|---|
| `buzz_key` | — | Your Buzz buzz key (required) |
| `email` | — | Account email (required) |
| `password` | — | Account password (required) |
| `account_id` | `nil` | Scope authentication to a specific account |
| `timezone` | `nil` | Sent as `X-Timezone` header |
| `keep_logged_in` | `true` | Call keep-logged-in after authenticating |
| `base_url` | `https://{buzz_key}.api.beeswax.com` | Override the API base URL |
| `open_timeout` | `10` | Connection open timeout in seconds |
| `read_timeout` | `30` | Read timeout in seconds |

## Testing

```
bundle exec rake test
```

## License

MIT
