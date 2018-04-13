module BenefitSponsors
  module BenefitApplications
    class BenefitApplicationFactory

      attr_accessor :benefit_sponsorship, :args

      def self.call(benefit_sponsorship:, benefit_application:, *args)
        new(benefit_sponsorship: benefit_sponsorship, benefit_application: benefit_application, args).benefit_application
      end

      def initialize(benefit_sponsorship: benefit_sponsorship, benefit_application: benefit_application, *args)
        @benefit_sponsorship = benefit_sponsorship
        @args = args.symbolize_keys
      end

      def build
        benefit_application.effective_period = args[:start_on]..args[:end_on]
        benefit_application.open_enrollment_period = args[:open_enrollment_start_on]..args[:open_enrollment_end_on]
        benefit_application.fte_count = args[:fte_count]
        benefit_application.pte_count = args[:pte_count]
        benefit_application.msp_count = args[:msp_count]

        if site.site_key == :cca
          benefit_application.recorded_sic_code    = args[:sic_code]
          benefit_application.recorded_rating_area = args[:rating_area]
        end
      end

      def benefit_application
        return @benefit_application if defined? @benefit_application
        benefit_market = benefit_sponsorship.benefit_market
        site_key = benefit_market.site.site_key

        if @benefit_application.blank?
          klass_name  = [benefit_market.kind.to_s.camelcase, site_key.to_s.camelcase, "BenefitApplication"].join('')
          @benefit_application = [parent_namespace_for(self.class), "BenefitApplications", klass_name].join("::").constantize.new
          @benefit_application.benefit_sponsorship = benefit_sponsorship
        end
      end
    end

    class BenefitApplicationFactoryError < StandardError; end
  end
end
