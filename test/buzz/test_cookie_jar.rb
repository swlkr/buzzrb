# frozen_string_literal: true

require "test_helper"

class TestCookieJar < Minitest::Test
  def setup
    @jar = Buzz::CookieJar.new
    @uri = URI.parse("https://test.api.beeswax.com/rest/v2/authenticate")
  end

  def test_empty_jar
    assert @jar.empty?
    assert_equal 0, @jar.size
    assert_nil @jar.cookie_header(@uri)
  end

  def test_parse_simple_cookie
    @jar.parse("session=abc123; Path=/", @uri)
    refute @jar.empty?
    assert_equal 1, @jar.size
    assert_equal "session=abc123", @jar.cookie_header(@uri)
  end

  def test_parse_multiple_cookies
    @jar.parse("session=abc123; Path=/", @uri)
    @jar.parse("token=xyz789; Path=/", @uri)
    assert_equal 2, @jar.size
    header = @jar.cookie_header(@uri)
    assert_includes header, "session=abc123"
    assert_includes header, "token=xyz789"
  end

  def test_cookie_replacement
    @jar.parse("session=first; Path=/", @uri)
    @jar.parse("session=second; Path=/", @uri)
    assert_equal 1, @jar.size
    assert_equal "session=second", @jar.cookie_header(@uri)
  end

  def test_expired_cookie_not_sent
    @jar.parse("session=abc123; Path=/; Max-Age=0", @uri)
    assert_nil @jar.cookie_header(@uri)
  end

  def test_secure_cookie_not_sent_over_http
    @jar.parse("session=abc123; Path=/; Secure", @uri)
    http_uri = URI.parse("http://test.api.beeswax.com/rest/v2/test")
    assert_nil @jar.cookie_header(http_uri)
  end

  def test_secure_cookie_sent_over_https
    @jar.parse("session=abc123; Path=/; Secure", @uri)
    assert_equal "session=abc123", @jar.cookie_header(@uri)
  end

  def test_path_matching
    @jar.parse("session=abc123; Path=/rest/v2", @uri)
    assert_equal "session=abc123", @jar.cookie_header(@uri)

    other_uri = URI.parse("https://test.api.beeswax.com/other")
    assert_nil @jar.cookie_header(other_uri)
  end

  def test_clear
    @jar.parse("session=abc123; Path=/", @uri)
    @jar.clear
    assert @jar.empty?
  end

  def test_parse_with_domain
    @jar.parse("session=abc123; Path=/; Domain=.api.beeswax.com", @uri)
    assert_equal 1, @jar.size
  end

  def test_parse_with_httponly
    @jar.parse("session=abc123; Path=/; HttpOnly", @uri)
    assert_equal "session=abc123", @jar.cookie_header(@uri)
  end

  def test_parse_nil_header
    @jar.parse(nil, @uri)
    assert @jar.empty?
  end

  def test_parse_array_of_headers
    headers = ["session=abc; Path=/", "token=xyz; Path=/"]
    @jar.parse(headers, @uri)
    assert_equal 2, @jar.size
  end
end
