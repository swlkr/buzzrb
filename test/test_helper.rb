# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "buzz"
require "minitest/autorun"
require_relative "support/fake_server"

module FakeServerHelper
  def override_base_url(client, url)
    client.config.base_url = url
  end
end
