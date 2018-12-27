module BenefitSponsors
  module Services
    class BrokerManagementService

      def assign_agencies(form)
        assign_agencies_for_employer(form)
      end

      def terminate_agencies(form)
        terminate_agencies_for_employer(form)
      end

      def set_default_ga(form, current_user)
        @broker_agency_profile = ::BenefitSponsors::Organizations::BrokerAgencyProfile.find(form.broker_agency_profile_id)
        @general_agency_profile = BenefitSponsors::Organizations::GeneralAgencyProfile.find(form.general_agency_profile_id) rescue nil
        if @broker_agency_profile.present?
          old_default_ga_id = @broker_agency_profile.default_general_agency_profile.id.to_s rescue nil
          if form.type == 'clear'
            @broker_agency_profile.default_general_agency_profile = nil
          elsif @general_agency_profile.present?
            @broker_agency_profile.default_general_agency_profile = @general_agency_profile
            # @broker_agency_profile.employer_clients.each do |employer_profile|
            #   @general_agency_profile.general_agency_hired_notice(employer_profile) # GA notice when broker selects a default GA
            # end
          end
          @broker_agency_profile.save
          # notify("acapi.info.events.broker.default_ga_changed", {:broker_id => @broker_agency_profile.primary_broker_role.hbx_id, :pre_default_ga_id => old_default_ga_id})
          @notice = "Changing default general agencies may take a few minutes to update all employers."

          @broker_role = current_user.person.broker_role || nil
          @general_agency_profiles = BenefitSponsors::Organizations::GeneralAgencyProfile.all_by_broker_role(@broker_role, approved_only: true)
        end

        form.broker_agency_profile = @broker_agency_profile
        form.general_agency_profiles = @general_agency_profiles
        form.notice = @notice
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
          invitation = BenefitSponsors::Services::InvitationEmailService.new({broker_role_id: broker_role_id, employer_profile: @employer_profile})
          invitation.send_broker_successfully_associated_email
        rescue Exception => e
          puts e.inspect
          puts e.backtrace
        end
      end

      def get_bson_id(id)
        BSON::ObjectId.from_string(id)
      end

      def assign_broker_agency_for_emp(broker_agency_profile_id, broker_role_id)
        broker_agency_profile = BenefitSponsors::Organizations::BrokerAgencyProfile.find(get_bson_id(broker_agency_profile_id))
        @employer_profile.broker_role_id = broker_role_id
        @employer_profile.hire_broker_agency(broker_agency_profile)
        @employer_profile.save!
        send_notification(broker_role_id)
      end

    end
  end
end
