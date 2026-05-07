# frozen_string_literal: true

module Buzz
  module Resources
    class AdvertiserCategory < Resource
      private

      def resource_path
        "/rest/v2/ref/advertiser-categories"
      end
    end
  end
end
