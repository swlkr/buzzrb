# frozen_string_literal: true

module Buzz
  module Resources
    class Advertiser < Resource
      private

      def resource_path
        "/rest/v2/advertisers"
      end
    end
  end
end
