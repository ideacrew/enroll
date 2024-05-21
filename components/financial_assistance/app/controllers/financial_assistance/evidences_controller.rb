# frozen_string_literal: true

module FinancialAssistance
  # controller for evidences
  class EvidencesController < FinancialAssistance::ApplicationController
    include ApplicationHelper
    include VerificationHelper

    before_action :fetch_applicant
    before_action :find_type

    def update_evidence
      authorize @applicant, :edit?
      update_reason = params[:verification_reason]
      admin_action = params[:admin_action]
      reasons_list = FinancialAssistance::Evidence::VERIFY_REASONS + FinancialAssistance::Evidence::REJECT_REASONS
      if reasons_list.include?(update_reason)
        verification_result = admin_verification_action(admin_action, @evidence, update_reason)
        message = (verification_result.is_a? String) ? verification_result : "Verification successfully approved."
        flash[:success] = message
      else
        flash[:error] = "Please provide a verification reason."
      end

      redirect_to main_app.verification_insured_families_path
    end

    def fdsh_hub_request
      authorize HbxProfile, :can_call_hub?
      result = @evidence.request_determination(params[:admin_action], "Requested Hub for verification", current_user.oim_id)

      if result
        key = :success
        message = "request submitted successfully"
      else
        key = :error
        message = "unable to submit request"
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
      authorize HbxProfile, :can_extend_due_date?
      @family_member = FamilyMember.find(@evidence.evidenceable.family_member_id)
      enrollment = @family_member.family.enrollments.enrolled.first
      if enrollment.present? && @evidence.type_unverified?
        if @evidence.extend_due_on(30.days, current_user.oim_id)
          flash[:success] = "#{@evidence.title} verification due date was extended for 30 days."
        else
          flash[:danger] = "Unable to extend due date"
        end
      else
        flash[:danger] = "Applicant doesn't have active Enrollment to extend verification due date."
      end
      redirect_back(fallback_location: main_app.verification_insured_families_path)
    end

    private

    def find_docs_owner
      @docs_owner = ::FinancialAssistance::Applicant.find(params[:applicant_id]) if params[:applicant_id]
    end

    def find_type
      authorize @applicant, :edit?
      fetch_applicant
      find_docs_owner
      # Here 'evidence kind' needs to be a singular association on
      # FinancialAssistance::Applicant which corresponds to something is, or
      # is a subclass of, FinancialAssistance::Evidence.
      # The options for what this can be are limited.
      # We should find a better way to do this, and probably limit the values
      # based on the model structure.
      return if @docs_owner.blank?
      return if params[:evidence_kind].blank?
      evidence_kind = params[:evidence_kind].to_s
      return unless ['income_evidence', 'esi_evidence', 'non_esi_evidence', 'local_mec_evidence'].include?(evidence_kind)
      @evidence = @docs_owner.fetch_evidence(evidence_kind)
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

      redirect_to main_app.logout_saml_index_path unless fetch_applicant_succeeded?
    end
  end
end