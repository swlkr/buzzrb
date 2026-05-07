# frozen_string_literal: true

require "test_helper"

class TestAdvertiserCategoryResource < Minitest::Test
  include FakeServerHelper

  def setup
    @server = FakeServer.new.start
    @client = Buzz::Client.new(
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
    paginator = @client.advertiser_categories.list
    assert_kind_of Buzz::Paginator, paginator
    items = paginator.to_a
    assert_equal 2, items.length
    assert_equal "auto", items.first["key"]
    assert_equal "Automotive", items.first["name"]
  end

  def test_find
    result = @client.advertiser_categories.find("auto")
    assert_equal "auto", result["key"]
    assert_equal "Automotive", result["name"]
  end
end
