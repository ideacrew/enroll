module BenefitSponsors
  module Organizations
    class AcaShopDcEmployerProfile < BenefitSponsors::Organizations::Profile
      # include BenefitSponsors::Employers::EmployerHelper
      include BenefitSponsors::Concerns::EmployerProfileConcern


      def rating_area
        # FIX this
      end

      def sic_code
        # Fix this
      end

      def broker_agency_profile
        # organization.active_benefit_sponsorship.present? ? organization.active_benefit_sponsorship.active_broker_agency_account.broker_agency_profile : nil
      end

      def active_broker
        # if active_broker_agency_account && active_broker_agency_account.writing_agent_id
        #   Person.where("broker_role._id" => BSON::ObjectId.from_string(active_broker_agency_account.writing_agent_id)).first
        # end
      end

      def census_employees
        CensusEmployee.find_by_employer_profile(self)
      end

      def staff_roles #managing profile staff
        staff_for_benefit_sponsors_employer(self)
      end

      private

      def initialize_profile
        return unless is_benefit_sponsorship_eligible.blank?

        write_attribute(:is_benefit_sponsorship_eligible, true)
        @is_benefit_sponsorship_eligible = true
        self
      end

      def build_nested_models
        return if inbox.present?
        build_inbox
        #TODO: After migration uncomment the lines below to get Welcome message for Initial Inbox creation
        # welcome_subject = "Welcome to #{Settings.site.short_name}"
        # welcome_body = "#{Settings.site.short_name} is the #{Settings.aca.state_name}'s online marketplace where benefit sponsors may select and offer products that meet their member's needs and budget."
        # inbox.messages.new(subject: welcome_subject, body: welcome_body)
      end
    end
  end
end
