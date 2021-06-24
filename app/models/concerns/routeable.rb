# frozen_string_literal: true

# For use of URL helpers in certain contexts
module Routeable
  extend ActiveSupport::Concern

  included do
    include Rails.application.routes.url_helpers
  end

  def default_url_options
    Rails.application.config.action_mailer.default_url_options
  end
end