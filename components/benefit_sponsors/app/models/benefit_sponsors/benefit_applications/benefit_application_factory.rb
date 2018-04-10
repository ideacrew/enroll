module BenefitSponsors
  module BenefitApplications
    class BenefitApplicationFactory

      attr_accessor :benefit_sponsorship

      def initialize(form_obj, benefit_sponsorship)
        @benefit_sponsorship = benefit_sponsorship
        @form_obj = form_obj
      end

      def self.call(form_obj)
        new(params).benefit_application
      end

      def site
        benefit_market.site
      end

      def benefit_market
        benefit_sponsorship.benefit_market
      end

      def benefit_application
        return @benefit_application if defined? @benefit_application
        @benefit_application = @form_obj.reference_benefit_application

        if @benefit_application.blank?
          namespace = [parent_namespace_for(self.class), "BenefitApplication"].join("::")
          market_kind = "#{benefit_market.kind}".camelcase
          site_key = "#{site.site_key}".camelcase
          klass_name = [market_kind, site, "BenefitApplication"].join('')

          @benefit_application = [namespace, klass_name].join("::").constantize.new
          @benefit_application.benefit_sponsorship_id = benefit_sponsorship.id
        end

        build_application
      end

      def build_application
        add_effective_period
        add_open_enrollment_period
        add_ftp_count
        add_pte_count
        add_msp_count

        if site.site_key == :cca
          add_recorded_sic_code
          add_recorded_rating_area
        end

        @benefit_application
      end

      def add_effective_period
        @benefit_application.effective_period = @form_obj.effective_period
      end

      def add_open_enrollment_period
        @benefit_application.open_enrollment_period = @form_obj.open_enrollment_period
      end

      def add_ftp_count
        @benefit_application.fte_count = @form_obj.fte_count
      end

      def add_pte_count
        @benefit_application.pte_count = @form_obj.pte_count
      end

      def add_msp_count
        @benefit_application.msp_count = @form_obj.msp_count
      end

      def add_recorded_sic_code
      end

      def add_recorded_rating_area
      end
    end

    class BenefitApplicationFactoryError < StandardError; end
  end
end