module BenefitSponsors
  module BenefitApplications
    class BenefitApplication
      include Mongoid::Document
      include Mongoid::Timestamps
      include AASM

      # The date range when this application is active
      field :effective_period,        type: Range

      # The date range when members may enroll in benefit products
      # Stored locally to enable sponsor-level exceptions
      field :open_enrollment_period,  type: Range

      # The date on which this application was canceled or terminated
      field :terminated_on,           type: Date

      # This application's workflow status
      field :aasm_state, type: String, default: :draft

      field :imported_plan_year, type: Boolean, default: false

      # Plan year created to support Employer converted into system. May not be complaint with Hbx Business Rules
      field :is_conversion, type: Boolean, default: false

      # Number of full-time employees
      field :fte_count, type: Integer, default: 0

      # Number of part-time employess
      field :pte_count, type: Integer, default: 0

      # Number of Medicare Second Payers
      field :msp_count, type: Integer, default: 0

      # Calculated Fields for DataTable
      field :enrolled_summary, type: Integer, default: 0
      field :waived_summary, type: Integer, default: 0


      # field :benefit_sponsorship_id, type: BSON::ObjectId
      belongs_to  :benefit_sponsorship, 
                  class_name: "BenefitSponsors::BenefitSponsorships::BenefitSponsorship"
      belongs_to  :benefit_market, counter_cache: true,
                  class_name: "SponsoredBenefits::BenefitMarkets::BenefitMarket"

      embeds_many :benefit_packages,    class_name: "BenefitSponsors::BenefitPackages:BenefitPackage",
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
        effective_range = BenefitSponsors.tidy_date_range(new_effective_period, :effective_period)
        write_attribute(:effective_period, effective_range) unless effective_range.blank?
      end

      def open_enrollment_period=(new_open_enrollment_period)
        open_enrollment_range = BenefitSponsors.tidy_date_range(new_open_enrollment_period, :open_enrollment_period)
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

      aasm do
        state :draft, initial: true

        state :publish_pending      # Plan application as submitted has warnings
        state :eligibility_review   # Plan application was submitted with warning and is under review by HBX officials
        state :published,         :after_enter => :accept_application     # Plan is finalized. Employees may view benefits, but not enroll
        state :published_invalid, :after_enter => :decline_application    # Non-compliant plan application was forced-published

        state :enrolling, :after_enter => :send_employee_invites          # Published plan has entered open enrollment
        state :enrolled,  :after_enter => [:ratify_enrollment, :initial_employer_open_enrollment_completed] # Published plan open enrollment has ended and is eligible for coverage,
                                                                          #   but effective date is in future
        state :application_ineligible, :after_enter => :deny_enrollment   # Application is non-compliant for enrollment
        state :expired              # Non-published plans are expired following their end on date
        state :canceled             # Published plan open enrollment has ended and is ineligible for coverage
        state :active               # Published plan year is in-force

        state :renewing_draft, :after_enter => :renewal_group_notice # renewal_group_notice - Sends a notice three months prior to plan year renewing
        state :renewing_published
        state :renewing_publish_pending
        state :renewing_enrolling, :after_enter => [:trigger_passive_renewals, :send_employee_invites]
        state :renewing_enrolled, :after_enter => :renewal_employer_open_enrollment_completed
        state :renewing_application_ineligible, :after_enter => :deny_enrollment  # Renewal application is non-compliant for enrollment
        state :renewing_canceled

        state :suspended            # Premium payment is 61-90 days past due and coverage is currently not in effect
        state :terminated           # Coverage under this application is terminated
        state :conversion_expired   # Conversion employers who did not establish eligibility in a timely manner

        event :activate, :after => :record_transition do
          transitions from: [:published, :enrolling, :enrolled, :renewing_published, :renewing_enrolling, :renewing_enrolled],  to: :active,  :guard  => :can_be_activated?
        end

        event :expire, :after => :record_transition do
          transitions from: [:published, :enrolling, :enrolled, :active],  to: :expired,  :guard  => :can_be_expired?
        end

        # Time-based transitions: Change enrollment state, in-force plan year and clean house on any plan year applications from prior year
        event :advance_date, :after => :record_transition do
          transitions from: :enrolled,  to: :active,                  :guard  => :is_event_date_valid?
          transitions from: :published, to: :enrolling,               :guard  => :is_event_date_valid?
          transitions from: :enrolling, to: :enrolled,                :guards => [:is_open_enrollment_closed?, :is_enrollment_valid?]
          transitions from: :enrolling, to: :application_ineligible,  :guard => :is_open_enrollment_closed?, :after => [:initial_employer_ineligibility_notice, :notify_employee_of_initial_employer_ineligibility]
          # transitions from: :enrolling, to: :canceled,  :guard  => :is_open_enrollment_closed?, :after => :deny_enrollment  # Talk to Dan

          transitions from: :active, to: :terminated, :guard => :is_event_date_valid?
          transitions from: [:draft, :ineligible, :publish_pending, :published_invalid, :eligibility_review], to: :expired, :guard => :is_plan_year_end?

          transitions from: :renewing_enrolled,   to: :active,              :guard  => :is_event_date_valid?
          transitions from: :renewing_published,  to: :renewing_enrolling,  :guard  => :is_event_date_valid?
          transitions from: :renewing_enrolling,  to: :renewing_enrolled,   :guards => [:is_open_enrollment_closed?, :is_enrollment_valid?]
          transitions from: :renewing_enrolling,  to: :renewing_application_ineligible, :guard => :is_open_enrollment_closed?, :after => [:renewal_employer_ineligibility_notice, :zero_employees_on_roster]

          transitions from: :enrolling, to: :enrolling  # prevents error when plan year is already enrolling
        end

        ## Application eligibility determination process

        # Submit plan year application
        event :publish, :after => :record_transition do
          transitions from: :draft, to: :draft,     :guard => :is_application_unpublishable?
          transitions from: :draft, to: :enrolling, :guard => [:is_application_eligible?, :is_event_date_valid?], :after => [:accept_application, :initial_employer_approval_notice, :zero_employees_on_roster]
          transitions from: :draft, to: :published, :guard => :is_application_eligible?, :after => [:initial_employer_approval_notice, :zero_employees_on_roster]
          transitions from: :draft, to: :publish_pending

          transitions from: :renewing_draft, to: :renewing_draft,     :guard => :is_application_unpublishable?
          transitions from: :renewing_draft, to: :renewing_enrolling, :guard => [:is_application_eligible?, :is_event_date_valid?], :after => [:accept_application, :trigger_renewal_notice, :zero_employees_on_roster]
          transitions from: :renewing_draft, to: :renewing_published, :guard => :is_application_eligible? , :after => [:trigger_renewal_notice, :zero_employees_on_roster]
          transitions from: :renewing_draft, to: :renewing_publish_pending
        end

        # Returns plan to draft state (or) renewing draft for edit
        event :withdraw_pending, :after => :record_transition do
          transitions from: :publish_pending, to: :draft
          transitions from: :renewing_publish_pending, to: :renewing_draft
        end

        # Plan as submitted failed eligibility check
        event :force_publish, :after => :record_transition do
          transitions from: :publish_pending, to: :published_invalid

          transitions from: :draft, to: :draft,     :guard => :is_application_invalid?
          transitions from: :draft, to: :enrolling, :guard => [:is_application_eligible?, :is_event_date_valid?], :after => [:accept_application, :zero_employees_on_roster]
          transitions from: :draft, to: :published, :guard => :is_application_eligible?, :after => :zero_employees_on_roster
          transitions from: :draft, to: :publish_pending, :after => :initial_employer_denial_notice

          transitions from: :renewing_draft, to: :renewing_draft,     :guard => :is_application_invalid?
          transitions from: :renewing_draft, to: :renewing_enrolling, :guard => [:is_application_eligible?, :is_event_date_valid?], :after => [:accept_application, :trigger_renewal_notice, :zero_employees_on_roster]
          transitions from: :renewing_draft, to: :renewing_published, :guard => :is_application_eligible?, :after => [:trigger_renewal_notice, :zero_employees_on_roster]
          transitions from: :renewing_draft, to: :renewing_publish_pending, :after => [:employer_renewal_eligibility_denial_notice, :notify_employee_of_renewing_employer_ineligibility]
        end

        # Employer requests review of invalid application determination
        event :request_eligibility_review, :after => :record_transition do
          transitions from: :published_invalid, to: :eligibility_review, :guard => :is_within_review_period?
        end

        # Upon review, application ineligible status overturned and deemed eligible
        event :grant_eligibility, :after => :record_transition do
          transitions from: :eligibility_review, to: :published
        end

        # Upon review, submitted application ineligible status verified ineligible
        event :deny_eligibility, :after => :record_transition do
          transitions from: :eligibility_review, to: :published_invalid
        end

        # Enrollment processed stopped due to missing binder payment
        event :cancel, :after => :record_transition do
          transitions from: [:draft, :published, :enrolling, :enrolled, :active], to: :canceled
        end

        # Coverage disabled due to non-payment
        event :suspend, :after => :record_transition do
          transitions from: :active, to: :suspended
        end

        # Coverage terminated due to non-payment
        event :terminate, :after => :record_transition do
          transitions from: [:active, :suspended], to: :terminated
        end

        # Coverage reinstated
        event :reinstate_plan_year, :after => :record_transition do
          transitions from: :terminated, to: :active, after: :reset_termination_and_end_date
        end

        event :renew_plan_year, :after => :record_transition do
          transitions from: :draft, to: :renewing_draft
        end

        event :renew_publish, :after => :record_transition do
          transitions from: :renewing_draft, to: :renewing_published
        end

        # Admin ability to reset plan year application
        event :revert_application, :after => :revert_employer_profile_application do
          transitions from: [
                                :enrolled, :enrolling, :active, :application_ineligible,
                                :renewing_application_ineligible, :published_invalid,
                                :eligibility_review, :published, :publish_pending
                              ], to: :draft, :after => [:cancel_enrollments]
        end

        # Admin ability to accept application and successfully complete enrollment
        event :enroll, :after => :record_transition do
          transitions from: [:published, :enrolling, :renewing_published], to: :enrolled
        end

        # Admin ability to reset renewing plan year application
        event :revert_renewal, :after => :record_transition do
          transitions from: [:active, :renewing_published, :renewing_enrolling,
            :renewing_application_ineligible, :renewing_enrolled], to: :renewing_draft, :after => [:cancel_enrollments]
        end

        event :cancel_renewal, :after => :record_transition do
          transitions from: [:renewing_draft, :renewing_published, :renewing_enrolling, :renewing_application_ineligible, :renewing_enrolled, :renewing_publish_pending], to: :renewing_canceled
        end

        event :conversion_expire, :after => :record_transition do
          transitions from: [:expired, :active], to: :conversion_expired, :guard => :can_be_migrated?
        end
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
