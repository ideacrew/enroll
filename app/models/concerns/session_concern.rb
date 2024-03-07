# frozen_string_literal: true

# Concern to fetch session and user
module SessionConcern
  extend ActiveSupport::Concern

  included do
    def current_user
      Thread.current[:current_user]
    end

    def session
      keys_to_extract = ["portal", "warden.user.user.session", "login_token", "session_id"]
      session_values = Thread.current[:current_session_values]&.slice(*keys_to_extract) || {}
      session_values[:login_session_id] = Thread.current[:login_session_id] if Thread.current[:login_session_id].present?
      session_values
    end

    def system_account
      system_email = EnrollRegistry[:aca_event_logging].setting(:system_account_email)&.item
      @system_account ||= User.find_by(email: system_email) if system_email
    end
  end
end
