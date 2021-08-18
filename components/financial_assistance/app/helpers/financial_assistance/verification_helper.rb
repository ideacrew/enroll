# frozen_string_literal: true

# rubocop:disable all

module FinancialAssistance
  module VerificationHelper

    def fetch_latest_determined_application(family_id)
      FinancialAssistance::Application.where(family_id: family_id).submitted.order_by(:created_at => 'desc').first
    end

    def show_verification_status(status, admin = nil)
      status = "verified" if status == "valid"
      status.capitalize.center(12).gsub(' ', '&nbsp;').html_safe
    end

    def verification_status_class(status)
      case status
      when "verified"
        "success"
      when "review"
        "warning"
      when "outstanding"
        "danger"
      when "curam"
        "default"
      when "attested"
        "default"
      when "valid"
        "success"
      when "pending"
        "info"
      when "expired"
        "default"
      when "unverified"
        "default"
      end
    end
  end
end