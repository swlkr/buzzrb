# frozen_string_literal: true

module Buzz
  module Resources
    class LineItem < Resource
      private

      def resource_path
        "/rest/v2/line-items"
      end
    end
  end
end
