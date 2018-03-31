module BenefitSponsors
  module BenefitPackages
    class BenefitPackageFactory
 
      # returns benefit package 

      def initialize(benefit_application)
        @benefit_application = benefit_application

        @benefit_package = BenefitSponsors::BenefitPackages::BenefitPackage.new
      end

      def probation_periods
      end

      def product_packages
      end

      def benefit_package
        @benefit_package
      end
    end
  end
end