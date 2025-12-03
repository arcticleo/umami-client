# frozen_string_literal: true

module UmamiClient
  # Base error class for all UmamiClient errors
  class Error < StandardError; end

  # Raised when API key is missing or invalid
  class AuthenticationError < Error; end

  # Raised when a request is malformed or invalid
  class BadRequestError < Error; end

  # Raised when a requested resource is not found
  class NotFoundError < Error; end

  # Raised when rate limit is exceeded
  class RateLimitError < Error; end

  # Raised when the server returns an error
  class ServerError < Error; end

  # Raised when a network error occurs
  class NetworkError < Error; end
end
