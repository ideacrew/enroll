module BenefitSponsors
  module BenefitApplications
    class BenefitApplicationBuilder

      attr_reader :benefit_application, :application_attrs
      
      # AcaShopCcaBenefitApplicationBuilder.build do |builder|
      #   builder.benefit_sponsorship(benefit_sponsorship)
      #   builder.application_attrs(list_bill_attrs)
      #   builder.build_application       
      # end

      def self.build
        builder = new
        yield(builder)
        builder.add_effective_period
        builder.add_open_enrollment_period
        builder.add_ftp_pte_msp
        builder.benefit_application
      end

      def effective_date
        return @effective_date if defined? @effective_date
        @effective_date = application_attrs[:start_on]
      end

      def benefit_sponsorship(benefit_sponsorship)
        @benefit_sponsorship = benefit_sponsorship
      end

      def benefit_market
        @benefit_sponsorship.benefit_market
      end

      def benefit_catalog
        return @benefit_catalog if defined? @benefit_catalog
        @benefit_catalog = benefit_market.benefit_catalog_by_effective_date(effective_date)
      end

      def organization
        @organization = @benefit_sponsorship.organization
      end

      def application_options(options)
        @application_attrs = options[:benefit_application_attributes].symbolize_keys
      end

      def add_effective_period
        @benefit_application.effective_period = parse_date(@application_attrs[:start_on])..parse_date(@application_attrs[:end_on])
      end

      def add_open_enrollment_period
        @benefit_application.open_enrollment_period = parse_date(@application_attrs[:open_enrollment_start_on])..parse_date(@application_attrs[:open_enrollment_end_on])
      end

      def add_ftp_pte_msp
        @benefit_application.fte_count = application_attrs[:fte_count]
      end

      def add_pte
        @benefit_application.pte_count = application_attrs[:pte_count]
      end

      def add_msp
        @benefit_application.msp_count = application_attrs[:msp_count]
      end

      # def add_benefit_sponsor(new_benefit_sponsor)
      #   @benefit_application.benefit_sponsor = new_benefit_sponsor
      # end

      # def add_roster(new_roster)
      #   @benefit_application.roster = new_roster
      # end

      # def add_marketplace_kind(new_marketplace_kind)
      #   @benefit_application.marketplace_kind = new_marketplace_kind
      # end

      # TODO: move to sponsorship
      # def add_broker(new_broker)
      #   @benefit_application.broker = new_broker
      # end

      # def add_geographic_rating_areas(new_geographic_rating_areas)
      #   @benefit_application.geographic_rating_areas << new_geographic_rating_areas
      # end

      # Date range beginning on coverage effective date and ending on coverage expiration date
      # def add_application_period(new_application_period)
      #   @benefit_application.application_period = new_application_period
      # end

      # def add_benefit_package(new_benefit_package)
      #   @benefit_application.benefit_packages << new_benefit_package
      # end

      # def reset
      #   @benefit_application = @application_class.new(options)
      # end

      def benefit_application
        @benefit_application
      end

      def method_missing(name, *args)
        words = name.to_s.split('_')
        return super(name, *args) unless words.shift == 'add'
        words.each do |word|
          method_str = "add_#{word}"
          if self.respond_to?(method_str)
            self.send(method_str)
          end
        end
      end

      def parse_date(date)
        Date.strptime(date, "%Y-%m-%d")
      end
    end

    class BenefitApplicationBuilderError < StandardError; end
  end
end
