# frozen_string_literal: true

# rubocop:disable all

module FinancialAssistance
  module VerificationHelper

    def fetch_latest_determined_application(family_id)
      FinancialAssistance::Application.where(family_id: family_id).determined.order_by(:created_at => 'desc').first
    end

    def show_verification_status(status, admin = nil)
      status = "verified" if status == "valid"
      (status || '').capitalize.center(12).gsub(' ', '&nbsp;').html_safe
    end

    def admin_verification_action(admin_action, evidence, update_reason)
      evidence.update(update_reason: update_reason, updated_by: current_user.oim_id)
      evidence.verification_histories << create_verification_history(admin_action, update_reason)
      case admin_action
      when "verify"
        evidence.move_to_verified!
        evidence.update!(is_satisfied: true, verification_outstanding: false)
        "#{evidence.title} successfully verified."
      when "return_for_deficiency"
        evidence.move_to_outstanding!
        evidence.update!(is_satisfied: false, verification_outstanding: true)
        "#{evidence.title} rejected."
      end
    end

    def create_verification_history(admin_action, update_reason)
      Eligibilities::VerificationHistory.new(action: admin_action, update_reason: update_reason, updated_by: current_user.oim_id)
    end

    def admin_actions_on_faa_documents(evidence)
      options_for_select(build_actions_list(evidence))
    end

    def build_actions_list(evidence)
      if evidence.aasm_state == "outstanding"
        Eligibilities::Evidence::ADMIN_VERIFICATION_ACTIONS.reject{|el| el == "Reject" }
      else
        Eligibilities::Evidence::ADMIN_VERIFICATION_ACTIONS
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
      when "Local MEC"
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