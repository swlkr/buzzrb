# frozen_string_literal: true

require "test_helper"

class TestClient < Minitest::Test
  include FakeServerHelper

  def setup
    @server = FakeServer.new.start
    @client = Beeswax::Client.new(
      buzz_key: @server.buzz_key,
      email: "user@example.com",
      password: "secret",
      open_timeout: 5,
      read_timeout: 5
    )
    override_base_url(@client, @server.base_url)
  end

  def teardown
    @server.stop
  end

  def test_authentication
    @client.authenticate
    assert @client.authenticated?
  end

  def test_authentication_failure
    client = Beeswax::Client.new(
      buzz_key: @server.buzz_key,
      email: "wrong@example.com",
      password: "wrong"
    )
    override_base_url(client, @server.base_url)

    assert_raises(Beeswax::AuthenticationError) { client.authenticate }
  end

  def test_lazy_authentication
    refute @client.authenticated?
    response = @client.get("/rest/v2/advertisers")
    assert @client.authenticated?
    assert response.success?
  end

  def test_get_request
    response = @client.get("/rest/v2/advertisers")
    assert response.success?
    assert_equal 3, response.count
    assert_equal 2, response.results.length
  end

  def test_post_request
    response = @client.post("/rest/v2/advertisers", { advertiser_name: "New Co" })
    assert_equal 201, response.status
    assert_equal 99, response.data["advertiser_id"]
    assert_equal "New Co", response.data["advertiser_name"]
  end

  def test_cookie_sent_after_auth
    @client.authenticate
    @client.get("/rest/v2/advertisers")

    # Check that the request to advertisers included the cookie
    adv_request = @server.requests.find { |r| r[:path] == "/rest/v2/advertisers" && r[:method] == "GET" }
    assert adv_request
  end

  def test_keep_logged_in
    @client.authenticate
    keep_alive_req = @server.requests.find { |r| r[:path] == "/rest/v2/authenticate/keep_logged_in" }
    assert keep_alive_req
  end

  def test_search
    response = @client.search(query: "acme", types: [:advertiser])
    assert response.success?
    assert_equal 1, response.count
  end

  def test_not_found_raises
    assert_raises(Beeswax::NotFoundError) do
      @client.get("/rest/v2/notfound")
    end
  end
end
