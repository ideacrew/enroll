module BenefitSponsors
  module Importers
    module ConversionEmployerEmployeeLookUp

      def find_employer(fein)
        BenefitSponsors::Organizations::Organization.where(fein: fein).first
      end

      def find_benefit_package(organization)
        organization.benefit_sponsorships.first.benefit_applications.first.benefit_packages.first
      end
    end
  end
end