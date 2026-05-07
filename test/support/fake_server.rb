# frozen_string_literal: true

require "webrick"
require "json"

class AllMethodsServlet < WEBrick::HTTPServlet::AbstractServlet
  def initialize(server, &block)
    super(server)
    @block = block
  end

  %w[GET POST PUT DELETE PATCH].each do |method|
    define_method("do_#{method}") do |req, res|
      @block.call(req, res)
    end
  end

  def self.create(block)
    Class.new(self) do
      define_method(:initialize) do |server, *args|
        super(server)
        @block = block
      end
    end
  end
end

class FakeServer
  attr_reader :port, :requests

  def initialize
    @port = find_available_port
    @requests = []
    @authenticated = false
    @server = nil
  end

  def start
    @server = WEBrick::HTTPServer.new(
      Port: @port,
      Logger: WEBrick::Log.new("/dev/null"),
      AccessLog: []
    )

    mount_endpoints
    @thread = Thread.new { @server.start }
    sleep 0.1 until @server.status == :Running
    self
  end

  def stop
    @server&.shutdown
    @thread&.join(5)
  end

  def base_url
    "http://localhost:#{@port}"
  end

  def buzz_key
    "test"
  end

  private

  def find_available_port
    server = TCPServer.new("127.0.0.1", 0)
    port = server.addr[1]
    server.close
    port
  end

  def mount_endpoints
    # Authentication
    @server.mount_proc "/rest/v2/authenticate" do |req, res|
      @requests << { method: req.request_method, path: req.path, body: req.body }
      if req.request_method == "POST"
        body = JSON.parse(req.body) rescue {}
        if body["email"] == "user@example.com" && body["password"] == "secret"
          res["Set-Cookie"] = "test_buzz_cookie=session123; Path=/; HttpOnly"
          res["Content-Type"] = "application/json"
          res.body = JSON.generate({ success: true, message: "Authenticated" })
        else
          res.status = 401
          res["Content-Type"] = "application/json"
          res.body = JSON.generate({ message: "Invalid credentials" })
        end
      end
    end

    # Keep logged in
    @server.mount_proc "/rest/v2/authenticate/keep_logged_in" do |req, res|
      @requests << { method: req.request_method, path: req.path, body: req.body }
      res["Set-Cookie"] = "test_buzz_cookie=longsession456; Path=/; HttpOnly; Max-Age=2592000"
      res["Content-Type"] = "application/json"
      res.body = JSON.generate({ success: true })
    end

    # Advertisers - list
    @server.mount_proc "/rest/v2/advertisers" do |req, res|
      @requests << { method: req.request_method, path: req.path, body: req.body, query: req.query_string }

      unless req["Cookie"]&.include?("test_buzz_cookie")
        res.status = 401
        res["Content-Type"] = "application/json"
        res.body = JSON.generate({ message: "Not authenticated" })
        next
      end

      case req.request_method
      when "GET"
        res["Content-Type"] = "application/json"
        # Support pagination via offset param
        query = req.query || {}
        offset = (query["offset"] || "0").to_i
        if offset == 0
          res.body = JSON.generate({
            count: 3,
            next: "http://localhost:#{@port}/rest/v2/advertisers?offset=2&limit=2",
            previous: nil,
            results: [
              { advertiser_id: 1, advertiser_name: "Acme Corp", active: true },
              { advertiser_id: 2, advertiser_name: "Widget Inc", active: true }
            ]
          })
        else
          res.body = JSON.generate({
            count: 3,
            next: nil,
            previous: "http://localhost:#{@port}/rest/v2/advertisers?offset=0&limit=2",
            results: [
              { advertiser_id: 3, advertiser_name: "Foo LLC", active: false }
            ]
          })
        end
      when "POST"
        res.status = 201
        res["Content-Type"] = "application/json"
        body = JSON.parse(req.body) rescue {}
        res.body = JSON.generate(body.merge("advertiser_id" => 99))
      end
    end

    # Advertisers - by ID (needs custom servlet for PUT/DELETE support)
    handler = proc do |req, res|
      @requests << { method: req.request_method, path: req.path, body: req.body }

      unless req["Cookie"]&.include?("test_buzz_cookie")
        res.status = 401
        res["Content-Type"] = "application/json"
        res.body = JSON.generate({ message: "Not authenticated" })
        next
      end

      case req.request_method
      when "GET"
        res["Content-Type"] = "application/json"
        res.body = JSON.generate({ advertiser_id: 42, advertiser_name: "Test Advertiser", active: true })
      when "PUT"
        res["Content-Type"] = "application/json"
        body = JSON.parse(req.body) rescue {}
        res.body = JSON.generate({ advertiser_id: 42 }.merge(body))
      when "DELETE"
        res["Content-Type"] = "application/json"
        res.body = JSON.generate({ success: true })
      end
    end
    @server.mount "/rest/v2/advertisers/42", AllMethodsServlet.create(handler)

    # Search
    @server.mount_proc "/rest/v2/search" do |req, res|
      @requests << { method: req.request_method, path: req.path, query: req.query_string }

      unless req["Cookie"]&.include?("test_buzz_cookie")
        res.status = 401
        res["Content-Type"] = "application/json"
        res.body = JSON.generate({ message: "Not authenticated" })
        next
      end

      res["Content-Type"] = "application/json"
      res.body = JSON.generate({
        count: 1,
        results: [{ type: "advertiser", id: 1, name: "Acme Corp" }]
      })
    end

    # Advertiser Categories - list
    @server.mount_proc "/rest/v2/ref/advertiser-categories" do |req, res|
      @requests << { method: req.request_method, path: req.path, body: req.body, query: req.query_string }

      unless req["Cookie"]&.include?("test_buzz_cookie")
        res.status = 401
        res["Content-Type"] = "application/json"
        res.body = JSON.generate({ message: "Not authenticated" })
        next
      end

      case req.request_method
      when "GET"
        res["Content-Type"] = "application/json"
        res.body = JSON.generate({
          count: 2,
          next: nil,
          previous: nil,
          results: [
            { key: "auto", name: "Automotive" },
            { key: "tech", name: "Technology" }
          ]
        })
      end
    end

    # Advertiser Categories - find
    category_handler = proc do |req, res|
      @requests << { method: req.request_method, path: req.path, body: req.body }

      unless req["Cookie"]&.include?("test_buzz_cookie")
        res.status = 401
        res["Content-Type"] = "application/json"
        res.body = JSON.generate({ message: "Not authenticated" })
        next
      end

      case req.request_method
      when "GET"
        res["Content-Type"] = "application/json"
        res.body = JSON.generate({ key: "auto", name: "Automotive" })
      end
    end
    @server.mount "/rest/v2/ref/advertiser-categories/auto", AllMethodsServlet.create(category_handler)

    # Report data
    @server.mount_proc "/rest/v2/report-data" do |req, res|
      @requests << { method: req.request_method, path: req.path, body: req.body }

      unless req["Cookie"]&.include?("test_buzz_cookie")
        res.status = 401
        res["Content-Type"] = "application/json"
        res.body = JSON.generate({ message: "Not authenticated" })
        next
      end

      if req.request_method == "POST"
        rows = [
          { "campaign_id" => 1, "campaign_name" => "Summer Campaign", "date" => "2026-03-18",
            "impressions" => 15000, "clicks" => 450, "spend" => 125.50,
            "ctr" => 0.03, "cpm" => 8.37, "conversions" => 12, "vcr" => 0.85, "viewability" => 0.72 },
          { "campaign_id" => 2, "campaign_name" => "Winter Campaign", "date" => "2026-03-18",
            "impressions" => 22000, "clicks" => 880, "spend" => 210.75,
            "ctr" => 0.04, "cpm" => 9.58, "conversions" => 28, "vcr" => 0.91, "viewability" => 0.68 }
        ]

        res["Content-Type"] = "application/json"
        res.body = JSON.generate({ count: rows.size, results: rows })
      end
    end

    # Reports - list
    @server.mount_proc "/rest/v2/reports" do |req, res|
      @requests << { method: req.request_method, path: req.path, body: req.body, query: req.query_string }

      unless req["Cookie"]&.include?("test_buzz_cookie")
        res.status = 401
        res["Content-Type"] = "application/json"
        res.body = JSON.generate({ message: "Not authenticated" })
        next
      end

      case req.request_method
      when "GET"
        res["Content-Type"] = "application/json"
        res.body = JSON.generate({
          count: 2,
          next: nil,
          previous: nil,
          results: [
            { report_id: 1, report_name: "Daily Spend", dimensions: ["campaign", "date"], metrics: ["spend", "impressions"] },
            { report_id: 2, report_name: "Weekly Performance", dimensions: ["line_item"], metrics: ["clicks", "ctr"] }
          ]
        })
      when "POST"
        res.status = 201
        res["Content-Type"] = "application/json"
        body = JSON.parse(req.body) rescue {}
        res.body = JSON.generate(body.merge("report_id" => 10))
      end
    end

    # Reports - by ID
    report_handler = proc do |req, res|
      @requests << { method: req.request_method, path: req.path, body: req.body }

      unless req["Cookie"]&.include?("test_buzz_cookie")
        res.status = 401
        res["Content-Type"] = "application/json"
        res.body = JSON.generate({ message: "Not authenticated" })
        next
      end

      case req.request_method
      when "GET"
        res["Content-Type"] = "application/json"
        res.body = JSON.generate({ report_id: 1, report_name: "Daily Spend", dimensions: ["campaign", "date"], metrics: ["spend", "impressions"] })
      when "DELETE"
        res["Content-Type"] = "application/json"
        res.body = JSON.generate({ success: true })
      end
    end
    @server.mount "/rest/v2/reports/1", AllMethodsServlet.create(report_handler)

    # Creative Assets - multipart upload
    @server.mount_proc "/rest/v2/creative-assets" do |req, res|
      @requests << {
        method: req.request_method,
        path: req.path,
        content_type: req["Content-Type"],
        body: req.body,
        query: req.query_string
      }

      unless req["Cookie"]&.include?("test_buzz_cookie")
        res.status = 401
        res["Content-Type"] = "application/json"
        res.body = JSON.generate({ message: "Not authenticated" })
        next
      end

      if req.request_method == "POST"
        res.status = 201
        res["Content-Type"] = "application/json"
        
        # In a real multipart request, WEBrick parses req.query
        # but for this mock we just want to confirm it was sent as multipart
        if req["Content-Type"] =~ /multipart\/form-data/
          res.body = JSON.generate({ creative_asset_id: 123, status: "uploaded" })
        else
          # Fallback for JSON
          body = JSON.parse(req.body) rescue {}
          res.body = JSON.generate(body.merge("creative_asset_id" => 123))
        end
      end
    end

    # 404 catch-all
    @server.mount_proc "/rest/v2/notfound" do |req, res|
      @requests << { method: req.request_method, path: req.path }
      res.status = 404
      res["Content-Type"] = "application/json"
      res.body = JSON.generate({ message: "Not found" })
    end
  end
end
