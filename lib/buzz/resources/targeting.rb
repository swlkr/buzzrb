# frozen_string_literal: true

module Buzz
  module Resources
    class Targeting < Resource
      private

      def resource_path
        "/rest/v2/targeting-expressions"
      end
    end
  end
end
