# frozen_string_literal: true

require_relative "beeswax/version"
require_relative "beeswax/configuration"
require_relative "beeswax/error"
require_relative "beeswax/cookie_jar"
require_relative "beeswax/response"
require_relative "beeswax/paginator"
require_relative "beeswax/resource"
require_relative "beeswax/resources/advertiser"
require_relative "beeswax/resources/campaign"
require_relative "beeswax/resources/line_item"
require_relative "beeswax/resources/creative"
require_relative "beeswax/resources/segment"
require_relative "beeswax/resources/targeting"
require_relative "beeswax/resources/creative_asset"
require_relative "beeswax/resources/search"
require_relative "beeswax/client"

module Beeswax
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
