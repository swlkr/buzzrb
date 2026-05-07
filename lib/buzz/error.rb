# frozen_string_literal: true

module Buzz
  class Error < StandardError
    attr_reader :status, :body

    def initialize(message = nil, status: nil, body: nil)
      @status = status
      @body = body
      super(message)
    end
  end

  class AuthenticationError < Error
  end

  class RateLimitError < Error
    attr_reader :retry_after

    def initialize(message = nil, status: nil, body: nil, retry_after: nil)
      @retry_after = retry_after
      super(message, status: status, body: body)
    end
  end

  class NotFoundError < Error
  end

  class ValidationError < Error
  end

  class ServerError < Error
  end
end
