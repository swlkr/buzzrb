# frozen_string_literal: true

module Buzz
  module Resources
    class Campaign < Resource
      private

      def resource_path
        "/rest/v2/campaigns"
      end
    end
  end
end
