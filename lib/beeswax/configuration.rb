# frozen_string_literal: true

module Beeswax
  class Configuration
    attr_accessor :buzz_key, :email, :password, :keep_logged_in,
                  :account_id, :timezone, :open_timeout, :read_timeout
    attr_writer :base_url

    def initialize
      @keep_logged_in = true
      @open_timeout = 10
      @read_timeout = 30
    end

    def base_url
      @base_url || "https://#{buzz_key}.api.beeswax.com"
    end

    def validate!
      raise ArgumentError, "buzz_key is required" unless buzz_key && !buzz_key.empty?
      raise ArgumentError, "email is required" unless email && !email.empty?
      raise ArgumentError, "password is required" unless password && !password.empty?
    end
  end
end
