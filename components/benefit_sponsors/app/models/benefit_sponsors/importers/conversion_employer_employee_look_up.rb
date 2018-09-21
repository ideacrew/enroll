module BenefitSponsors
  module Importers
    module ConversionEmployerEmployeeLookUp

      def find_employer(fein)
        BenefitSponsors::Organizations::Organization.where(fein: fein).first
      end

      def find_benefit_package(organization)
        organization.benefit_sponsorships.first.benefit_applications.first.benefit_packages.first
      end

      def find_carrier
        BenefitSponsors::Organizations::IssuerProfile.find_by_abbrev(carrier)
      end

    end
  end
end