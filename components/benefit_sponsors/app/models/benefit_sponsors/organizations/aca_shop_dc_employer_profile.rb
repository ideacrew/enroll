module BenefitSponsors
  module Organizations
    class AcaShopDcEmployerProfile < BenefitSponsors::Organizations::Profile
      include BenefitSponsors::Employers::EmployerHelper
      include Concerns::EmployerProfileConcern


      def rating_area
        # FIX this
      end

      def sic_code
        # Fix this
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
    end
  end
end
