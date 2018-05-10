module BenefitSponsors
  module BenefitPackages
    class BenefitPackageFactory
 
      # returns benefit package

      def self.call(benefit_application, args)
        new(benefit_application, args).benefit_package
      end

      def self.validate(benefit_package)
        # TODO: Add validations
        true
      end

      def initialize(benefit_application, args)
        @benefit_application = benefit_application
        initialize_benefit_package(args)
      end

      def initialize_benefit_package(args)
        @benefit_package = @benefit_application.benefit_packages.build
        @benefit_package.assign_attributes(args)
        binding.pry
        @benefit_package.save
      end

      def benefit_package
        @benefit_package
      end
    end
  end
end