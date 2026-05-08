# frozen_string_literal: true

require "net/http"
require "uri"
require "json"
require "tempfile"

module Buzz
  class Client
    attr_reader :config, :cookie_jar

    def initialize(buzz_key: nil, email: nil, password: nil, **options)
      @config = if buzz_key
        Configuration.new.tap do |c|
          c.buzz_key = buzz_key
          c.email = email
          c.password = password
          options.each { |k, v| c.public_send(:"#{k}=", v) }
        end
      else
        Buzz.configuration.dup
      end

      @config.validate!
      @cookie_jar = CookieJar.new
      @http = nil
      @authenticated = false
      @mutex = Mutex.new
    end

    def get(path, params = {})
      request(:get, path, params: params)
    end

    def post(path, body = {})
      request(:post, path, body: body)
    end

    def put(path, body = {})
      request(:put, path, body: body)
    end

    def delete(path, params = {})
      request(:delete, path, params: params)
    end

    def authenticate
      uri = build_uri("/rest/v2/authenticate")
      body = {email: config.email, password: config.password}
      body[:account_id] = config.account_id if config.account_id

      req = build_request(:post, uri)
      req["Content-Type"] = "application/json"
      req.body = JSON.generate(body)

      response = execute(uri, req)

      unless response.success?
        raise(
          AuthenticationError.new(
            "Authentication failed: #{response.body}",
            status: response.status,
            body: response.data
          )
        )
      end

      @authenticated = true

      if config.keep_logged_in
        keep_logged_in
      end

      response
    end

    def authenticated?
      @authenticated
    end

    # Resource accessors
    def advertisers
      Resources::Advertiser.new(self)
    end

    def advertiser_categories
      Resources::AdvertiserCategory.new(self)
    end

    def campaigns
      Resources::Campaign.new(self)
    end

    def line_items
      Resources::LineItem.new(self)
    end

    def creatives
      Resources::Creative.new(self)
    end

    def creative_templates
      Resources::CreativeTemplate.new(self)
    end

    def segments
      Resources::Segment.new(self)
    end

    def targeting
      Resources::Targeting.new(self)
    end

    def creative_assets
      Resources::CreativeAsset.new(self)
    end

    def creative_line_items(line_item_id)
      Resources::CreativeLineItem.new(self, line_item_id)
    end

    def reporting
      Resources::Reporting.new(self)
    end

    def search(query:, types: nil)
      params = {q: query}
      params[:entity_types] = Array(types).map(&:to_s).join(",") if types
      get("/rest/v2/search", params)
    end

    private

    def keep_logged_in
      uri = build_uri("/rest/v2/authenticate/keep_logged_in")
      req = build_request(:post, uri)
      req["Content-Type"] = "application/json"
      req.body = JSON.generate({})
      execute(uri, req)
    end

    def request(method, path, params: {}, body: nil)
      ensure_authenticated

      uri = build_uri(path, params)
      req = build_request(method, uri)

      if body
        if multipart?(body)
          req.set_form(format_multipart(body), "multipart/form-data")
        else
          req["Content-Type"] = "application/json"
          req.body = JSON.generate(body)
        end
      end

      response = execute(uri, req)

      if response.status == 401
        @authenticated = false
        authenticate
        uri = build_uri(path, params)
        req = build_request(method, uri)

        if body
          if multipart?(body)
            req.set_form(format_multipart(body), "multipart/form-data")
          else
            req["Content-Type"] = "application/json"
            req.body = JSON.generate(body)
          end
        end

        response = execute(uri, req)
      end

      handle_errors(response)
      response
    end

    def ensure_authenticated
      authenticate unless @authenticated
    end

    def build_uri(path, params = {})
      uri = URI.parse("#{config.base_url}#{path}")
      if params && !params.empty?
        query = params.map { |k, v| "#{URI.encode_www_form_component(k)}=#{URI.encode_www_form_component(v)}" }
        uri.query = query.join("&")
      end

      uri
    end

    def build_request(method, uri)
      klass = case method
      when :get
        Net::HTTP::Get
      when :post
        Net::HTTP::Post
      when :put
        Net::HTTP::Put
      when :delete
        Net::HTTP::Delete
      end

      req = klass.new(uri)
      req["Accept"] = "application/json"
      req["X-Timezone"] = config.timezone if config.timezone

      cookie = cookie_jar.cookie_header(uri)
      req["Cookie"] = cookie if cookie

      req
    end

    def execute(uri, req)
      http = connection_for(uri)
      raw = http.request(req)

      # Parse cookies from response
      if raw.get_fields("Set-Cookie")
        raw.get_fields("Set-Cookie").each do |cookie_str|
          cookie_jar.parse(cookie_str, uri)
        end
      end

      Response.new(raw)
    end

    def connection_for(uri)
      @mutex.synchronize do
        if @http.nil? || !@http.started?
          @http = Net::HTTP.new(uri.host, uri.port)
          @http.use_ssl = uri.scheme == "https"
          @http.open_timeout = config.open_timeout
          @http.read_timeout = config.read_timeout
          @http.keep_alive_timeout = 30
          @http.start
        end

        @http
      end
    end

    def handle_errors(response)
      case response.status
      when 200..299
        # success
      when 400
        raise ValidationError.new(error_message(response), status: 400, body: response.data)
      when 401
        raise AuthenticationError.new(error_message(response), status: 401, body: response.data)
      when 404
        raise NotFoundError.new(error_message(response), status: 404, body: response.data)
      when 429
        retry_after = response.headers["retry-after"]&.first&.to_i
        raise RateLimitError.new(error_message(response), status: 429, body: response.data, retry_after: retry_after)
      when 500..599
        raise ServerError.new(error_message(response), status: response.status, body: response.data)
      else
        raise Error.new(error_message(response), status: response.status, body: response.data)
      end
    end

    def multipart?(body)
      return false unless body.is_a?(Hash) || body.is_a?(Array)

      if body.is_a?(Hash)
        body.values.any? { |v| v.is_a?(IO) || (defined?(Tempfile) && v.is_a?(Tempfile)) }
      else
        body.any? { |v| v.is_a?(IO) || (defined?(Tempfile) && v.is_a?(Tempfile)) }
      end
    end

    def format_multipart(body)
      return body unless body.is_a?(Hash)

      body.map do |k, v|
        if v.is_a?(IO) || (defined?(Tempfile) && v.is_a?(Tempfile))
          [k.to_s, v]
        else
          [k.to_s, v.to_s]
        end
      end
    end

    def error_message(response)
      if response.data.is_a?(Hash) && response.data["message"]
        response.data["message"]
      elsif response.data.is_a?(Hash) && response.data["detail"]
        response.data["detail"]
      else
        "HTTP #{response.status}"
      end
    end
  end
end
