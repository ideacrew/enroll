module BenefitSponsors
  module Importers::Mhc
    class ConversionEmployerPlanYear < ::Importers::Mhc::ConversionEmployerPlanYear

      attr_accessor :plan_year_end, :mid_year_conversion


      def find_carrier
        BenefitSponsors::Organizations::IssuerProfile.find_by_abbrev(carrier)
      end

      def find_employer
        org = BenefitSponsors::Organizations::Organization.where(:fein => fein).first
        return nil unless org
        org.profiles.first
      end
    end
  end
end