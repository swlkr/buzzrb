# frozen_string_literal: true

module Beeswax
  module Resources
    class CreativeLineItem
      attr_reader :client, :line_item_id

      def initialize(client, line_item_id)
        @client = client
        @line_item_id = line_item_id
      end

      def list(params = {})
        Paginator.new(client, base_path, params)
      end

      def create(attributes = {})
        response = client.post(base_path, attributes)
        response.data
      end

      def find(id)
        response = client.get("#{base_path}/#{id}")
        response.data
      end

      def delete(id)
        response = client.delete("#{base_path}/#{id}")
        response.data
      end

      private

      def base_path
        "/rest/v2/line-items/#{line_item_id}/creatives"
      end
    end
  end
end
