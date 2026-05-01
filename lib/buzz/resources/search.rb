# frozen_string_literal: true

module Buzz
  module Resources
    class Search < Resource
      private

      def resource_path
        "/rest/v2/search"
      end
    end
  end
end
