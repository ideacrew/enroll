module SponsoredBenefits
  module Organizations
    class IssuerProfile < Profile
      include Mongoid::Document
      include Mongoid::Timestamps



      def benefit_products
      end

      def benefit_products_by_effective_date(effective_date)
      end

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
