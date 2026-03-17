# frozen_string_literal: true

module Beeswax
  module Resources
    class Creative < Resource
      private

      def resource_path
        "/rest/v2/creatives"
      end
    end
  end
end
