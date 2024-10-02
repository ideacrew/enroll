# frozen_string_literal: true

module EnrollMiddleware
  # Add the rails CSP nonce to a custom header, so we can
  # construct our CSP around it using Nginx.
  class RailsContentNonce
    def initialize(app)
      @app = app
    end

    def call(env)
      request = ActionDispatch::Request.new env
      env["X-Rails-Content-Nonce"] = request.content_security_policy_nonce
      @app.call(env)
    end
  end
end

Rails.application.config.middleware.insert_after ActionDispatch::ContentSecurityPolicy::Middleware, EnrollMiddleware::RailsContentNonce