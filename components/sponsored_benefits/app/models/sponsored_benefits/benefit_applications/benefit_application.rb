module SponsoredBenefits
  module BenefitApplications
    class BenefitApplication
      include Mongoid::Document
      include Mongoid::Timestamps


      # The date range when this application is active
      field :effective_period,        type: Range

      # The date range when members may enroll in benefit products
      # Stored locally to enable sponsor-level exceptions
      field :open_enrollment_period,  type: Range

      # The date on which this application was canceled or terminated
      field :terminated_on,           type: Date

      # This application's workflow status
      field :aasm_state, type: String

      # field :benefit_sponsorship_id, type: BSON::ObjectId
      belongs_to  :benefit_sponsorship, class_name: "SponsoredBenefits::BenefitSponsorships::BenefitSponsorship"
      belongs_to  :benefit_market,      class_name: "SponsoredBenefits::BenefitMarkets::BenefitMarket"

      embeds_many :benefit_packages,    class_name: "SponsoredBenefits::BenefitSponsorships::BenefitPackage", 
        cascade_callbacks: true, 
        validate: true

      validates_presence_of :benefit_market, :effective_period, :open_enrollment_period
      # validate :validate_application_dates

      validate :open_enrollment_date_checks

      index({ "effective_period.min" => 1, "effective_period.max" => 1 }, { name: "effective_period" })
      index({ "open_enrollment_period.min" => 1, "open_enrollment_period.max" => 1 }, { name: "open_enrollment_period" })

      scope :by_effective_date,       ->(effective_date)    { where(:"effective_period.min" => effective_date) }
      scope :by_effective_date_range, ->(begin_on, end_on)  { where(:"effective_period.min".gte => begin_on, :"effective_period.min".lte => end_on) }


      ## Stub for BQT
      def estimate_group_size?
        true
      end

      def effective_date
        effective_period.begin unless effective_period.blank?
      end

      def effective_period=(new_effective_period)
        effective_range = SponsoredBenefits.tidy_date_range(new_effective_period, :effective_period)
        write_attribute(:effective_period, effective_range) unless effective_range.blank?
      end

      def open_enrollment_period=(new_open_enrollment_period)
        open_enrollment_range = SponsoredBenefits.tidy_date_range(new_open_enrollment_period, :open_enrollment_period)
        write_attribute(:open_enrollment_period, open_enrollment_range) unless open_enrollment_range.blank?
      end

      def open_enrollment_completed?
        open_enrollment_period.blank? ? false : (::TimeKeeper.date_of_record > open_enrollment_period.end)
      end

      # Application meets criteria necessary for sponsored members to shop for benefits
      def is_open_enrollment_eligible?
      end

      # Application meets criteria necessary for sponsored members to effectuate selected benefits
      def is_coverage_effective_eligible?
      end

      # def employer_profile
      #   benefit_sponsorship.benefit_sponsorable
      # end

      def default_benefit_group
        benefit_groups.detect(&:default)
      end

      def minimum_employer_contribution
        unless benefit_groups.size == 0
          benefit_groups.map do |benefit_group|
            if benefit_group.sole_source?
              OpenStruct.new(:premium_pct => 100)
            else
              benefit_group.relationship_benefits.select do |relationship_benefit|
                relationship_benefit.relationship == "employee"
              end.min_by do |relationship_benefit|
                relationship_benefit.premium_pct
              end
            end
          end.map(&:premium_pct).first
        end
      end

      def to_plan_year
        return unless benefit_sponsorship.present? && effective_period.present? && open_enrollment_period.present?
        raise "Invalid number of benefit_groups: #{benefit_groups.size}" if benefit_groups.size != 1

        # CCA-specific attributes (move to subclass)
        recorded_sic_code               = ""
        recorded_rating_area            = ""

        copied_benefit_groups = []
        benefit_groups.each do |benefit_group|
          benefit_group.attributes.delete("_type")
          copied_benefit_groups << ::BenefitGroup.new(benefit_group.attributes)
        end

        ::PlanYear.new(
          start_on: effective_period.begin,
          end_on: effective_period.end,
          open_enrollment_start_on: open_enrollment_period.begin,
          open_enrollment_end_on: open_enrollment_period.end,
          benefit_groups: copied_benefit_groups
        )
      end

      class << self
        def calculate_start_on_dates
          start_on = if TimeKeeper.date_of_record.day > open_enrollment_minimum_begin_day_of_month(true)
            TimeKeeper.date_of_record.beginning_of_month + Settings.aca.shop_market.open_enrollment.maximum_length.months.months
          else
            TimeKeeper.date_of_record.prev_month.beginning_of_month + Settings.aca.shop_market.open_enrollment.maximum_length.months.months
          end

          end_on = TimeKeeper.date_of_record - Settings.aca.shop_market.initial_application.earliest_start_prior_to_effective_on.months.months
          dates = (start_on..end_on).select {|t| t == t.beginning_of_month}
        end

        def calculate_start_on_options
          calculate_start_on_dates.map {|date| [date.strftime("%B %Y"), date.to_s(:db) ]}
        end

        def enrollment_timetable_by_effective_date(effective_date)
          effective_date            = effective_date.to_date.beginning_of_month
          effective_period          = effective_date..(effective_date + 1.year - 1.day)
          open_enrollment_period    = open_enrollment_period_by_effective_date(effective_date)
          prior_month               = effective_date - 1.month
          binder_payment_due_on     = Date.new(prior_month.year, prior_month.month, Settings.aca.shop_market.binder_payment_due_on)

          open_enrollment_minimum_day     = open_enrollment_minimum_begin_day_of_month
          open_enrollment_period_minimum  = Date.new(prior_month.year, prior_month.month, open_enrollment_minimum_day)..open_enrollment_period.end

          {
              effective_date: effective_date,
              effective_period: effective_period,
              open_enrollment_period: open_enrollment_period,
              open_enrollment_period_minimum: open_enrollment_period_minimum,
              binder_payment_due_on: binder_payment_due_on,
            }
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


        # TODOs
        ## handle late rate scenarios where partial or no benefit product plan/rate data exists for effective date
        ## handle midyear initial enrollments for annual fixed enrollment periods
        def effective_period_by_date(given_date = TimeKeeper.date_of_record, use_grace_period = false)
          given_day_of_month    = given_date.day
          next_month_start      = given_date.end_of_month + 1.day
          following_month_start = next_month_start + 1.month

          if use_grace_period
            last_day = open_enrollment_minimum_begin_day_of_month(true)
          else
            last_day = open_enrollment_minimum_begin_day_of_month
          end

          if given_day_of_month > last_day
            following_month_start..(following_month_start + 1.year - 1.day)
          else
            next_month_start..(next_month_start + 1.year - 1.day)
          end
        end




        def find(id)
          application = nil
          Organizations::PlanDesignOrganization.where(:"plan_design_profile.benefit_sponsorships.benefit_applications._id" => BSON::ObjectId.from_string(id)).each do |pdo|
            sponsorships = pdo.plan_design_profile.try(:benefit_sponsorships) || []
            sponsorships.each do |sponsorship|
              application = sponsorship.benefit_applications.detect { |benefit_application| benefit_application._id == BSON::ObjectId.from_string(id) }
              break if application.present?
            end
          end
          application
        end
      end



      def open_enrollment_date_checks
        return if effective_period.blank? || open_enrollment_period.blank?

        if effective_period.begin.mday != effective_period.begin.beginning_of_month.mday
          errors.add(:effective_period, "start date must be first day of the month")
        end

        if effective_period.end.mday != effective_period.end.end_of_month.mday
          errors.add(:effective_period, "must be last day of the month")
        end

        if effective_period.end > effective_period.begin.years_since(Settings.aca.shop_market.benefit_period.length_maximum.year)
          errors.add(:effective_period, "benefit period may not exceed #{Settings.aca.shop_market.benefit_period.length_maximum.year} year")
        end

        if open_enrollment_period.end > effective_period.begin
          errors.add(:effective_period, "start date can't occur before open enrollment end date")
        end

        if open_enrollment_period.end < open_enrollment_period.begin
          errors.add(:open_enrollment_period, "can't occur before open enrollment start date")
        end

        if open_enrollment_period.begin < (effective_period.begin - Settings.aca.shop_market.open_enrollment.maximum_length.months.months)
          errors.add(:open_enrollment_period, "can't occur earlier than 60 days before start date")
        end

        if open_enrollment_period.end > (open_enrollment_period.begin + Settings.aca.shop_market.open_enrollment.maximum_length.months.months)
          errors.add(:open_enrollment_period, "open enrollment period is greater than maximum: #{Settings.aca.shop_market.open_enrollment.maximum_length.months} months")
        end

        ## Leave this validation disabled in the BQT??
        # if (effective_period.begin + Settings.aca.shop_market.initial_application.earliest_start_prior_to_effective_on.months.months) > TimeKeeper.date_of_record
        #   errors.add(:effective_period, "may not start application before " \
        #              "#{(effective_period.begin + Settings.aca.shop_market.initial_application.earliest_start_prior_to_effective_on.months.months).to_date} with #{effective_period.begin} effective date")
        # end
      end


    end
  end
end
