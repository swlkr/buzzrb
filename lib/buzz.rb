# frozen_string_literal: true

require_relative "buzz/version"
require_relative "buzz/configuration"
require_relative "buzz/error"
require_relative "buzz/cookie_jar"
require_relative "buzz/response"
require_relative "buzz/paginator"
require_relative "buzz/resource"
require_relative "buzz/resources/advertiser"
require_relative "buzz/resources/advertiser_category"
require_relative "buzz/resources/campaign"
require_relative "buzz/resources/line_item"
require_relative "buzz/resources/creative"
require_relative "buzz/resources/segment"
require_relative "buzz/resources/targeting"
require_relative "buzz/resources/creative_asset"
require_relative "buzz/resources/creative_line_item"
require_relative "buzz/resources/search"
require_relative "buzz/resources/reporting"
require_relative "buzz/client"

module Buzz
  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def reset_configuration!
      @configuration = Configuration.new
    end
  end
end
