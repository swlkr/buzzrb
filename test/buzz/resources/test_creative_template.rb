# frozen_string_literal: true

require "test_helper"

class TestCreativeTemplateResource < Minitest::Test
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
    paginator = @client.creative_templates.list
    assert_kind_of Buzz::Paginator, paginator
    items = paginator.to_a
    assert_equal 1, items.length
    assert_equal "JPEG Banner", items.first["creative_template_name"]
  end
end
