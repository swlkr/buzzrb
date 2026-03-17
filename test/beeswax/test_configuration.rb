# frozen_string_literal: true

require "test_helper"

class TestConfiguration < Minitest::Test
  def setup
    Beeswax.reset_configuration!
  end

  def test_configure_block
    Beeswax.configure do |c|
      c.buzz_key = "mycompany"
      c.email = "user@example.com"
      c.password = "secret"
    end

    assert_equal "mycompany", Beeswax.configuration.buzz_key
    assert_equal "user@example.com", Beeswax.configuration.email
    assert_equal "secret", Beeswax.configuration.password
  end

  def test_defaults
    config = Beeswax::Configuration.new
    assert_equal true, config.keep_logged_in
    assert_equal 10, config.open_timeout
    assert_equal 30, config.read_timeout
    assert_nil config.account_id
    assert_nil config.timezone
  end

  def test_base_url
    config = Beeswax::Configuration.new
    config.buzz_key = "mycompany"
    assert_equal "https://mycompany.api.beeswax.com", config.base_url
  end

  def test_validate_missing_buzz_key
    config = Beeswax::Configuration.new
    config.email = "user@example.com"
    config.password = "secret"
    assert_raises(ArgumentError) { config.validate! }
  end

  def test_validate_missing_email
    config = Beeswax::Configuration.new
    config.buzz_key = "mycompany"
    config.password = "secret"
    assert_raises(ArgumentError) { config.validate! }
  end

  def test_validate_missing_password
    config = Beeswax::Configuration.new
    config.buzz_key = "mycompany"
    config.email = "user@example.com"
    assert_raises(ArgumentError) { config.validate! }
  end

  def test_validate_success
    config = Beeswax::Configuration.new
    config.buzz_key = "mycompany"
    config.email = "user@example.com"
    config.password = "secret"
    assert_nil config.validate!
  end
end
