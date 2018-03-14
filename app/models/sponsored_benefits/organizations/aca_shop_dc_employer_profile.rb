module SponsoredBenefits
  module Organizations
    class AcaShopDcEmployerProfile < Profile


      private

      def initialize_profile
        return unless benefit_sponsorship_eligible.blank?

        write_attribute(:benefit_sponsorship_eligible, true)
        @benefit_sponsorship_eligible = true
        self
      end
    end
  end
end
