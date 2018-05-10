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
        assign_application_attributes(args)
      end

      def initialize_benefit_package(args)
        @benefit_package = BenefitSponsors::BenefitPackages::BenefitPackage.new(args)
        @benefit_application.benefit_packages << @benefit_package
        @benefit_application.save
      end

      def product_packages
      end

      def benefit_package
        @benefit_package
      end

      protected

      def assign_application_attributes(args)
        return nil if args.blank?
        args.each_pair do |k, v|
          @benefit_package.send("#{k}=".to_sym, v)
        end
      end

    end
  end
end