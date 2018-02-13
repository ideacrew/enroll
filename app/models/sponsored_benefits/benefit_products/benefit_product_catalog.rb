module SponsoredBenefits
  module BenefitProducts
    class BenefitProductCatalog

      attr_reader :effective_period, :benefit_market, 
                  :open_enrollment_period, :open_enrollment_period_minimum, 
                  :binder_payment_due_on,
                  :probation_period_kinds,
                  :benefit_products,
                  :sponsor_eligibility_policy


      def initialize(effective_date, benefit_market)
        @effective_date         = effective_date.to_date.beginning_of_month
        @open_enrollment_period = open_enrollment_period_by_effective_date(effective_date)

        open_enrollment_period


        prior_month           = effective_date - 1.month
        binder_payment_due_on = Date.new(prior_month.year, prior_month.month, Settings.aca.shop_market.binder_payment_due_on)
      end

      def effective_period
        @effective_period  = effective_date..(effective_date + 1.year - 1.day)
      end


      def open_enrollment_period
        earliest_begin_date = effective_date - @benefit_market.open_enrollment_maximum_length

        prior_month = effective_date - 1.month

        begin_on = Date.new(earliest_begin_date.year, earliest_begin_date.month, 1)
        end_on   = Date.new(prior_month.year, prior_month.month, @benefit_market.open_enrollment_end_on_day_of_month)

        @open_enrollment_period = begin_on..end_on
      end


      def open_enrollment_minimum_begin_day_of_month(use_grace_period = false)
        if use_grace_period
          minimum_length = Settings.aca.shop_market.open_enrollment.minimum_length.days
        else
          minimum_length = Settings.aca.shop_market.open_enrollment.minimum_length.adv_days
        end

        open_enrollment_end_on_day = Settings.aca.shop_market.open_enrollment.monthly_end_on
        open_enrollment_end_on_day - minimum_length
      end


      def benefit_products
      end



    end
  end
end
