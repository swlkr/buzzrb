# frozen_string_literal: true

require "test_helper"
require "tempfile"

class TestMultipartUpload < Minitest::Test
  include FakeServerHelper

  def setup
    @server = FakeServer.new.start
    @client = Buzz::Client.new(
      buzz_key: @server.buzz_key,
      email: "user@example.com",
      password: "secret"
    )
    override_base_url(@client, @server.base_url)
    @client.authenticate
  end

  def teardown
    @server.stop
  end

  def test_post_with_file_upload
    tempfile = Tempfile.new("test_asset.png")
    tempfile.write("fake-image-content")
    tempfile.rewind

    begin
      response = @client.post("/rest/v2/creative-assets", {
        advertiser_id: 1,
        file: tempfile
      })

      assert_equal 201, response.status
      assert_equal 123, response.data["creative_asset_id"]
      assert_equal "uploaded", response.data["status"]

      # Verify the request was sent as multipart
      upload_req = @server.requests.find { |r| r[:path] == "/rest/v2/creative-assets" && r[:method] == "POST" }
      assert_match(/multipart\/form-data/, upload_req[:content_type])
      assert_match(/fake-image-content/, upload_req[:body])
    ensure
      tempfile.close
      tempfile.unlink
    end
  end

  def test_post_without_file_is_still_json
    response = @client.post("/rest/v2/creative-assets", {
      advertiser_id: 1,
      name: "Standard Asset"
    })

    assert_equal 201, response.status
    
    upload_req = @server.requests.find { |r| r[:path] == "/rest/v2/creative-assets" && r[:method] == "POST" }
    assert_equal "application/json", upload_req[:content_type]
  end
end
