# frozen_string_literal: true

require "uri"
require "time"

module Buzz
  class CookieJar
    Cookie = Struct.new(:name, :value, :domain, :path, :expires, :secure, :httponly, keyword_init: true)

    def initialize
      @cookies = {}
      @mutex = Mutex.new
    end

    def parse(set_cookie_header, request_uri)
      return unless set_cookie_header

      headers = set_cookie_header.is_a?(Array) ? set_cookie_header : [set_cookie_header]
      uri = request_uri.is_a?(URI) ? request_uri : URI.parse(request_uri)

      @mutex.synchronize do
        headers.each do |header|
          cookie = parse_cookie(header, uri)
          @cookies[cookie.name] = cookie if cookie
        end
      end
    end

    def cookie_header(uri)
      uri = uri.is_a?(URI) ? uri : URI.parse(uri)
      now = Time.now

      @mutex.synchronize do
        matching = @cookies.values.select do |cookie|
          next false if cookie.expires && cookie.expires < now
          next false if cookie.secure && uri.scheme != "https"
          path_matches?(uri.path, cookie.path)
        end

        return nil if matching.empty?
        matching.map { |c| "#{c.name}=#{c.value}" }.join("; ")
      end
    end

    def clear
      @mutex.synchronize { @cookies.clear }
    end

    def empty?
      @mutex.synchronize { @cookies.empty? }
    end

    def size
      @mutex.synchronize { @cookies.size }
    end

    private

    def parse_cookie(header, uri)
      parts = header.split(";").map(&:strip)
      return nil if parts.empty?

      name_value = parts.shift
      eq_index = name_value.index("=")
      return nil unless eq_index

      name = name_value[0...eq_index].strip
      value = name_value[(eq_index + 1)..].strip
      return nil if name.empty?

      attrs = {name: name, value: value, domain: uri.host, path: "/", secure: false, httponly: false}

      parts.each do |part|
        key, val = part.split("=", 2).map(&:strip)
        case key.downcase
        when "domain"
          attrs[:domain] = val&.delete_prefix(".") if val
        when "path"
          attrs[:path] = val if val
        when "expires"
          attrs[:expires] = Time.parse(val) rescue nil if val
        when "max-age"
          attrs[:expires] = Time.now + val.to_i if val
        when "secure"
          attrs[:secure] = true
        when "httponly"
          attrs[:httponly] = true
        end
      end

      Cookie.new(**attrs)
    end

    def path_matches?(request_path, cookie_path)
      request_path = "/" if request_path.nil? || request_path.empty?
      cookie_path = "/" if cookie_path.nil? || cookie_path.empty?
      request_path.start_with?(cookie_path)
    end
  end
end
