# frozen_string_literal: true

module Insured
  # controller for fdsh ridp H139 feature
  class FdshRidpVerificationsController < ApplicationController
    layout 'progress' if EnrollRegistry.feature_enabled?(:bs4_consumer_flow)

    before_action :set_bs4_layout if EnrollRegistry.feature_enabled?(:bs4_consumer_flow)
    before_action :set_current_person
    before_action :set_cache_headers, only: [:failed_validation]
    before_action :set_consumer_bookmark_url, only: [:service_unavailable, :failed_validation]

    def new
      authorize @person, :complete_ridp?
      result = Operations::Fdsh::Ridp::RequestPrimaryDetermination.new.call(@person.primary_family)

      if result.success?
        redirect_to wait_for_primary_response_insured_fdsh_ridp_verifications_path
      else
        respond_to do |format|
          format.html { redirect_to :action => "service_unavailable" }
        end
      end
    end

    def wait_for_primary_response
      authorize @person, :complete_ridp?
      respond_to :html
    end

    def wait_for_secondary_response
      authorize @person, :complete_ridp?
      respond_to :html
    end

    def primary_response
      authorize @person, :complete_ridp?
      response = find_response('primary')

      if response.present?
        payload = response.serializable_hash.deep_symbolize_keys[:ridp_eligibility][:event]
        result = Operations::Fdsh::Ridp::PrimaryResponseToInteractiveVerification.new.call(payload)
        if result.success?
          @interactive_verification = result.value!
          respond_to do |format|
            format.html { render :primary_response }
          end
        else
          @step = ["RF1", "RF2"].include?(final_secision_code(payload)) ? 'questions' : 'start'
          redirect_to :action => "failed_validation", :step => @step, :verification_transaction_id => transaction_id(payload, 'primary_response') || session_identification_id(payload)
        end
      else
        redirect_to :action => "service_unavailable"
      end
    end

    def secondary_response
      authorize @person, :complete_ridp?
      response = find_response('secondary')
      if response.present?
        response_hash = response.serializable_hash.deep_symbolize_keys
        status = response_hash.dig(:ridp_eligibility, :event, :attestations, :ridp_attestation, :status)
        payload = response_hash.dig(:ridp_eligibility, :event)
        if status == 'success'
          response_metadata = payload.dig(:attestations, :ridp_attestation, :evidences, 0, :secondary_response, :Response)
          process_successful_interactive_verification(response_metadata)
        else
          @step = 'questions'
          redirect_to :action => "failed_validation", :step => @step, :verification_transaction_id => transaction_id(payload, 'secondary_response') || session_identification_id(payload)
        end
      else
        redirect_to :action => "service_unavailable"
      end
    end

    def create
      authorize @person, :complete_ridp?
      @interactive_verification = ::IdentityVerification::InteractiveVerification.new(
        params.require(:interactive_verification).permit(:session_id, :transaction_id, questions_attributes: {}).to_h
      )

      if @interactive_verification.valid?
        result = Operations::Fdsh::Ridp::RequestSecondaryDetermination.new.call(@person.primary_family, @interactive_verification)

        if result.success?
          redirect_to wait_for_secondary_response_insured_fdsh_ridp_verifications_path
        else
          redirect_to :action => "service_unavailable"
        end
      else
        respond_to do |format|
          format.html { render "new" }
        end
      end
    end

    def check_primary_response_received
      authorize @person, :complete_ridp?
      result = received_response('primary')
      respond_to do |format|
        format.js { render :plain => result.success? }
      end
    end

    def check_secondary_response_received
      authorize @person, :complete_ridp?
      result = received_response('secondary')
      respond_to do |format|
        format.js { render :plain => result.success? }
      end
    end

    def service_unavailable
      authorize @person, :complete_ridp?
      @person.consumer_role.move_identity_documents_to_outstanding

      respond_to do |format|
        format.html { render "service_unavailable" }
      end
    end

    def failed_validation
      @person = Person.find(params[:person_id]) if params[:person_id].present?
      authorize @person, :complete_ridp?

      @step = params[:step]
      @verification_transaction_id = params[:verification_transaction_id]
      @person.consumer_role.move_identity_documents_to_outstanding

      respond_to do |format|
        format.html { render "failed_validation" }
      end
    end

    private

    def received_response(event_kind)
      find_params = {primary_member_hbx_id: @person.primary_family.primary_applicant.hbx_id, event_kind: event_kind}
      Operations::Fdsh::Ridp::FindEligibilityResponse.new.call(find_params)
    end

    def find_response(event_kind)
      primary_member_hbx_id = @person.primary_family.primary_applicant.hbx_id
      ::Fdsh::Ridp::EligibilityResponseModel.where(event_kind: event_kind, primary_member_hbx_id: primary_member_hbx_id, :deleted_at.ne => nil).to_a.max_by(&:deleted_at)
    end

    def session_identification_id(response)
      response.dig(:attestations, :ridp_attestation, :evidences, 0, :primary_response, :Response, :VerificationResponse, :SessionIdentification)
    end

    def transaction_id(response, response_kind)
      response.dig(:attestations, :ridp_attestation, :evidences, 0, response_kind.to_sym, :Response, :VerificationResponse, :DSHReferenceNumber)
    end

    def final_secision_code(response)
      response.dig(:attestations, :ridp_attestation, :evidences, 0, :primary_response, :Response, :VerificationResponse, :FinalDecisionCode)
    end

    def process_successful_interactive_verification(response)
      consumer_role = @person.consumer_role
      consumer_user = @person.user
      if consumer_user
        consumer_user.identity_final_decision_code = User::INTERACTIVE_IDENTITY_VERIFICATION_SUCCESS_CODE
        consumer_user.identity_response_code = User::INTERACTIVE_IDENTITY_VERIFICATION_SUCCESS_CODE
        consumer_user.identity_response_description_text = response[:ResponseMetadata][:TDSResponseDescriptionText]
        consumer_user.identity_final_decision_transaction_id = response[:VerificationResponse][:DSHReferenceNumber] || response[:VerificationResponse][:SessionIdentification]
        consumer_user.identity_verified_date = TimeKeeper.date_of_record
        consumer_user.save!
      end
      consumer_role.move_identity_documents_to_verified
      consumer_redirection_path = insured_family_members_path(:consumer_role_id => consumer_role.id)
      consumer_redirection_path = help_paying_coverage_insured_consumer_role_index_path if EnrollRegistry.feature_enabled?(:financial_assistance)
      redirect_to consumer_role.admin_bookmark_url.present? ? consumer_role.admin_bookmark_url : consumer_redirection_path
    end

    private

    def set_bs4_layout
      @bs4 = true
    end
  end
end
