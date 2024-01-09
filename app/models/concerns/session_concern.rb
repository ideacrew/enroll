# frozen_string_literal: true

# Concern to fetch session and user
module SessionConcern
  extend ActiveSupport::Concern

  included do
    def current_user
      Thread.current[:current_user]
    end

    def session
      session_values = Thread.current[:current_session_values] || {}
      session_values[:login_session_id] = Thread.current[:login_session_id] if Thread.current[:login_session_id].present?
      session_values
    end

    def system_account
      @system_account ||= User.find_by(email: "admin@dc.gov")
    end
  end
end
