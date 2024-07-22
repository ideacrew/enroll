# frozen_string_literal: true

# rubocop:disable all

module FinancialAssistance
  module VerificationHelper
    include HtmlScrubberUtil

    def fetch_latest_determined_application(family_id)
      FinancialAssistance::Application.where(family_id: family_id).determined.order_by(:created_at => 'desc').first
    end

    def show_verification_status(status, admin = nil)
      status = "verified" if status == "valid"
      sanitize_html((status || '').titleize.center(12).gsub(' ', '&nbsp;'))
    end

    def admin_verification_action(admin_action, evidence, update_reason)
      evidence.update(update_reason: update_reason, updated_by: current_user.oim_id)
      evidence.verification_histories << create_verification_history(admin_action, update_reason)
      applicant = evidence.evidenceable

      case admin_action
      when "verify"
        applicant.set_evidence_verified(evidence)
        "#{evidence.title} successfully verified."
      when "return_for_deficiency"
        # applicant.set_evidence_outstanding(evidence)
        applicant.set_evidence_rejected(evidence)
        "#{evidence.title} rejected."
      end
    end

    def create_verification_history(admin_action, update_reason)
      Eligibilities::VerificationHistory.new(action: admin_action, update_reason: update_reason, updated_by: current_user.oim_id)
    end

    def admin_actions_on_faa_documents(evidence)
      options_for_select(build_actions_list(evidence))
    end

    def display_upload_for_evidence?(evidence)
      evidence.type_unverified?
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
      default_class = @bs4 ? "absent" : "default"
      case status
      when "verified", "valid"
        "success"
      when "review", "negative_response_received"
        "warning"
      when "outstanding", "rejected"
        "danger"
      when "curam", "attested", "expired", "unverified"
        default_class
      when "pending"
        "info"
      else
        default_class
      end
    end
  end
end