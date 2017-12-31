module SponsoredBenefits
  module BenefitApplications
    class BenefitApplication
      include Mongoid::Document
      include Mongoid::Timestamps

      embedded_in :benefit_sponsorship, class_name: "SponsoredBenefits::BenefitSponsorships::BenefitSponsorship"

      delegate :sic_code, to: :benefit_sponsorship
      delegate :rating_area, to: :benefit_sponsorship
      delegate :census_employees, to: :benefit_sponsorship
      delegate :plan_design_organization, to: :benefit_sponsorship
     ### Deprecate -- use effective_period attribute
      # field :start_on, type: Date
      # field :end_on, type: Date

      # The date range when this application is active
      field :effective_period,        type: Range

      ### Deprecate -- use open_enrollment_period attribute
      # field :open_enrollment_start_on, type: Date
      # field :open_enrollment_end_on, type: Date

      # The date range when members may enroll in benefit products
      field :open_enrollment_period,  type: Range

      # Populate when enrollment is terminated prior to open_enrollment_period.end
      # field :terminated_early_on, type: Date

      # field :sponsorable_id, type: String
      # field :rosterable_id, type: String
      # field :broker_id, type: String
      # field :kind, type: :symbol

      # has_one :rosterable, as: :rosterable

      embeds_many :benefit_groups, class_name: "SponsoredBenefits::BenefitApplications::BenefitGroup", cascade_callbacks: true

      # embeds_many :benefit_packages, as: :benefit_packageable, class_name: "SponsoredBenefits::BenefitPackages::BenefitPackage"
      # accepts_nested_attributes_for :benefit_packages

      # ## Override with specific benefit package subclasses
      #   embeds_many :benefit_packages, class_name: "SponsoredBenefits::BenefitPackages::BenefitPackage", cascade_callbacks: true
      #   accepts_nested_attributes_for :benefit_packages
      # ##

      validates_presence_of :effective_period, :open_enrollment_period, :message => "is missing"
      # validate :validate_application_dates

      validate :open_enrollment_date_checks

      #
      # Are these correct? I don't think you can move an embedded object just by changing an id?
      #
      # def benefit_sponsor=(new_sponsor)
      #   self.sponsorable_id = new_sponsor.id
      # end
      #
      # BrokerAgencyProfile embeds this entire chain - this can't be the way we adjust it
      #
      # def broker=(new_broker)
      #   self.broker_id = new_broker.id
      # end


      ## Stub for BQT
      def estimate_group_size?
        true
      end

      def effective_period=(new_effective_period)
        effective_range = SponsoredBenefits.tidy_date_range(new_effective_period, :effective_period)
        write_attribute(:effective_period, new_effective_period) unless new_effective_period.blank?
      end

      def open_enrollment_period=(new_open_enrollment_period)
        open_enrollment_range = SponsoredBenefits.tidy_date_range(new_open_enrollment_period, :open_enrollment_period)
        write_attribute(:open_enrollment_period, new_open_enrollment_period) unless new_open_enrollment_period.blank?
      end

      def start_on
        effective_period.begin
      end

      def end_on
        effective_period.end
      end

      def open_enrollment_begin_on
        open_enrollment_period.begin
      end

      def open_enrollment_end_on
        open_enrollment_period.end
      end

      def open_enrollment_completed?
        open_enrollment_period.blank? ? false : (::TimeKeeper.date_of_record > open_enrollment_period.end)
      end

      # Application meets criteria necessary for sponsored group to shop for benefits
      def is_open_enrollment_eligible?
      end

      # Application meets criteria necessary for sponsored group to effectuate selected benefits
      def is_coverage_effective_eligible?
      end

      def employer_profile
        benefit_sponsorship.benefit_sponsorable
      end

      def plan_design_census_employees
        CensusMembers::PlanDesignCensusEmployee.where(:benefit_application_id => self.id)
      end


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
        return unless benefit_sponsorship.present && enrollment_period.present? && open_enrollment_period.present?
        raise "Invalid number of benefit_groups: #{benefit_groups.size}" unless benefit_groups.size <= 1

        # Attribute Map
        start_on                        = enrollment_period.begin
        end_on                          = enrollment_period.end
        open_enrollment_period_start_on = open_enrollment_period.begin
        open_enrollment_period_end_on   = open_enrollment_period.end

        # CCA-specific attributes (move to subclass)
        recorded_sic_code               = ""
        recorded_rating_area            = ""

        # TODO: BenefitGroups and CensusEmployee BenefitGroupAssigments use IDs for association.  Ruby clone creates a
        # new instance with a new ID.  However, given the requirements specify only one benefit_group is supported by Plan Design,
        # the mapping straightforward.

        benefit_group_assignments = []
        cloned_benefit_groups = benefit_groups.reduce([]) do |list, benefit_group|

          source_benefit_group_id = benefit_groups.pluck(:_id).first
          employees = CensusEmployee.where({ :"benefit_group_assignments.benefit_group_id" => source_benefit_group_id })

          cloned_benefit_group = benefit_group.clone
          cloned_benefit_group_id = cloned_benefit_group.id

          employees.each do |census_employee|
            census_employee.benefit_group_assignments.where(:benefit_group_id => bg_id).each do |assignment|
              assignment.update(benefit_group_id = cloned_benefit_group_id)
            end
          end

          # list <<

        end

        ::PlanYear.new( start_on: start_on,
                        end_on: end_on,
                        open_enrollment_period_start_on: open_enrollment_period_start_on,
                        open_enrollment_period_end_on: open_enrollment_period_end_on,
                        benefit_groups: cloned_benefit_groups,
                      )
      end

      ## This Plan Year code is refactored in section below.  Remove this section once the values are properly mapped in new context ##

      # def shop_enrollment_timetable(new_effective_date)
      #   effective_date = new_effective_date.to_date.beginning_of_month
      #   prior_month = effective_date - 1.month
      #   plan_year_start_on = effective_date
      #   plan_year_end_on = effective_date + 1.year - 1.day

      #   employer_initial_application_earliest_start_on = (effective_date +
      #     Settings.aca.shop_market.initial_application.earliest_start_prior_to_effective_on.months.months +
      #     Settings.aca.shop_market.initial_application.earliest_start_prior_to_effective_on.day_of_month.days)

      #   employer_initial_application_earliest_submit_on = employer_initial_application_earliest_start_on
      #   employer_initial_application_latest_submit_on   = ("#{prior_month.year}-#{prior_month.month}-#{HbxProfile::ShopPlanYearPublishedDueDayOfMonth}").to_date


      #   open_enrollment_earliest_start_on     = effective_date - Settings.aca.shop_market.open_enrollment.maximum_length.months.months
      #   open_enrollment_latest_start_on       = ("#{prior_month.year}-#{prior_month.month}-#{HbxProfile::ShopOpenEnrollmentBeginDueDayOfMonth}").to_date
      #   open_enrollment_latest_end_on         = ("#{prior_month.year}-#{prior_month.month}-#{PlanYear.shop_market_open_enrollment_monthly_end_on}").to_date
      #   binder_payment_due_date               = first_banking_date_prior ("#{prior_month.year}-#{prior_month.month}-#{PlanYear.shop_market_binder_payment_due_on}")
      #   advertised_due_date_of_month          = ("#{prior_month.year}-#{prior_month.month}-#{HbxProfile::ShopOpenEnrollmentAdvBeginDueDayOfMonth}").to_date


      #   timetable = {
      #     effective_date: effective_date,
      #     plan_year_start_on: plan_year_start_on,
      #     plan_year_end_on: plan_year_end_on,
      #     employer_initial_application_earliest_start_on: employer_initial_application_earliest_start_on,
      #     employer_initial_application_earliest_submit_on: employer_initial_application_earliest_submit_on,
      #     employer_initial_application_latest_submit_on: employer_initial_application_latest_submit_on,
      #     open_enrollment_earliest_start_on: open_enrollment_earliest_start_on,
      #     open_enrollment_latest_start_on: open_enrollment_latest_start_on,
      #     open_enrollment_latest_end_on: open_enrollment_latest_end_on,
      #     binder_payment_due_date: binder_payment_due_date,
      #     advertised_due_date_of_month: advertised_due_date_of_month
      #   }

      #   timetable
      # end


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
          effective_period          = effective_date..(effective_date + 1.year - 1.day).end_of_day
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


        def open_enrollment_period_by_effective_date(effective_date)
          earliest_begin_date = effective_date + Settings.aca.shop_market.initial_application.earliest_start_prior_to_effective_on.months.months
          prior_month = effective_date - 1.month

          begin_on = Date.new(earliest_begin_date.year, earliest_begin_date.month, 1)
          end_on   = Date.new(prior_month.year, prior_month.month, Settings.aca.shop_market.open_enrollment.monthly_end_on)
          begin_on..end_on.end_of_day
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
          errors.add(:open_enrollment_period.begin, "can't occur earlier than 60 days before start date")
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
