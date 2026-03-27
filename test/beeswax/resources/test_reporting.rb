# frozen_string_literal: true

require "test_helper"

class TestReportingResource < Minitest::Test
  include FakeServerHelper

  def setup
    @server = FakeServer.new.start
    @client = Beeswax::Client.new(
      buzz_key: @server.buzz_key,
      email: "user@example.com",
      password: "secret"
    )
    override_base_url(@client, @server.base_url)
  end

  def teardown
    @server.stop
  end

  def test_query
    results = @client.reporting.query(
      dimensions: ["campaign", "date"],
      metrics: ["impressions", "clicks", "spend"]
    )
    assert_kind_of Array, results
    assert_equal 2, results.length
    first = results.first
    assert first.key?("campaign_name")
    assert first.key?("spend")
    assert first.key?("impressions")
  end

  def test_list
    paginator = @client.reporting.list
    assert_kind_of Beeswax::Paginator, paginator
    items = paginator.to_a
    assert_equal 2, items.length
    assert_equal "Daily Spend", items.first["report_name"]
  end

  def test_find
    result = @client.reporting.find(1)
    assert_equal 1, result["report_id"]
    assert_equal "Daily Spend", result["report_name"]
  end

  def test_create
    result = @client.reporting.create(
      report_name: "New Report",
      dimensions: ["campaign"],
      metrics: ["spend"]
    )
    assert_equal 10, result["report_id"]
    assert_equal "New Report", result["report_name"]
  end

  def test_delete
    result = @client.reporting.delete(1)
    assert_equal true, result["success"]
  end
end
