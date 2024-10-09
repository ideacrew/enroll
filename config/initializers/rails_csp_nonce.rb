# frozen_string_literal: true

require "loofah"

module EnrollMiddleware
  # Insert the rails content nonce into in-page script tags
  # where it doesn't exist, and report the violation as a warning.
  class RailsContentNonceRewrite
    def initialize(app)
      @app = app
    end

    def call(env)
      request = ActionDispatch::Request.new env
      stat, headers, body = @app.call(env)
      nonce = request.content_security_policy_nonce
      content_type_header = headers['Content-Type']
      content_type = Mime::Type.lookup(content_type_header)
      return [stat, headers, body] unless content_type&.html?

      doc = nil
      if body.is_a?(ActionDispatch::Response::RackBody)
        doc = Loofah.document(body.body)
      else
        doc = Loofah.document(body)
      end
      doc.xpath("//script").each do |node|
        nonce_node(node, nonce, :script, request)
      end
      doc.xpath("//style").each do |node|
        nonce_node(node, nonce, :style, request)
      end
      response = ActionDispatch::Response.new(stat, headers, doc.to_s)
      response.to_a
    end

    def nonce_node(node, nonce, kind, ad_request)
      return if node["src"] || node["integrity"] || node["nonce"]
      node["nonce"] = nonce
      ad_request.logger.tagged("CSPTagMissingNonce").warn("#{kind} tag is missing a nonce: #{ad_request.original_url}")
    end
  end
end

Rails.application.config.content_security_policy_nonce_generator = -> request { SecureRandom.base64(16) }
Rails.application.config.content_security_policy_nonce_directives = %w(script-src style-src)

Rails.application.config.content_security_policy do |policy|
  csp_proto = Rails.env.production? ? :https : :http
  policy.default_src :self, csp_proto
  policy.object_src  :none
  policy.font_src    :self, csp_proto, :data, "*.gstatic.com",  "*.fontawesome.com"
  policy.img_src     :self, csp_proto, :data, "*.google-analytics.com", "*.gstatic.com", "*.googletagmanager.com"
  policy.script_src  :self, csp_proto, "https://tagmanager.google.com", "https://www.googletagmanager.com", "https://apps.usw2.pure.cloud", "*.fontawesome.com", "*.google-analytics.com"
  policy.style_src   :self, csp_proto, "unsafe-inline", "https://tagmanager.google.com", "https://www.googletagmanager.com", "https://fonts.googleapis.com", "*.fontawesome.com"
  policy.connect_src :self, csp_proto, "https://api.usw2.pure.cloud", "wss://streaming.usw2.pure.cloud"
end

Rails.application.config.middleware.insert_after Browser::Middleware, EnrollMiddleware::RailsContentNonceRewrite