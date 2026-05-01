# frozen_string_literal: true

module Buzz
  module Resources
    class CreativeAsset < Resource
      private

      def resource_path
        "/rest/v2/creative-assets"
      end
    end
  end
end
