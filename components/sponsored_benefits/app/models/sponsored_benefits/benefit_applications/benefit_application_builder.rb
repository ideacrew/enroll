module SponsoredBenefits
  module BenefitApplications
    class BenefitApplicationBuilder

      attr_reader :benefit_application

      def initialize(options)
        @application_class ||= AcaShopBenefitApplication
        @benefit_application = @application_class.new(options)
      end

      def add_benefit_sponsor(new_benefit_sponsor)
        @benefit_application.benefit_sponsor = new_benefit_sponsor
      end

      def add_roster(new_roster)
        @benefit_application.roster = new_roster
      end

      def add_marketplace_kind(new_marketplace_kind)
        @benefit_application.marketplace_kind = new_marketplace_kind
      end

      def add_broker(new_broker)
        @benefit_application.broker = new_broker
      end

      def add_geographic_rating_areas(new_geographic_rating_areas)
        @benefit_application.geographic_rating_areas << new_geographic_rating_areas
      end


      # Date range beginning on coverage effective date and ending on coverage expiration date
      def add_coverage_effective_range(new_coverage_effective_range)
        @benefit_application.coverage_effective_range = new_coverage_effective_range
      end

      def add_benefit_package(new_benefit_package)
        @benefit_application.benefit_packages << new_benefit_package
      end

      def benefit_application
        @benefit_application
      end

      def reset
        @benefit_application.benefit_sponsor = nil
        @benefit_application.roster = nil
        @benefit_application.broker = nil
        @benefit_application.marketplace_kind = nil
        @benefit_application.coverage_effective_range = nil
        @benefit_application.benefit_packages = []
      end
    end
  end
end
