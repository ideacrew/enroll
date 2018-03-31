module BenefitSponsors
  module Organizations
    class FehbEmployerProfile < BenefitSponsors::Organizations::Profile
    include Mongoid::Document


      field :benefit_sponsorship_id,  type: BSON::ObjectId

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
