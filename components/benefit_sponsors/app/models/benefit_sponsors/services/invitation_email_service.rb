module BenefitSponsors
  module Services
    class InvitationEmailService
      include ::L10nHelper

      attr_accessor :broker_role_id, :employer_profile, :broker_agency_profile_id

      def initialize(params={})
        @broker_role_id = params[:broker_role_id]
        @employer_profile = params[:employer_profile]
        @broker_agency_profile_id = params[:broker_agency_profile_id]
      end

      def send_broker_successfully_associated_email
        broker_person = Person.where(:'broker_role._id' => get_bson_id(broker_role_id)).first
        body = "You have been selected as a broker by #{employer_profile.legal_name}"

        message_params = {
            sender_id: employer_profile.try(:id),
            parent_message_id: broker_person.id,
            from: employer_profile.try(:legal_name),
            to: broker_person.try(:full_name),
            body: body,
            subject: 'You have been select as the Broker'
        }

        create_secure_message(message_params, broker_person, :inbox)
      end

      def send_general_agency_successfully_associated_email
        broker_agency_profile = BenefitSponsors::Organizations::BrokerAgencyProfile.find(get_bson_id(broker_agency_profile_id))
        general_agency = broker_agency_profile.default_general_agency_profile
        subject = l10n("employers.broker_agency_notice.subject", broker_legal_name: broker_agency_profile.organization.legal_name, agency_legal_name: general_agency.legal_name)
        body = l10n("employers.broker_agency_notice.body", agency_legal_name: general_agency.legal_name, employer_legal_name: employer_profile.legal_name)
        secure_message(broker_agency_profile, general_agency, subject, body)
        secure_message(broker_agency_profile, employer_profile, subject, body)
      end

      def create_secure_message(message_params, inbox_provider, folder)
        message = Message.new(message_params)
        message.folder =  Message::FOLDER_TYPES[folder]
        msg_box = inbox_provider.inbox
        msg_box.post_message(message)
        msg_box.save
      end

      def secure_message(from_provider, to_provider, subject, body)
        message_params = {
          sender_id: from_provider.id,
          parent_message_id: to_provider.id,
          from: from_provider.legal_name,
          to: to_provider.legal_name,
          subject: subject,
          body: body
        }

        create_secure_message(message_params, to_provider, :inbox)
        create_secure_message(message_params, from_provider, :sent)
      end

      def get_bson_id(id)
        BSON::ObjectId.from_string(id)
      end

    end

  end
end
