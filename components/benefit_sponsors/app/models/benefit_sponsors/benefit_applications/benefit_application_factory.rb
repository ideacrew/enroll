module BenefitSponsors
  module BenefitApplications
    class BenefitApplicationFactory

      attr_accessor :benefit_sponsorship

      def self.call(benefit_sponsorship, args)
        new(benefit_sponsorship, args).benefit_application
      end

      def self.validate(benefit_application)
        # TODO: Add validations
        # Validate open enrollment period
        true
      end

      def initialize(benefit_sponsorship, args)
        @benefit_sponsorship = benefit_sponsorship
        initialize_benefit_application
        assign_application_attributes(args)
      end

      def initialize_benefit_application
        # benefit_market = benefit_sponsorship.benefit_market
        # site_key = benefit_market.site_urn
        # klass_name  = [benefit_market.kind.to_s.camelcase, site_key.to_s.camelcase, "BenefitApplication"].join('')
        # @benefit_application = [parent_namespace_for(self.class), klass_name].join("::").constantize.new

        @benefit_application = BenefitSponsors::BenefitApplications::BenefitApplication.new
        @benefit_application.benefit_sponsorship = benefit_sponsorship
      end

      def benefit_application
        @benefit_application
      end

      protected

      def parent_namespace_for(klass)
        klass_name = klass.to_s.split("::")
        klass_name.slice!(-1) || []
        klass_name.join("::")
      end

      def assign_application_attributes(args)
        args.each_pair do |k, v|
          @benefit_application.send("#{k}=".to_sym, v)
        end
      end
    end

    class BenefitApplicationFactoryError < StandardError; end
  end
end
