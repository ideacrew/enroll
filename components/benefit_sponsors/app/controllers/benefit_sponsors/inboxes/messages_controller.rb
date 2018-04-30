module BenefitSponsors
  module Inboxes
    class MessagesController < ApplicationController
      before_action :set_current_user
      before_action :find_inbox_provider, except: [:msg_to_portal]
      before_action :find_message
      before_action :set_sent_box, only: [:show, :destroy], if: :is_broker?
      before_action :find_organization ,only: [:msg_to_portal]

      def new
        #TODO: fix it -- if needed
      end

      def create
        #TODO: fix it -- if needed
      end

      def show
        BenefitSponsors::Services::MessageService.for_show(@message, @current_user)
        respond_to do |format|
          format.html
          format.js
        end
      end

      def destroy
        BenefitSponsors::Services::MessageService.for_destroy(@message)
        flash[:notice] = "Successfully deleted inbox message."
        if params[:url].present?
          @inbox_url = params[:url]
        end
      end

      def msg_to_portal
        @broker_agency_provider = @organizations.first.broker_agency_profile if @organizations.present?
        @inbox_provider = @broker_agency_provider
        @inbox_provider_name = @inbox_provider.try(:legal_name)
        @inbox_to_name = "HBX Admin"
        log("#3969 and #3985 params: #{params.to_s}, request: #{request.env.inspect}", {:severity => "error"}) if @inbox_provider.blank?
        @new_message = @inbox_provider.inbox.messages.build
      end

      private

      def set_current_user
        @current_user = current_user
      end

      def set_sent_box
        @sent_box = true
      end

      def is_broker?
        return (current_user.person == @inbox_provider) || /.*BrokerAgencyProfile$/.match(@inbox_provider._type)
      end

      def find_inbox_provider
        id = params["id"]||params['profile_id']
        if current_user.person._id.to_s == id
          @inbox_provider = current_user.person
        else
          organizations = find_organization
          @inbox_provider = organizations.first.profiles.first
          @inbox_provider_name = @inbox_provider.legal_name if /.*EmployerProfile$/.match(@inbox_provider._type)
        end
      end

      def find_organization
        @organizations = BenefitSponsors::Organizations::Organization.where(:"profiles._id" => BSON::ObjectId.from_string(params["id"]||params['profile_id']))
      end

      def find_message
        @message = @inbox_provider.inbox.messages.by_message_id(params["message_id"]).to_a.first
      end

      def set_inbox_and_assign_message
        #TODO fix it when create action is implemented
      end

      def successful_save_path
        #TODO fix it when create action is implemented
      end
    end
  end
end
