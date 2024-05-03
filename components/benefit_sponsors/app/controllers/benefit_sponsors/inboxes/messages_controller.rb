# frozen_string_literal: true

module BenefitSponsors
  module Inboxes
    # Needs to explictly inherit from BenefitSponsors::ApplicationController, or won't have access to authorize method
    class MessagesController < BenefitSponsors::ApplicationController
      before_action :authenticate_user!
      before_action :set_current_user
      before_action :find_inbox_provider
      before_action :find_message
      before_action :set_sent_box, if: :is_broker?

      # Shows an inbox message.
      # The id passed in is not the message id but the person id or profile id.
      # The message id is passed in as message_id.
      # The implementation is so that the messages of a BrokerAgencyProfile are attached to the person
      # who is the primary broker of the agency and not the agency itself.
      # This method checks if the user has the necessary permissions to view the message and then displays it.
      # If a url is passed in the parameters, it is stored in the @inbox_url instance variable.
      #
      # @note This method is used in the show action of the messages controller.
      # @note The authorization checks are performed using the BenefitSponsors::PersonPolicy policy.
      #
      # @return [HTML, JS] The inbox message is displayed in HTML format.
      def show
        if is_broker?
          authorize @inbox_provider, :show_inbox_message?, policy_class: BenefitSponsors::PersonPolicy
        elsif @inbox_provider.instance_of?(Person)
          authorize @inbox_provider, :can_read_inbox?, policy_class: BenefitSponsors::PersonPolicy
        else
          authorize @inbox_provider, :can_read_inbox?
        end
        BenefitSponsors::Services::MessageService.for_show(@message, @current_user)
        respond_to do |format|
          format.html
          format.js
        end
      end

      # Destroys an inbox message.
      # The id passed in is not the message id but the person id or profile id.
      # The message id is passed in as message_id.
      # The implementation is so that the messages of a BrokerAgencyProfile are attached to the person
      # who is the primary broker of the agency and not the agency itself.
      # This method checks if the user has the necessary permissions to destroy the message and then destroys it.
      # A success message is displayed to the user after the message is destroyed.
      # If a url is passed in the parameters, it is stored in the @inbox_url instance variable.
      #
      # @note This method is used in the destroy action of the messages controller.
      # @note The authorization checks are performed using the BenefitSponsors::PersonPolicy policy.
      def destroy
        if is_broker?
          authorize @inbox_provider, :destroy_inbox_message?, policy_class: BenefitSponsors::PersonPolicy
        elsif @inbox_provider.instance_of?(Person)
          authorize @inbox_provider, :can_read_inbox?, policy_class: BenefitSponsors::PersonPolicy
        else
          authorize @inbox_provider, :can_read_inbox?
        end
        BenefitSponsors::Services::MessageService.for_destroy(@message)
        flash[:notice] = "Successfully deleted inbox message."
        if params[:url].present?
          @inbox_url = params[:url]
        end
      end

      private

      def set_current_user
        @current_user = current_user
      end

      def set_sent_box
        @sent_box = true
      end

      def is_broker?
        return (@inbox_provider.class.to_s == "Person") && (/.*BrokerAgencyProfile$/.match(@inbox_provider.broker_role.broker_agency_profile._type))
      end

      def find_inbox_provider
        person = Person.where(id: params["id"])

        if person.present? && person.first.broker_role.present?
          @inbox_provider = person.first
        elsif find_profile.present?
          @inbox_provider = find_profile
          @inbox_provider_name = @inbox_provider.legal_name if /.*EmployerProfile$/.match(@inbox_provider._type) || /.*GeneralAgencyProfile$/.match(@inbox_provider._type)
        end
      end

      def find_profile
        @profile = BenefitSponsors::Organizations::Profile.find(params["id"])
      end

      def find_message
        @message = @inbox_provider.inbox.messages.by_message_id(params["message_id"]).to_a.first
      end
    end
  end
end
