module Insured
  class FdshRidpController < ApplicationController
    before_action :set_current_person

    def new
      result = Operations::Fdsh::Ridp::RequestPrimaryDetermination.new.call(@person.primary_family)

      if result.success?
        redirect_to wait_for_primary_response_insured_fdsh_ridp_index_path
      else 
        redirect_to :action => "service_unavailable"
      end
    end

    def wait_for_primary_response
    end

    def wait_for_secondary_response
      @family = @person.primary_family 
    end

    def service_unavailable
      set_consumer_bookmark_url
      @person.consumer_role.move_identity_documents_to_outstanding
      render "service_unavailable"
    end

    def primary_response
      # find_params = {primary_member_hbx_id: @person.primary_family.primary_applicant.hbx_id, event_kind: 'primary'}
      # Operations::FindRidpEligibilityResponse.new.call(find_params).value!
    end

    def failed_validation
      set_consumer_bookmark_url
      @step = params[:step]
      @verification_transaction_id = params[:verification_transaction_id]
      @person.consumer_role.move_identity_documents_to_outstanding
      render "failed_validation"
    end

    def create
      @interactive_verification = ::IdentityVerification::InteractiveVerification.new(
        params.require(:interactive_verification).permit(:session_id, :transaction_id, questions_attributes: {}).to_h
      )
      respond_to do |format|
        format.html do
          if @interactive_verification.valid?

            result = Operations::Fdsh::Ridp::RequestSecondaryDetermination.new.call(@person.primary_family, @interactive_verification)
            # service = ::IdentityVerification::InteractiveVerificationService.new
            # service_response = service.respond_to_questions(render_question_responses(@interactive_verification))
            # if service_response.blank?
            #   redirect_to :action => "service_unavailable"
            # else
            #   if service_response.successful?
            #     process_successful_interactive_verification(service_response)
            #   else
            #     @step = 'questions'
            #     @verification_response= service_response
            #     redirect_to :action => "failed_validation", :step => @step, :verification_transaction_id => @verification_response.transaction_id
            #   end
            # end
          else
            render "new"
          end
        end
      end
    end

    def update
      @transaction_id = params.require(:id)

      respond_to do |format|
        format.html do
            service = ::IdentityVerification::InteractiveVerificationService.new
            service_response = service.check_override(render_verification_override(@transaction_id))
            if service_response.blank?
              redirect_to :action => "service_unavailable"
            else
              if service_response.successful?
                process_successful_interactive_verification(service_response)
              else
                @verification_response = service_response
                redirect_to :action =>  "failed_validation", :verification_transaction_id => @verification_response.transaction_id
              end
            end
        end
      end
    end

    def check_primary_response_received
      primary_fm = @person.primary_family.primary_applicant
      render :plain => false unless primary_fm
      if primary_fm
        record = Operations::FindRidpEligibilityResponse.new.call()
        # Fdsh::Ridp::RidpResponseServiceModel.where(primary_member_hbx_id: primary_fm.hbx_id, event_kind: 'primary').max_by(&:updated_at)
        render :plain => record.success?
      end
    end

    def check_secondary_response_received
      primary_fm = @person.primary_family.primary_applicant
      render :plain => false unless primary_fm
      if primary_fm
        record = Operations::FindRidpEligibilityResponse.new.call()
        # record = Fdsh::Ridp::RidpResponseServiceModel.where(primary_member_hbx_id: primary_fm.hbx_id, event_kind: 'primary').max_by(&:updated_at)
        render :plain => record.success?
      end
    end

    def process_successful_interactive_verification(service_response)
      consumer_role = @person.consumer_role
      consumer_user = @person.user
      #TODO TREY KEVIN JIM There is no user when CSR creates enroooment
      if consumer_user
        consumer_user.identity_final_decision_code = User::INTERACTIVE_IDENTITY_VERIFICATION_SUCCESS_CODE
        consumer_user.identity_response_code = User::INTERACTIVE_IDENTITY_VERIFICATION_SUCCESS_CODE
        consumer_user.identity_response_description_text = service_response.response_text
        consumer_user.identity_final_decision_transaction_id = service_response.transaction_id
        consumer_user.identity_verified_date = TimeKeeper.date_of_record
        consumer_user.save!
      end
      consumer_role.move_identity_documents_to_verified
      consumer_redirection_path = insured_family_members_path(:consumer_role_id => consumer_role.id)
      consumer_redirection_path = help_paying_coverage_insured_consumer_role_index_path if EnrollRegistry.feature_enabled?(:financial_assistance)
      redirect_to consumer_role.admin_bookmark_url.present? ? consumer_role.admin_bookmark_url : consumer_redirection_path
    end
  end
end
