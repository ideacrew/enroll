module Insured
  class InteractiveIdentityVerificationsController < ApplicationController
    before_action :set_current_person

    def new
        service = ::IdentityVerification::InteractiveVerificationService.new
        service_response = service.initiate_session(render_session_start)
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

    def create
      @interactive_verification = ::IdentityVerification::InteractiveVerification.new(params.require(:interactive_verification).permit!)
      if @interactive_verification.valid?
        service = ::IdentityVerification::InteractiveVerificationService.new
        service_response = service.respond_to_questions(render_question_responses(@interactive_verification))
        if service_response.blank?
          render "service_unavailable"
        else
          if service_response.successful?
            process_successful_interactive_verification(@interactive_verification)
          else
            @verification_response = service_response
            render "failed_validation" 
          end
        end
      else
        render "new"
      end
    end

    def process_successful_interactive_verification(verification_response)
      redirect_to root_path
    end

    def render_session_start
      render_to_string "events/identity_verification/interactive_session_start", :formats => ["xml"], :locals => { :individual => @person }
    end

    def render_question_responses(session)
      render_to_string "events/identity_verification/interactive_questions_response", :formats => ["xml"], :locals => { :session => session }
    end
  end
end
