module BenefitSponsors
  module Services
    class BrokerManagementService

      def assign_agencies(form)
        assign_agencies_for_employer(form)
      end

      def terminate_agencies(form)
        terminate_agencies_for_employer(form)
      end

      private

      def terminate_agencies_for_employer(form)
        @employer_profile = BenefitSponsors::Organizations::Profile.find(form.employer_profile_id)
        if form.termination_date
          @employer_profile.fire_broker_agency(form.termination_date)
          #TODO fix this during GA's implementation
          # @employer_profile.fire_general_agency!(termination_date)
          @employer_profile.save!
          return true
        else
          return false
        end
      end

      def assign_agencies_for_employer(form)
        @employer_profile = BenefitSponsors::Organizations::Profile.find(form.employer_profile_id)
        assign_broker_agency_for_emp(form.broker_agency_profile_id, form.broker_role_id)
        # # TODO fix this during GA's implementation
        # assign_general_agency_for_employer(form)
        # # TODO fix this during notices implementation
        # send_notices_associated_to_employer_profile
      end

      def send_notification(broker_role_id)
        begin
          invitation = BenefitSponsors::Services::InvitationEmails.new({broker_role_id: broker_role_id, employer_profile: @employer_profile})
          invitation.send_broker_successfully_associated_email
        rescue Exception => e
          puts e.inspect
          puts e.backtrace
        end
      end
      #
      # def get_bson_id(id)
      #   BSON::ObjectId.from_string(id)
      # end

      def assign_broker_agency_for_emp(broker_agency_profile_id, broker_role_id)
        broker_agency_profile = BenefitSponsors::Organizations::BrokerAgencyProfile.find(get_bson_id(broker_agency_profile_id))
        @employer_profile.broker_role_id = broker_role_id
        @employer_profile.hire_broker_agency(broker_agency_profile)
        @employer_profile.save!
        send_notification(broker_role_id)
      end

      # def send_broker_successfully_associated_email broker_role_id
      #   broker_person = Person.where(:'broker_role._id' => get_bson_id(broker_role_id)).first
      #   body = "You have been selected as a broker by #{@employer_profile.legal_name}"
      #
      #   message_params = {
      #     sender_id: @employer_profile.try(:id),
      #     parent_message_id: broker_person.id,
      #     from: @employer_profile.try(:legal_name),
      #     to: broker_person.try(:full_name),
      #     body: body,
      #     subject: 'You have been select as the Broker'
      #   }
      #
      #   create_secure_message(message_params, broker_person, :inbox)
      # end
      #
      # def create_secure_message(message_params, inbox_provider, folder)
      #   message = Message.new(message_params)
      #   message.folder =  Message::FOLDER_TYPES[folder]
      #   msg_box = inbox_provider.inbox
      #   msg_box.post_message(message)
      #   msg_box.save
      # end
    end
  end
end