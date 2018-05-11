module BenefitSponsors
  module BenefitApplications
    class BenefitApplication
      include Mongoid::Document
      include Mongoid::Timestamps
      include AASM
      include BenefitApplicationStateMachineHelper
      include BenefitSponsors::Concerns::RecordTransition

      PUBLISHED = %w(published enrolling enrolled active suspended)
      RENEWING  = %w(renewing_draft renewing_published renewing_enrolling renewing_enrolled renewing_publish_pending)
      RENEWING_PUBLISHED_STATE = %w(renewing_published renewing_enrolling renewing_enrolled)

      INELIGIBLE_FOR_EXPORT_STATES = %w(draft publish_pending eligibility_review published_invalid canceled renewing_draft suspended terminated application_ineligible renewing_application_ineligible renewing_canceled conversion_expired renewing_enrolling enrolling)

      OPEN_ENROLLMENT_STATE   = %w(enrolling renewing_enrolling)
      INITIAL_ENROLLING_STATE = %w(publish_pending eligibility_review published published_invalid enrolling enrolled)
      INITIAL_ELIGIBLE_STATE  = %w(published enrolling enrolled)

      # The date range when this application is active
      field :effective_period,        type: Range

      # The date range when members may enroll in benefit products
      # Stored locally to enable sponsor-level exceptions
      field :open_enrollment_period,  type: Range

      # The date on which this application was canceled or terminated
      field :terminated_on,           type: Date

      # This application's workflow status
      field :aasm_state,              type: String,   default: :draft

      # Calculated Fields for DataTable
      field :enrolled_summary,        type: Integer,  default: 0
      field :waived_summary,          type: Integer,  default: 0

      # Sponsor self-reported number of full-time employees
      field :fte_count, type: Integer, default: 0

      # Sponsor self-reported number of part-time employess
      field :pte_count, type: Integer, default: 0

      # Sponsor self-reported number of Medicare Second Payers
      field :msp_count, type: Integer, default: 0

      # # SIC code, Rating Area, Service Area frozen when the plan year is published,
      field :recorded_sic_code,            type: String


      # Create a doubly-linked list of application chain:
      # predecessor_application is nil if it's the first in an application chain without
      # gaps in dates.  Otherwise, it references the preceding application that it replaces
      # successor_application is nil if this is the last in an application chain without
      # gaps in dates.  Otherwise, it references the application which immediately follows
      has_one     :predecessor_application, inverse_of: :successor_application,
                  class_name: "BenefitSponsors::BenefitApplications::BenefitApplication"

      belongs_to  :successor_application, inverse_of: :predecessor_application,
                  class_name: "BenefitSponsors::BenefitApplications::BenefitApplication"

      belongs_to  :recorded_rating_area,
                  :counter_cache: true,
                  class_name: "::BenefitMarkets::Locations::RatingArea"

      belongs_to  :recorded_service_area,
                  :counter_cache: true,
                  class_name: "::BenefitMarkets::Locations::ServiceArea"

      belongs_to  :benefit_sponsorship,
                  counter_cache: true,
                  class_name: "::BenefitSponsors::BenefitSponsorships::BenefitSponsorship"

      embeds_one  :benefit_sponsor_catalog,
                  class_name: "::BenefitMarkets::BenefitSponsorCatalog"

      embeds_many :benefit_packages,
                  class_name: "BenefitSponsors::BenefitPackages::BenefitPackage"

      validates_presence_of :effective_period, :open_enrollment_period

      validate :validate_application_dates
      # validate :open_enrollment_date_checks

      index({ "effective_period.min" => 1, "effective_period.max" => 1 }, { name: "effective_period" })
      index({ "open_enrollment_period.min" => 1, "open_enrollment_period.max" => 1 }, { name: "open_enrollment_period" })

      scope :by_open_enrollment_end_date,     ->(end_on) { where(:"effective_period.max" => end_on) }
      scope :by_effective_date,               ->(effective_date)    { where(:"effective_period.min" => effective_date) }
      scope :by_effective_date_range,         ->(begin_on, end_on)  { where(:"effective_period.min".gte => begin_on, :"effective_period.min".lte => end_on) }

      scope :published,                       ->{ any_in(aasm_state: PUBLISHED) }
      scope :renewing,                        ->{ any_in(aasm_state: RENEWING) }
      scope :renewing_published_state,        ->{ any_in(aasm_state: RENEWING_PUBLISHED_STATE) }
      scope :published_or_renewing_published, ->{ any_of([published.selector, renewing_published_state.selector]) }

      scope :published_benefit_applications_within_date_range, ->(begin_on, end_on) {
        where(
          "$and" => [
            {:aasm_state.in => PUBLISHED },
            {"$or" => [
              { :effective_period.min => {"$gte" => begin_on, "$lte" => end_on }},
              { :effective_period.max => {"$gte" => begin_on, "$lte" => end_on }}
            ]
          }
        ]
        )
      }

      scope :published_plan_years_by_date, ->(date) {
        where(
          "$and" => [
            {:aasm_state.in => PUBLISHED },
            {:"effective_period.min".lte => date, :"effective_period.max".gte => date}
          ]
          )
      }

      scope :published_and_expired_plan_years_by_date, ->(date) {
        where(
          "$and" => [
            {:aasm_state.in => PUBLISHED + ['expired'] },
            {:"effective_period.min".lte => date, :"effective_period.max".gte => date}
          ]
          )
      }

      # Build a new application instance along with all associated child model instances, for the
      # benefit period immediately following this application, applying the benefit_sponsor_catalog
      # renewal attributes
      # Service and rating areas are assgiend from the benefit_sponsorhip to pick up when sponsor
      # changes primary office location following the prior application
      def renew(benefit_sponsor_catalog)

        renewal_application = benefit_sponsorship.benefit_applications.new(
            fte_count:                fte_count,
            pte_count:                pte_count,
            msp_count:                msp_count,
            benefit_sponsor_catalog:  benefit_sponsor_catalog,
            preceding_application:    self,
            recorded_service_area:    benefit_sponsorship.service_area,
            recorded_rating_area:     benefit_sponsorship.rating_area,
            # effective_period:
            # open_enrollment_period:
          )

        benefit_packages.each do |benefit_package|
          renewal_application.benefit_packages << benefit_package.renew
        end
      end

      def terminate

      end

      def reinstate

      end

      # after_update :update_employee_benefit_packages
      # TODO: Refactor code into benefit package updater
      def update_employee_benefit_packages
        if self.start_on_changed?
          bg_ids = self.benefit_groups.pluck(:_id)
          employees = CensusEmployee.where({ :"benefit_group_assignments.benefit_group_id".in => bg_ids })
          employees.each do |census_employee|
            census_employee.benefit_group_assignments.where(:benefit_group_id.in => bg_ids).each do |assignment|
              assignment.update(start_on: self.start_on)
              assignment.update(end_on: self.end_on) if assignment.end_on.present?
            end
          end
        end
      end

      def start_on
        effective_period.begin
      end

      def end_on
        effective_period.end
      end

      def open_enrollment_start_on
        open_enrollment_period.min
      end

      def open_enrollment_end_on
        open_enrollment_period.max
      end

      def effective_date
        effective_period.begin unless effective_period.blank?
      end

      def is_renewing?
        RENEWING.include?(aasm_state)
      end

      def employer_profile
        benefit_sponsorship.benefit_sponsorable
      end

      def effective_period=(new_effective_period)
        effective_range = BenefitSponsors.tidy_date_range(new_effective_period, :effective_period)
        super(effective_range) unless effective_range.blank?
      end

      def open_enrollment_period=(new_open_enrollment_period)
        open_enrollment_range = BenefitSponsors.tidy_date_range(new_open_enrollment_period, :open_enrollment_period)
        super(open_enrollment_range) unless open_enrollment_range.blank?
      end

      def eligible_for_export?
        return false if self.aasm_state.blank?
        return false if self.is_conversion
        !INELIGIBLE_FOR_EXPORT_STATES.include?(self.aasm_state.to_s)
      end

      def overlapping_published_plan_years
        benefit_sponsorship.benefit_applications.published_benefit_applications_within_date_range(start_on, end_on)
      end

      def overlapping_published_plan_year?
        self.benefit_sponsorship.benefit_applications.published_or_renewing_published.any? do |benefit_application|
          benefit_application.effective_period.cover?(self.start_on) && (benefit_application != self)
        end
      end

      ## Stub for BQT
      def estimate_group_size?
        true
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

      def default_benefit_group
        benefit_groups.detect(&:default)
      end

      def employee_participation_percent
        return "-" if eligible_to_enroll_count == 0
        "#{(total_enrolled_count / eligible_to_enroll_count.to_f * 100).round(2)}%"
      end

      def employee_participation_percent_based_on_summary
        return "-" if eligible_to_enroll_count == 0
        "#{(enrolled_summary / eligible_to_enroll_count.to_f * 100).round(2)}%"
      end

      # TODO: Fix this method
      def minimum_employer_contribution
        unless benefit_packages.size == 0
          benefit_packages.map do |benefit_package|
            if benefit_package#.sole_source?
              OpenStruct.new(:premium_pct => 100)
            else
              benefit_package.relationship_benefits.select do |relationship_benefit|
                relationship_benefit.relationship == "employee"
              end.min_by do |relationship_benefit|
                relationship_benefit.premium_pct
              end
            end
          end.map(&:premium_pct).first
        end
      end

      def to_plan_year
        BenefitApplicationToPlanYearConverter.new(self).call
      end

      def filter_active_enrollments_by_date(date)
        enrollment_proxies = BenefitApplicationEnrollmentsQuery.new(self).call(Family, date)
        return [] if (enrollment_proxies.count > 100)
        enrollment_proxies.map do |ep|
          OpenStruct.new(ep)
        end
      end

      def hbx_enrollments_by_month(date)
        BenefitApplicationEnrollmentsMonthlyQuery.new(self).call(date)
      end

      aasm do
        state :draft, initial: true

        state :publish_pending      # Plan application as submitted has warnings
        state :eligibility_review   # Plan application was submitted with warning and is under review by HBX officials
        state :published#,         :after_enter => :accept_application     # Plan is finalized. Employees may view benefits, but not enroll
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

        event :activate do
          transitions from: [:published, :enrolling, :enrolled, :renewing_published, :renewing_enrolling, :renewing_enrolled],  to: :active,  :guard  => :can_be_activated?
        end

        event :expire do
          transitions from: [:published, :enrolling, :enrolled, :active],  to: :expired,  :guard  => :can_be_expired?
        end

        # Time-based transitions: Change enrollment state, in-force plan year and clean house on any plan year applications from prior year
        event :advance_date do
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
        event :publish do
          transitions from: :draft, to: :draft,     :guard => :is_application_unpublishable?
          transitions from: :draft, to: :enrolling, :guard => [:is_application_eligible?, :is_event_date_valid?]#, :after => [:accept_application, :initial_employer_approval_notice, :zero_employees_on_roster]
          transitions from: :draft, to: :published, :guard => :is_application_eligible?#, :after => [:initial_employer_approval_notice, :zero_employees_on_roster]
          transitions from: :draft, to: :publish_pending

          transitions from: :renewing_draft, to: :renewing_draft,     :guard => :is_application_unpublishable?
          transitions from: :renewing_draft, to: :renewing_enrolling, :guard => [:is_application_eligible?, :is_event_date_valid?], :after => [:accept_application, :trigger_renewal_notice, :zero_employees_on_roster]
          transitions from: :renewing_draft, to: :renewing_published, :guard => :is_application_eligible? , :after => [:trigger_renewal_notice, :zero_employees_on_roster]
          transitions from: :renewing_draft, to: :renewing_publish_pending
        end

        # Returns plan to draft state (or) renewing draft for edit
        event :withdraw_pending do
          transitions from: :publish_pending, to: :draft
          transitions from: :renewing_publish_pending, to: :renewing_draft
        end

        # Plan as submitted failed eligibility check
        event :force_publish do
          transitions from: :publish_pending, to: :published_invalid

          transitions from: :draft, to: :draft,     :guard => :is_application_invalid?
          transitions from: :draft, to: :enrolling, :guard => [:is_application_eligible?, :is_event_date_valid?]#, :after => [:accept_application, :zero_employees_on_roster]
          transitions from: :draft, to: :published, :guard => :is_application_eligible?#, :after => :zero_employees_on_roster
          transitions from: :draft, to: :publish_pending#, :after => :initial_employer_denial_notice

          transitions from: :renewing_draft, to: :renewing_draft,     :guard => :is_application_invalid?
          transitions from: :renewing_draft, to: :renewing_enrolling, :guard => [:is_application_eligible?, :is_event_date_valid?], :after => [:accept_application, :trigger_renewal_notice, :zero_employees_on_roster]
          transitions from: :renewing_draft, to: :renewing_published, :guard => :is_application_eligible?, :after => [:trigger_renewal_notice, :zero_employees_on_roster]
          transitions from: :renewing_draft, to: :renewing_publish_pending, :after => [:employer_renewal_eligibility_denial_notice, :notify_employee_of_renewing_employer_ineligibility]
        end

        # Employer requests review of invalid application determination
        event :request_eligibility_review do
          transitions from: :published_invalid, to: :eligibility_review, :guard => :is_within_review_period?
        end

        # Upon review, application ineligible status overturned and deemed eligible
        event :grant_eligibility do
          transitions from: :eligibility_review, to: :published
        end

        # Upon review, submitted application ineligible status verified ineligible
        event :deny_eligibility do
          transitions from: :eligibility_review, to: :published_invalid
        end

        # Enrollment processed stopped due to missing binder payment
        event :cancel do
          transitions from: [:draft, :published, :enrolling, :enrolled, :active], to: :canceled
        end

        # Coverage disabled due to non-payment
        event :suspend do
          transitions from: :active, to: :suspended
        end

        # Coverage terminated due to non-payment
        event :terminate do
          transitions from: [:active, :suspended], to: :terminated
        end

        # Coverage reinstated
        event :reinstate_plan_year do
          transitions from: :terminated, to: :active, after: :reset_termination_and_end_date
        end

        event :renew_plan_year do
          transitions from: :draft, to: :renewing_draft
        end

        event :renew_publish do
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
        event :enroll do
          transitions from: [:published, :enrolling, :renewing_published], to: :enrolled
        end

        # Admin ability to reset renewing plan year application
        event :revert_renewal do
          transitions from: [:active, :renewing_published, :renewing_enrolling,
            :renewing_application_ineligible, :renewing_enrolled], to: :renewing_draft, :after => [:cancel_enrollments]
        end

        event :cancel_renewal do
          transitions from: [:renewing_draft, :renewing_published, :renewing_enrolling, :renewing_application_ineligible, :renewing_enrolled, :renewing_publish_pending], to: :renewing_canceled
        end

        event :conversion_expire do
          transitions from: [:expired, :active], to: :conversion_expired, :guard => :can_be_migrated?
        end
      end

      class << self
        def find(id)
          BenefitSponsors::BenefitApplications::BenefitApplication.where(id: BSON::ObjectId.from_string(id)).first
        end
      end

      def due_date_for_publish
        if benefit_sponsorship.benefit_applications.renewing.any?
          Date.new(start_on.prev_month.year, start_on.prev_month.month, Settings.aca.shop_market.renewal_application.publish_due_day_of_month)
        else
          Date.new(start_on.prev_month.year, start_on.prev_month.month, Settings.aca.shop_market.initial_application.publish_due_day_of_month)
        end
      end

      def is_application_eligible?
        application_eligibility_warnings.blank?
      end

      def is_publish_date_valid?
        event_name = aasm.current_event.to_s.gsub(/!/, '')
        event_name == "force_publish" ? true : (TimeKeeper.datetime_of_record <= due_date_for_publish.end_of_day)
      end

      def assigned_census_employees
        benefit_packages.flat_map(){ |benefit_package| benefit_package.census_employees.active }
      end

      #TODO: FIX this
      def assigned_census_employees_without_owner
        benefit_packages#.flat_map(){ |benefit_package| benefit_package.census_employees.active.non_business_owner }
      end

      def open_enrollment_date_errors
        errors = {}

        if is_renewing?
          minimum_length = Settings.aca.shop_market.renewal_application.open_enrollment.minimum_length.days
          enrollment_end = Settings.aca.shop_market.renewal_application.monthly_open_enrollment_end_on
        else
          minimum_length = Settings.aca.shop_market.open_enrollment.minimum_length.days
          enrollment_end = Settings.aca.shop_market.open_enrollment.monthly_end_on
        end

        if (open_enrollment_end_on - (open_enrollment_start_on - 1.day)).to_i < minimum_length
          log_message(errors) {{open_enrollment_period: "Open Enrollment period is shorter than minimum (#{minimum_length} days)"}}
        end

        if open_enrollment_end_on > Date.new(start_on.prev_month.year, start_on.prev_month.month, enrollment_end)
          log_message(errors) {{open_enrollment_period: "Open Enrollment must end on or before the #{enrollment_end.ordinalize} day of the month prior to effective date"}}
        end

        errors
      end

      # Check plan year for violations of model integrity relative to publishing
      def application_errors
        errors = {}

        if open_enrollment_end_on > (open_enrollment_start_on + (Settings.aca.shop_market.open_enrollment.maximum_length.months).months)
          log_message(errors){{open_enrollment_period: "Open Enrollment period is longer than maximum (#{Settings.aca.shop_market.open_enrollment.maximum_length.months} months)"}}
        end

        # if benefit_packages.any?{|bg| bg.reference_plan_id.blank? }
        #   log_message(errors){{benefit_packages: "Reference plans have not been selected for benefit packages. Please edit the benefit application and select reference plans."}}
        # end

        if benefit_packages.blank?
          log_message(errors) {{benefit_packages: "You must create at least one benefit package to publish a plan year"}}
        end

        # if benefit_sponsorship.census_employees.active.to_set != assigned_census_employees.to_set
        #   log_message(errors) {{benefit_packages: "Every employee must be assigned to a benefit package defined for the published plan year"}}
        # end

        if benefit_sponsorship.ineligible?
          log_message(errors) {{benefit_sponsorship:  "This employer is ineligible to enroll for coverage at this time"}}
        end

        if overlapping_published_plan_year?
          log_message(errors) {{ publish: "You may only have one published benefit application at a time" }}
        end

        if !is_publish_date_valid?
          log_message(errors) {{publish: "Plan year starting on #{start_on.strftime("%m-%d-%Y")} must be published by #{due_date_for_publish.strftime("%m-%d-%Y")}"}}
        end

        errors
      end

      # Check plan year application for regulatory compliance
      def application_eligibility_warnings
        warnings = {}
        unless benefit_sponsorship.profile.is_primary_office_local?
          warnings.merge!({primary_office_location: "Has its principal business address in the #{Settings.aca.state_name} and offers coverage to all full time employees through #{Settings.site.short_name} or Offers coverage through #{Settings.site.short_name} to all full time employees whose Primary worksite is located in the #{Settings.aca.state_name}"})
        end

        # Application is in ineligible state from prior enrollment activity
        if aasm_state == "application_ineligible" || aasm_state == "renewing_application_ineligible"
          warnings.merge!({ineligible: "Application did not meet eligibility requirements for enrollment"})
        end

        # Maximum company size at time of initial registration on the HBX
        if !(is_renewing?) && (fte_count > Settings.aca.shop_market.small_market_employee_count_maximum)
          warnings.merge!({ fte_count: "Has #{Settings.aca.shop_market.small_market_employee_count_maximum} or fewer full time equivalent employees" })
        end

        # Exclude Jan 1 effective date from certain checks
        unless effective_date.yday == 1
          # Employer contribution toward employee premium must meet minimum
          # TODO: FIX this once minimum_employer_contribution is fixed
          # if benefit_packages.size > 0 && (minimum_employer_contribution < Settings.aca.shop_market.employer_contribution_percent_minimum)
            # warnings.merge!({ minimum_employer_contribution:  "Employer contribution percent toward employee premium (#{minimum_employer_contribution.to_i}%) is less than minimum allowed (#{Settings.aca.shop_market.employer_contribution_percent_minimum.to_i}%)" })
          # end
        end

        warnings
      end

      # TODO review this
      def validate_application_dates
        return if canceled? || expired? || renewing_canceled?
        return if effective_period.blank? || open_enrollment_period.blank?
        # return if imported_plan_year

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

        if !['canceled', 'suspended', 'terminated'].include?(aasm_state)
          #groups terminated for non-payment get 31 more days of coverage from their paid through date
          if end_on != end_on.end_of_month
            errors.add(:end_on, "must be last day of the month")
          end

          if end_on != (start_on + Settings.aca.shop_market.benefit_period.length_minimum.year.years - 1.day)
            errors.add(:end_on, "plan year period should be: #{duration_in_days(Settings.aca.shop_market.benefit_period.length_minimum.year.years - 1.day)} days")
          end
        end
      end

      private

      def log_message(errors)
        msg = yield.first
        (errors[msg[0]] ||= []) << msg[1]
      end
    end
  end
end
