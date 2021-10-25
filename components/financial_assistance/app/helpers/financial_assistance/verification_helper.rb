# frozen_string_literal: true

# rubocop:disable all

module FinancialAssistance
  module VerificationHelper

    def fetch_latest_determined_application(family_id)
      FinancialAssistance::Application.where(family_id: family_id).determined.order_by(:created_at => 'desc').first
    end

    def show_verification_status(status, admin = nil)
      status = "verified" if status == "valid"
      status.capitalize.center(12).gsub(' ', '&nbsp;').html_safe
    end

    def admin_verification_action(admin_action, evidence, update_reason)
      case admin_action
      when "verify"
        evidence.update!(eligibility_status: 'verified', update_reason: update_reason)
      when "return_for_deficiency"
        evidence.update!(eligibility_status: 'outstanding', update_reason: update_reason, rejected: true)
      end
    end

    def admin_actions_on_faa_documents(evidence)
      options_for_select(build_actions_list(evidence))
    end

    def build_actions_list(evidence)
      if evidence.eligibility_status == "outstanding"
        FinancialAssistance::Document::ADMIN_VERIFICATION_ACTIONS.reject{|el| el == "Reject" }
      else
        FinancialAssistance::Document::ADMIN_VERIFICATION_ACTIONS
      end
    end

    def env_bucket_name(bucket_name)
      aws_env = ENV['AWS_ENV'] || "qa"
      subdomain = EnrollRegistry[:enroll_app].setting(:subdomain).item
      "#{subdomain}-enroll-#{bucket_name}-#{aws_env}"
    end

    def display_evidence_type(evidence)
      case evidence
      when "ESI MEC"
        "faa.evidence_type_esi"
      when "ACES MEC"
        "faa.evidence_type_aces"
      when "Non ESI MEC"
        "faa.evidence_type_non_esi"
      when "Income"
        "faa.evidence_type_income"
      end
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