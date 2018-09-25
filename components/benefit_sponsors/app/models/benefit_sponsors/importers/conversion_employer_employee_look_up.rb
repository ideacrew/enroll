module BenefitSponsors
  module Importers
    module ConversionEmployerEmployeeLookUp

      def find_carrier
        BenefitSponsors::Organizations::IssuerProfile.find_by_abbrev(carrier)
      end

      def find_employer
        org = BenefitSponsors::Organizations::Organization.where(:fein => fein).first
        return nil unless org
        org.profiles.first
      end

      def find_benefit_package
        employer_profile = find_employer
        benefit_application = employer_profile.benefit_applications.first
        benefit_application.benefit_packages.first
      end
    end
  end
end