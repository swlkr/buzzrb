# frozen_string_literal: true

module Buzz
  class Paginator
    include Enumerable

    attr_reader :response

    def initialize(client, path, params = {})
      @client = client
      @path = path
      @params = params
      @response = nil
    end

    def each_page
      return enum_for(:each_page) unless block_given?

      @response = @client.get(@path, @params)
      yield @response

      while @response.next_url
        next_path = URI.parse(@response.next_url).path
        next_params = parse_query(URI.parse(@response.next_url).query)
        @response = @client.get(next_path, next_params)
        yield @response
      end
    end

    def each(&block)
      return enum_for(:each) unless block_given?

      each_page do |page|
        results = page.results || []
        results.each(&block)
      end
    end

    def to_a
      entries = []
      each { |item| entries << item }
      entries
    end

    private

    def parse_query(query_string)
      return {} if query_string.nil? || query_string.empty?
      URI.decode_www_form(query_string).to_h.transform_keys(&:to_sym)
    end
  end
end
