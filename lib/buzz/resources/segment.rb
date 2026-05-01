# frozen_string_literal: true

module Buzz
  module Resources
    class Segment < Resource
      private

      def resource_path
        "/rest/v2/segments"
      end
    end
  end
end
