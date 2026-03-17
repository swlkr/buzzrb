# frozen_string_literal: true

require "test_helper"

class TestAdvertiserResource < Minitest::Test
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

  def test_list
    paginator = @client.advertisers.list
    assert_kind_of Beeswax::Paginator, paginator
    items = paginator.to_a
    assert_equal 3, items.length
  end

  def test_find
    result = @client.advertisers.find(42)
    assert_equal 42, result["advertiser_id"]
    assert_equal "Test Advertiser", result["advertiser_name"]
  end

  def test_create
    result = @client.advertisers.create(advertiser_name: "New Advertiser")
    assert_equal 99, result["advertiser_id"]
    assert_equal "New Advertiser", result["advertiser_name"]
  end

  def test_update
    result = @client.advertisers.update(42, advertiser_name: "Updated Name")
    assert_equal 42, result["advertiser_id"]
    assert_equal "Updated Name", result["advertiser_name"]
  end

  def test_delete
    result = @client.advertisers.delete(42)
    assert_equal true, result["success"]
  end
end
