module SponsoredBenefits
  module BenefitApplications
    class AcaShopCcaBenefitApplicationBuilder < BenefitApplicationBuilder

      def initialize(benefit_sponsor, effective_on = ::TimeKeeper.date_of_record, options={})
        effective_on      = options[:effective_date] || Date.today.next_month.end_of_month + 1
        effective_period  = one_year_period(effective_on)

        @application_class    = AcaShopCcaBenefitApplication
        @benefit_application  = @application_class.new({effective_period: effective_period})


        super(options)

        # @benefit_application = SponsoredBenefits::BenefitApplications::AcaShopCcaBenefitApplication.new
        # @benefit_sponsor =
        # @benefit_market =

        # Settings.site.benefit_market
      end

      def add_broker(new_broker)
        @broker = new_broker
      end

      def add_employer_attestation(new_employer_attestation)
      end

      def benefit_application
        # raise "" if open_enrollment_term.blank?
        @benefit_application
      end

      def reset
        @benefit_application = @application_class.new
      end

    private
      def one_year_period(begin_on)
        begin_on..(begin_on + 1.year - 1.day)
      end



    end
  end
end
