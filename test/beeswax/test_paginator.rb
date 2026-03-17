# frozen_string_literal: true

require "test_helper"

class TestPaginator < Minitest::Test
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

  def test_auto_pagination
    paginator = Beeswax::Paginator.new(@client, "/rest/v2/advertisers")
    all_items = paginator.to_a
    assert_equal 3, all_items.length
    assert_equal "Acme Corp", all_items[0]["advertiser_name"]
    assert_equal "Foo LLC", all_items[2]["advertiser_name"]
  end

  def test_each_page
    paginator = Beeswax::Paginator.new(@client, "/rest/v2/advertisers")
    pages = []
    paginator.each_page { |page| pages << page }
    assert_equal 2, pages.length
    assert_equal 2, pages[0].results.length
    assert_equal 1, pages[1].results.length
  end

  def test_enumerable
    paginator = Beeswax::Paginator.new(@client, "/rest/v2/advertisers")
    names = paginator.map { |item| item["advertiser_name"] }
    assert_equal ["Acme Corp", "Widget Inc", "Foo LLC"], names
  end
end
