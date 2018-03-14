module SponsoredBenefits
  module Organizations
    class ContactCenterProfile
      include Mongoid::Document
      include Mongoid::Timestamps



      private 

      def initialize_profile
        return unless benefit_sponsorship_eligible.blank?

        write_attribute(:benefit_sponsorship_eligible, false)
        @benefit_sponsorship_eligible = false
        self
      end

    end
  end
end
