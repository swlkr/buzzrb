# frozen_string_literal: true

module Buzz
  module Resources
    class Reporting
      attr_reader :client

      def initialize(client)
        @client = client
      end

      # Query performance data (spend, impressions, clicks, etc.)
      def query(dimensions: [], metrics: [], **params)
        body = { dimensions: dimensions, metrics: metrics }.merge(params)
        response = client.post("/rest/v2/report-data", body)
        response.data["results"]
      end

      # CRUD on saved report definitions
      def list(params = {})
        Paginator.new(client, "/rest/v2/reports", params)
      end

      def find(id)
        client.get("/rest/v2/reports/#{id}").data
      end

      def create(attributes = {})
        client.post("/rest/v2/reports", attributes).data
      end

      def delete(id)
        client.delete("/rest/v2/reports/#{id}").data
      end
    end
  end
end
