# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../../lib", __dir__)
require "beeswax"
require "minitest/autorun"

# Integration tests against the Python mock Beeswax server.
# Requires: python3 server.py running on localhost:8550
#
# Run: BEESWAX_MOCK=1 bundle exec ruby test/integration/test_mock_server.rb

MOCK_URL = ENV.fetch("BEESWAX_MOCK_URL", "http://localhost:8550")

class TestMockServerIntegration < Minitest::Test
  def setup
    skip "Set BEESWAX_MOCK=1 to run integration tests" unless ENV["BEESWAX_MOCK"]
    @client = Beeswax::Client.new(
      buzz_key: "test",
      email: "user@example.com",
      password: "secret",
      base_url: MOCK_URL
    )
  end

  # --- Authentication ---

  def test_authenticate
    response = @client.authenticate
    assert response.success?
    assert @client.authenticated?
    assert_equal true, response.data["success"]
  end

  def test_cookie_jar_has_session_after_auth
    @client.authenticate
    uri = URI.parse(MOCK_URL)
    cookie = @client.cookie_jar.cookie_header(uri)
    refute_nil cookie
    refute_empty cookie
  end

  # --- Advertisers CRUD ---

  def test_list_advertisers
    results = @client.advertisers.list.to_a
    assert_kind_of Array, results
    refute_empty results
    first = results.first
    assert first.key?("id"), "Expected 'id' key, got: #{first.keys}"
    assert first.key?("name"), "Expected 'name' key, got: #{first.keys}"
    assert [true, false].include?(first["active"])
  end

  def test_list_advertisers_envelope
    response = @client.get("/rest/v2/advertisers")
    assert response.success?
    assert_kind_of Array, response.results
    assert_kind_of Integer, response.count
  end

  def test_find_advertiser
    result = @client.advertisers.find(42)
    assert_kind_of Hash, result
    assert_equal 42, result["id"]
  end

  def test_create_advertiser
    response = @client.post("/rest/v2/advertisers", { name: "Integration Test Advertiser", active: true })
    assert_equal 201, response.status
    assert_equal "Integration Test Advertiser", response.data["name"]
    assert_equal true, response.data["active"]
  end

  def test_update_advertiser
    result = @client.advertisers.update(42, name: "Updated Name")
    assert_kind_of Hash, result
    assert_equal 42, result["id"]
    assert_equal "Updated Name", result["name"]
  end

  def test_delete_advertiser
    result = @client.advertisers.delete(42)
    assert_kind_of Hash, result
    assert_equal true, result["success"]
  end

  # --- Campaigns ---

  def test_list_campaigns
    results = @client.campaigns.list.to_a
    assert_kind_of Array, results
    refute_empty results
    first = results.first
    assert first.key?("id")
    assert first.key?("advertiser_id")
    assert first.key?("name")
  end

  def test_create_campaign
    response = @client.post("/rest/v2/campaigns", { name: "Test Campaign", advertiser_id: 1 })
    assert_equal 201, response.status
    assert_equal "Test Campaign", response.data["name"]
  end

  # --- Line Items ---

  def test_list_line_items
    results = @client.line_items.list.to_a
    assert_kind_of Array, results
    refute_empty results
    first = results.first
    assert first.key?("id")
    assert first.key?("campaign_id")
    assert first.key?("type")
  end

  def test_create_line_item
    response = @client.post("/rest/v2/line-items", { name: "Test LI", campaign_id: 1, type: "banner" })
    assert_equal 201, response.status
    assert_equal "Test LI", response.data["name"]
  end

  # --- Creatives ---

  def test_list_creatives
    results = @client.creatives.list.to_a
    assert_kind_of Array, results
    refute_empty results
    first = results.first
    assert first.key?("id")
    assert first.key?("creative_type")
  end

  # --- Segments ---

  def test_list_segments
    results = @client.segments.list.to_a
    assert_kind_of Array, results
    refute_empty results
    first = results.first
    assert first.key?("id")
    assert first.key?("name")
  end

  # --- Targeting Expressions ---

  def test_list_targeting_expressions
    results = @client.targeting.list.to_a
    assert_kind_of Array, results
    refute_empty results
    first = results.first
    assert first.key?("id")
    assert first.key?("expression")
  end

  # --- Creative Assets ---

  def test_list_creative_assets
    results = @client.creative_assets.list.to_a
    assert_kind_of Array, results
    refute_empty results
    first = results.first
    assert first.key?("id")
    assert first.key?("url")
  end

  # --- Search ---

  def test_search
    response = @client.search(query: "acme")
    assert response.success?
    assert_kind_of Hash, response.data
  end

  def test_search_with_types
    response = @client.search(query: "acme", types: [:advertiser])
    assert response.success?
    assert_kind_of Hash, response.data
  end

  # --- Pagination envelope ---

  def test_pagination_envelope_structure
    response = @client.get("/rest/v2/advertisers")
    assert response.success?
    data = response.data
    assert data.key?("results"), "Missing 'results' key"
    assert data.key?("count"), "Missing 'count' key"
    assert data.key?("next"), "Missing 'next' key"
    assert data.key?("previous"), "Missing 'previous' key"
  end

  # --- Error handling ---

  def test_400_raises_validation_error
    @client.authenticate
    err = assert_raises(Beeswax::ValidationError) do
      @client.get("/rest/v2/test/bad-request")
    end
    assert_equal 400, err.status
    assert_match(/Validation failed/, err.message)
  end

  def test_404_raises_not_found_error
    @client.authenticate
    err = assert_raises(Beeswax::NotFoundError) do
      @client.get("/rest/v2/test/not-found")
    end
    assert_equal 404, err.status
  end

  def test_429_raises_rate_limit_error
    @client.authenticate
    err = assert_raises(Beeswax::RateLimitError) do
      @client.get("/rest/v2/test/rate-limit")
    end
    assert_equal 429, err.status
    assert_equal 30, err.retry_after
  end

  def test_500_raises_server_error
    @client.authenticate
    err = assert_raises(Beeswax::ServerError) do
      @client.get("/rest/v2/test/server-error")
    end
    assert_equal 500, err.status
  end
end
