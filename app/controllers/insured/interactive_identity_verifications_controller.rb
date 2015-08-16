module Insured
  class InteractiveIdentityVerificationsController < ApplicationController
    before_action :set_current_person

    def new
      service = ::IdentityVerification::InteractiveVerificationService.new
      service_response = service.initiate_session(render_session_start)
      respond_to do |format|
        format.html do
          if service_response.blank?
            render "service_unavailable"
          else
            if service_response.failed?
              @verification_response = service_response
              render "failed_validation" 
            else
              @interactive_verification = service_response.to_model
              render :new
            end
          end
        end
      end
    end

    def create
      @interactive_verification = ::IdentityVerification::InteractiveVerification.new(params.require(:interactive_verification).permit!)
      respond_to do |format|
        format.html do
          if @interactive_verification.valid?
            service = ::IdentityVerification::InteractiveVerificationService.new
            service_response = service.respond_to_questions(render_question_responses(@interactive_verification))
            if service_response.blank?
              render "service_unavailable"
            else
              if service_response.successful?
                process_successful_interactive_verification(@interactive_verification, service_response)
              else
                @verification_response = service_response
                render "failed_validation" 
              end
            end
          else
            render "new"
          end
        end
      end
    end

    def process_successful_interactive_verification(interactive_verification, service_response)
      consumer_role = @person.consumer_role
      consumer_role.identity_final_decision_code = ConsumerRole::INTERACTIVE_IDENTITY_VERIFICATION_SUCCESS_CODE
      consumer_role.identity_response_code = ConsumerRole::INTERACTIVE_IDENTITY_VERIFICATION_SUCCESS_CODE
      consumer_role.identity_response_description_text = service_response.response_text
      consumer_role.identity_final_decision_transaction_id = service_response.transaction_id
      consumer_role.identity_verified_date = Date.today
      consumer_role.verify_identity!
      redirect_to consumer_employee_dependents_path(consumer_role_id: consumer_role.id, type: "consumer")
    end

    def render_session_start
      render_to_string "events/identity_verification/interactive_session_start", :formats => ["xml"], :locals => { :individual => @person }
    end

    def render_question_responses(session)
      render_to_string "events/identity_verification/interactive_questions_response", :formats => ["xml"], :locals => { :session => session }
    end
  end
end
