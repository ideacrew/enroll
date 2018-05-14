module BenefitSponsors
  module Organizations
    class IssuerProfile < BenefitSponsors::Organizations::Profile
      include Mongoid::Document
      include Mongoid::Timestamps


      def benefit_products
      end

      def benefit_products_by_effective_date(effective_date)
      end

      private 

      def initialize_profile
        return unless is_benefit_sponsorship_eligible.blank?

        write_attribute(:is_benefit_sponsorship_eligible, false)
        @is_benefit_sponsorship_eligible = false
        self
      end

      class << self
        def find_by_issuer_name(issuer_name)
          issuer_org = BenefitSponsors::Organizations::Organization.where(:legal_name => issuer_name, :"profiles._type" => "BenefitSponsors::Organizations::IssuerProfile").first
          issuer_org.profiles.where(:"_type" => "BenefitSponsors::Organizations::IssuerProfile").first
        end
      end
    end 
  end
end
