# frozen_string_literal: true

require "json"

module Buzz
  class Response
    attr_reader :status, :headers, :body, :data

    def initialize(http_response)
      @status = http_response.code.to_i
      @headers = http_response.to_hash
      @body = http_response.body
      @data = parse_body
    end

    def success?
      status >= 200 && status < 300
    end

    def results
      data["results"] if data.is_a?(Hash)
    end

    def count
      data["count"] if data.is_a?(Hash)
    end

    def next_url
      data["next"] if data.is_a?(Hash)
    end

    def previous_url
      data["previous"] if data.is_a?(Hash)
    end

    private

    def parse_body
      return nil if body.nil? || body.empty?
      JSON.parse(body)
    rescue JSON::ParserError
      nil
    end
  end
end
