# frozen_string_literal: true

module FinancialAssistance
  # controller for evidencces
  class EvidencesController < FinancialAssistance::ApplicationController
    include ApplicationHelper
    include VerificationHelper

    before_action :fetch_applicant
    before_action :updateable?, :find_type

    def update_evidence
      update_reason = params[:verification_reason]
      admin_action = params[:admin_action]
      reasons_list = FinancialAssistance::Evidence::VERIFY_REASONS + FinancialAssistance::Evidence::REJECT_REASONS
      if reasons_list.include?(update_reason)
        verification_result = admin_verification_action(admin_action, @evidence, update_reason)
        message = (verification_result.is_a? String) ? verification_result : "Verification successfully approved."
        flash[:success] = message
        # update_documents_status(@applicant) if @applicant
      else
        flash[:error] = "Please provide a verification reason."
      end

      redirect_to main_app.verification_insured_families_path
    end

    def fdsh_hub_request
      result = @evidence.request_determination(params[:admin_action], "Requested Hub for verification", current_user.oim_id)

      if result
        @evidence.move_to_pending!
        key = :success
        message = "request submited successfully"
      else
        key = :error
        message = "unable to submited request"
      end

      respond_to do |format|
        format.html do
          flash[key] = message
          redirect_back(fallback_location: main_app.verification_insured_families_path)
        end
        format.js
      end
    end

    def extend_due_date
      @family_member = FamilyMember.find(@evidence.evidenceable.family_member_id)
      enrollment = @family_member.family.enrollments.enrolled.first
      if enrollment.present? && @evidence.type_unverified?
        @evidence.extend_due_date(30.days, current_user.oim_id)

        if updated
          flash[:success] = "#{@evidence.title} verification due date was extended for 30 days."
        end
      else
        flash[:danger] = "Applicant doesn't have active Enrollment to extend verification due date."
      end
      redirect_back(fallback_location: main_app.verification_insured_families_path)
    end

    private

    def updateable?
      authorize ::Family, :updateable?
    end

    def find_docs_owner
      @docs_owner = ::FinancialAssistance::Applicant.find(params[:applicant_id]) if params[:applicant_id]
    end

    def find_type
      fetch_applicant
      find_docs_owner
      @evidence = @docs_owner.send(params[:evidence_kind]) if @docs_owner.respond_to?(params[:evidence_kind])
    end

    def update_documents_status(applicant)
      family = applicant.family
      family.update_family_document_status!
    end

    def fetch_applicant_succeeded?
      return true if @applicant
      message = {}
      message[:message] = 'Application Exception - applicant required'
      message[:session_person_id] = session[:person_id]
      message[:user_id] = current_user.id
      message[:oim_id] = current_user.oim_id
      message[:url] = request.original_url
      log(message, :severity => 'error')
      false
    end

    def fetch_applicant
      @applicant = if params[:applicant_id]
                     FinancialAssistance::Applicant.find(params[:applicant_id])
                   elsif current_user.try(:person).try(:agent?) && session[:person_id].present?
                     FinancialAssistance::Applicant.find(session[:person_id])
                   end

      redirect_to maain_app.logout_saml_index_path unless fetch_applicant_succeeded?
    end
  end
end