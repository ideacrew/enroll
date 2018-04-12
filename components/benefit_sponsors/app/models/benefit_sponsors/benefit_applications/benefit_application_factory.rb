module BenefitSponsors
  module BenefitApplications
    class BenefitApplicationFactory

      attr_accessor :benefit_sponsorship, :args

      def self.call(benefit_sponsorship, args)
        new(benefit_sponsorship, attributes).benefit_application
      end

      def initialize(benefit_sponsorship, args)
        @benefit_sponsorship = benefit_sponsorship
        @args = args.symbolize_keys
        build_benefit_application
      end

      def build_benefit_application
        initialize_application
        add_effective_period
        add_open_enrollment_period
        add_ftp_count
        add_pte_count
        add_msp_count

        if site.site_key == :cca
          add_recorded_sic_code
          add_recorded_rating_area
        end
      end

      def initialize_application
        @benefit_application = @args[:benefit_application]
        benefit_market = benefit_sponsorship.benefit_market
        site_key = benefit_market.site.site_key

        if @benefit_application.blank?
          klass_name  = [benefit_market.kind.to_s.camelcase, site_key.to_s.camelcase, "BenefitApplication"].join('')
          @benefit_application = [parent_namespace_for(self.class), "BenefitApplications", klass_name].join("::").constantize.new
          @benefit_application.benefit_sponsorship_id = benefit_sponsorship.id
        end
      end

      def add_effective_period
        @benefit_application.effective_period = args[:start_on]..args[:end_on]
      end

      def add_open_enrollment_period
        @benefit_application.open_enrollment_period = args[:open_enrollment_start_on]..args[:open_enrollment_end_on]
      end

      def add_ftp_count
        @benefit_application.fte_count = args[:fte_count]
      end

      def add_pte_count
        @benefit_application.pte_count = args[:pte_count]
      end

      def add_msp_count
        @benefit_application.msp_count = args[:msp_count]
      end

      def add_recorded_sic_code
      end

      def add_recorded_rating_area
      end

      def benefit_application
        @benefit_application
      end

      def benefit_sponsor_catalogs_for(benefit_sponsorship)
        benefit_sponsorship.benefit_sponsor_catalogs
      end
    end

    class BenefitApplicationFactoryError < StandardError; end
  end
end
