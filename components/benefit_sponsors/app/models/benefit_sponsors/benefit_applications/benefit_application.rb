module BenefitSponsors
  module BenefitApplications
    class BenefitApplication
      include Mongoid::Document
      include Mongoid::Timestamps
      # include BenefitSponsors::Concerns::RecordTransition
      include AASM

      APPLICATION_EXCEPTION_STATES  = [:pending, :assigned, :processing, :reviewing, :information_needed, :appealing].freeze
      APPLICATION_DRAFT_STATES      = [:draft] + APPLICATION_EXCEPTION_STATES.freeze
      APPLICATION_APPROVED_STATES   = [:approved].freeze
      ENROLLING_STATES              = [:enrollment_open, :enrollment_closed].freeze
      ENROLLMENT_ELIGIBLE_STATES    = [:enrollment_eligible].freeze
      ENROLLMENT_INELIGIBLE_STATES  = [:enrollment_ineligible].freeze
      COVERAGE_EFFECTIVE_STATES     = [:active].freeze
      TERMINATED_STATES             = [:denied, :suspended, :terminated, :canceled, :expired].freeze
      EXPIRED_STATES                = [:expired].freeze

      PUBLISHED_STATES = ENROLLMENT_ELIGIBLE_STATES + APPLICATION_APPROVED_STATES + ENROLLING_STATES + COVERAGE_EFFECTIVE_STATES

      APPROVED_STATES           = [:approved, :enrollment_open, :enrollment_closed, :enrollment_eligible, :active, :suspended].freeze
      # INELIGIBLE_FOR_EXPORT_STATES = %w(draft publish_pending eligibility_review published_invalid canceled renewing_draft suspended terminated application_ineligible renewing_application_ineligible renewing_canceled conversion_expired renewing_enrolling enrolling)


      # The date range when this application is active
      field :effective_period,        type: Range

      # The date range when members may enroll in benefit products
      # Stored locally to enable sponsor-level exceptions
      field :open_enrollment_period,  type: Range

      # The date on which this application was canceled or terminated
      field :terminated_on,           type: Date

      # This application's workflow status
      field :aasm_state,              type: Symbol,   default: :draft

      # Calculated Fields for DataTable
      field :enrolled_summary,        type: Integer,  default: 0
      field :waived_summary,          type: Integer,  default: 0

      # Sponsor self-reported number of full-time employees
      field :fte_count,               type: Integer,  default: 0

      # Sponsor self-reported number of part-time employess
      field :pte_count,               type: Integer,  default: 0

      # Sponsor self-reported number of Medicare Second Payers
      field :msp_count,               type: Integer,  default: 0

      # Sponsor's Standard Industry Classification code for period covered by this
      # applciation
      field :recorded_sic_code,       type: String


      # Create a doubly-linked list of application chain:
      #   predecessor_application is nil if it's the first in an application chain without
      #   gaps in dates.  Otherwise, it references the preceding application that it replaces
      #   successor_applications are nil if this is the last in an application chain without
      #   gaps in dates.  Otherwise, it references the applications which immediately follow.
      #   An application may have multiple successors, but only one may be active at once
      belongs_to  :predecessor_application, inverse_of: :successor_applications,
                  class_name: "BenefitSponsors::BenefitApplications::BenefitApplication"

      has_many    :successor_applications, inverse_of: :predecessor_application,
                  counter_cache: true,
                  class_name: "BenefitSponsors::BenefitApplications::BenefitApplication"

      belongs_to  :recorded_rating_area,
                  class_name: "::BenefitMarkets::Locations::RatingArea"

      has_and_belongs_to_many  :recorded_service_areas,
                  class_name: "::BenefitMarkets::Locations::ServiceArea"

      belongs_to  :benefit_sponsorship,
                  counter_cache: true,
                  class_name: "::BenefitSponsors::BenefitSponsorships::BenefitSponsorship"

      embeds_one  :benefit_sponsor_catalog,
                  class_name: "::BenefitMarkets::BenefitSponsorCatalog"

      embeds_many :benefit_packages,
                  class_name: "BenefitSponsors::BenefitPackages::BenefitPackage"

      validates_presence_of :effective_period, :open_enrollment_period, :recorded_service_areas, :recorded_rating_area

      index({ "aasm_state" => 1 })
      index({ "effective_period.min" => 1, "effective_period.max" => 1 }, { name: "effective_period" })
      index({ "open_enrollment_period.min" => 1, "open_enrollment_period.max" => 1 }, { name: "open_enrollment_period" })

      # Load the
      # after_initialize :set_values

      def set_values
        recorded_sic_code     = benefit_sponsorship.sic_code unless recorded_sic_code.present?
        recorded_rating_area  = benefit_sponsorship.rating_area unless recorded_rating_area.present?
        recorded_service_areas = benefit_sponsorship.service_areas unless recorded_service_areas.present?
      end

      # Use chained scopes, for example: approved.effective_date_begin_on(start, end)
      scope :plan_design_draft,               ->{ any_in(aasm_state: APPLICATION_DRAFT_STATES) }
      scope :plan_design_approved,            ->{ any_in(aasm_state: APPLICATION_APPROVED_STATES) }
      scope :plan_design_exception,           ->{ any_in(aasm_state: APPLICATION_EXCEPTION_STATES) }
      scope :enrolling,                       ->{ any_in(aasm_state: ENROLLING_STATES) }
      scope :enrollment_eligible,             ->{ any_in(aasm_state: ENROLLMENT_ELIGIBLE_STATES) }
      scope :enrollment_ineligible,           ->{ any_in(aasm_state: ENROLLMENT_INELIGIBLE_STATES) }
      scope :coverage_effective,              ->{ any_in(aasm_state: COVERAGE_EFFECTIVE_STATES) }
      scope :terminated,                      ->{ any_in(aasm_state: TERMINATED_STATES) }
      scope :non_canceled,                    ->{ not_in(aasm_state: TERMINATED_STATES) }

      scope :expired,                         ->{ any_in(aasm_state: EXPIRED_STATES) }

      scope :is_renewing,                     ->{ where(:predecessor_application => {:$exists => true},
                                                        :aasm_state.in => APPLICATION_DRAFT_STATES + ENROLLING_STATES).order_by(:'created_at'.desc)
                                                            }

      scope :effective_date_begin_on,         ->(compare_date = TimeKeeper.date_of_record) { where(
                                                              :"effective_period.min" => compare_date )
                                                            }
      scope :effective_period_cover,          ->(compare_date = TimeKeeper.date_of_record) { where(
                                                              :"effective_period.min".gte => compare_date,
                                                              :"effective_period.max".lte => compare_date)
                                                            }
      scope :open_enrollment_period_cover,    ->(compare_date = TimeKeeper.date_of_record) { where(
                                                              :"opem_enrollment_period.min".gte => compare_date,
                                                              :"opem_enrollment_period.max".lte => compare_date)
                                                            }
      scope :open_enrollment_begin_on,          ->(compare_date = TimeKeeper.date_of_record) { where(
                                                              :"open_enrollment_period.min" => compare_date)
                                                            }
      scope :open_enrollment_end_on,          ->(compare_date = TimeKeeper.date_of_record) { where(
                                                              :"open_enrollment_period.max" => compare_date)
                                                            }
      # TODO
      scope :published,                       ->{ any_in(aasm_state: PUBLISHED_STATES) }
      scope :renewing,                        ->{ is_renewing } # Deprecate it in future

      # scope :by_effective_date_range,         ->(begin_on, end_on)  { where(:"effective_period.min".gte => begin_on, :"effective_period.min".lte => end_on) }
      # scope :renewing,                        ->{ any_in(aasm_state: RENEWING) }
      # scope :renewing_published_state,        ->{ any_in(aasm_state: RENEWING_APPROVED_STATE) }
      # scope :published_or_renewing_published, ->{ any_of([published.selector, renewing_published_state.selector]) }

      scope :published_benefit_applications_within_date_range, ->(begin_on, end_on) {
        where(
          "$and" => [
            {:aasm_state.in => APPROVED_STATES },
            {"$or" => [
              { :effective_period.min => {"$gte" => begin_on, "$lte" => end_on }},
              { :effective_period.max => {"$gte" => begin_on, "$lte" => end_on }}
            ]
          }
        ]
        )
      }

      # scope :published_plan_years_by_date, ->(date) {
      #   where(
      #     "$and" => [
      #       {:aasm_state.in => APPROVED_STATES },
      #       {:"effective_period.min".lte => date, :"effective_period.max".gte => date}
      #     ]
      #     )
      # }

      # scope :published_and_expired_plan_years_by_date, ->(date) {
      #   where(
      #     "$and" => [
      #       {:aasm_state.in => APPROVED_STATES + ['expired'] },
      #       {:"effective_period.min".lte => date, :"effective_period.max".gte => date}
      #     ]
      #     )
      # }

      def effective_period=(new_effective_period)
        effective_range = BenefitSponsors.tidy_date_range(new_effective_period, :effective_period)
        super(effective_range) unless effective_range.blank?
      end

      def open_enrollment_period=(new_open_enrollment_period)
        open_enrollment_range = BenefitSponsors.tidy_date_range(new_open_enrollment_period, :open_enrollment_period)
        super(open_enrollment_range) unless open_enrollment_range.blank?
      end

      def rate_schedule_date
        start_on
      end

      def start_on
        effective_period.begin unless effective_period.blank?
      end

      def end_on
        effective_period.end unless effective_period.blank?
      end

      def open_enrollment_start_on
        open_enrollment_period.min unless open_enrollment_period.blank?
      end

      def open_enrollment_end_on
        open_enrollment_period.max unless open_enrollment_period.blank?
      end

      # Reschedule the end date of open enrollment for this application.  The application must be in
      # open enrollment state already, or in an enrolling state that can transition to open enrollment.
      # Also, the new end date must be later than the existing end date, may not occur in the past, and
      # must precede the start of coverage
      #
      # @param [ Date ] new_end_date The date open enrollment for benefit selection will end
      # @return [ BenefitApplication ] Self, with the updated open enrollment period and application in
      # open enrollment state
      def extend_open_enrollment_period(new_end_date)
        if may_begin_open_enrollment? &&
           new_end_date < start_on &&
           [new_end_date, open_enrollment_end_on, TimeKeeper.date_of_record].max == new_end_date

          self.open_enrollment_period = open_enrollment_start_on..new_end_date
          begin_open_enrollment!
        end
        self
      end

      def effective_date
        start_on
      end

      def sponsor_profile
        benefit_sponsorship.profile
      end

      def default_benefit_group
        benefit_groups.detect(&:default)
      end

      def is_renewing?
        predecessor_application.present? && (APPLICATION_DRAFT_STATES + ENROLLING_STATES).include?(aasm_state)
      end

      def is_renewal_enrolling?
        predecessor_application.present? && (ENROLLING_STATES).include?(aasm_state)
      end

      def open_enrollment_contains?(date)
        open_enrollment_period.cover?(date)
      end

      # TODO Refactor -- use the new state: :open_enrollment_closed
      # def open_enrollment_completed?
      #   ::TimeKeeper.date_of_record > open_enrollment_period.end unless open_enrollment_period.blank?
      # end

      # Build a new [BenefitApplication] instance along with all associated child model instances, for the
      # benefit period immediately following this application's, applying the renewal settings
      # specified in the passed [BenefitSponsorCatalog]
      #
      # Service and rating areas are assigned from this application's BenefitSponsorship to pick up scenario
      # when Sponsor changes their primary office location during the previous enrollment effective period
      #
      # @param [ BenefitSponsorCatalog ] The catalog valid for the effective_period immediately following this
      # BenefitApplication instance's effective_period
      # @return [ BenefitApplication ] The built renewal application instance and submodels
      def renew(new_benefit_sponsor_catalog)
        if new_benefit_sponsor_catalog.effective_date != end_on + 1.day
          raise StandardError, "effective period must begin on #{end_on + 1.day}"
        end

        renewal_application = benefit_sponsorship.benefit_applications.new(
            fte_count:                fte_count,
            pte_count:                pte_count,
            msp_count:                msp_count,
            benefit_sponsor_catalog:  new_benefit_sponsor_catalog,
            predecessor_application:  self,
            recorded_service_areas:    benefit_sponsorship.service_areas,
            recorded_rating_area:     benefit_sponsorship.rating_area,
            effective_period:         new_benefit_sponsor_catalog.effective_period,
            open_enrollment_period:   new_benefit_sponsor_catalog.open_enrollment_period
          )

        benefit_packages.each do |benefit_package|
          new_benefit_package = renewal_application.benefit_packages.build
          benefit_package.renew(new_benefit_package)
        end

        renewal_application
      end

      def overlapping_published_benefit_applications
        self.sponsor_profile.benefit_applications.published_benefit_applications_within_date_range(self.start_on, self.end_on)
      end

      def renew_benefit_package_assignments
        benefit_packages.each do |benefit_package|
          predecessor_benefit_package = benefit_package.predecessor
          predecessor_effective_date  = predecessor_application.effective_period.min

          predecessor_benefit_package.census_employees_assigned_on(predecessor_effective_date).each  do |employee|
            new_benefit_package_assignment = employee.benefit_package_assignment_on(effective_period.min)
            if new_benefit_package_assignment.blank? || (benefit_package_assignment.benefit_package != benefit_package)
              census_employee.assign_to_benefit_package(benefit_package, effective_period.min)
            end
          end
        end

        benefit_sponsorship.census_employees.non_terminated.benefit_application_unassigned(self).each do |employee|
          assign_to_default_benefit_package(census_employee)
        end
      end

      def assign_to_default_benefit_package(census_employee, assignment_on = effective_period.min)
        census_employee.assign_to_benefit_package(default_benefit_package, assignment_on)
      end

      def renew_benefit_package_members
        benefit_packages.each do |benefit_package|
          member_collection = benefit_package.census_employees_assigned_on(benefit_package.effective_period.min)
          benefit_package.renew_member_benefits(member_collection)
        end
      end

      def refresh(new_benefit_sponsor_catalog)
        if benefit_sponsorship_catalog != new_benefit_sponsor_catalog

          benefit_packages.each do |benefit_package|
            benefit_package.refresh(new_benefit_sponsor_catalog)
          end

          self.benefit_sponsor_catalog = new_benefit_sponsor_catalog
        end

        self
      end

      def cancel_enrollments
      end

      def is_event_date_valid?
        today = TimeKeeper.date_of_record

        is_valid = case aasm_state
        when "approved", "draft"
          today >= open_enrollment_period.begin
        when "enrollment_open"
          today > open_enrollment_period.end
        when "enrollment_closed"
          today >= effective_period.begin
        when "active"
          today > effective_period.end
        else
          false
        end

        is_valid
      end

      aasm do
        state :draft, initial: true
        # state :renewing_draft, :after_enter => :renewal_group_notice # renewal_group_notice - Sends a notice three months prior to plan year renewing

        state :imported             # Static state for seed application instances used to transfer Benefit Sponsors and members into the system

        state :approved             # Accepted - Application meets criteria necessary for sponsored members to shop for benefits.  Members may view benefits, but not enroll
        state :denied               # Rejected

        # state :published_invalid, :after_enter => :decline_application    # Non-compliant plan application was forced-published

        # TODO: Compare optional states with CCA values for Employer Attestation approval flow
        ## Begin optional states for exception processing
        state :pending              # queued for review or verification
        state :assigned             # assigned to case worker
        state :processing           # under consideration and determination
        state :reviewing            # determination under peer or supervisory review
        state :information_needed   # returned for supplementary information
        state :appealing            # request reversal of negative determination
        ## End optional states for exception processing

        state :enrollment_open      # Approved application has entered open enrollment period
        # :after_enter => :send_employee_invites
        # state :renewing_enrolling, :after_enter => [:trigger_passive_renewals, :send_employee_invites]

        state :enrollment_closed
        state :enrollment_eligible  # Enrollment meets criteria necessary for sponsored members to effectuate selected benefits
        # :after_enter => [:ratify_enrollment, :initial_employer_open_enrollment_completed]
        # Published plan open enrollment has ended and is eligible for coverage,
                                                                          #   but effective date is in future
        # state :renewing_enrolled, :after_enter => :renewal_employer_open_enrollment_completed

        state :enrollment_ineligible, :after_enter => :deny_enrollment   # open enrollment did not meet eligibility criteria
        # state :application_ineligible,          :after_enter => :deny_enrollment   # Application is non-compliant for enrollment
        # state :renewing_application_ineligible, :after_enter => :deny_enrollment  # Renewal application is non-compliant for enrollment

        state :active               # Application benefit coverage is in-force
        state :suspended            # Coverage is no longer in effect. members may not enroll or change enrollments
        state :terminated           # Coverage under this application is terminated
        state :expired              # Non-published plans are expired following their end on date
        state :canceled             # Application closed prior to coverage taking effect

        after_all_transitions :publish_state_transition

        event :import do
          transitions from: :draft, to: :imported
        end

        # Time-based transitions: Change enrollment state, in-force plan year and clean house on any plan year applications from prior year
        event :advance_date do
          transitions from: :enrollment_eligible,                   to: :active,                 guard:   :is_event_date_valid?
          transitions from: :approved,                              to: :enrollment_open,        guard:   :is_event_date_valid?
          transitions from: [:enrollment_open, :enrollment_closed], to: :enrollment_eligible,    guards:  [:is_open_enrollment_closed?, :is_enrollment_valid?]
          transitions from: [:enrollment_open, :enrollment_closed], to: :enrollment_ineligible,  guard:   :is_open_enrollment_closed? #, :after => [:initial_employer_ineligibility_notice, :notify_employee_of_initial_employer_ineligibility]
          transitions from: :enrollment_open,                       to: :enrollment_closed,      guard:   :is_event_date_valid?

          transitions from: :active,                                to: :terminated,             guard:   :is_event_date_valid?
          transitions from: [:pending],                             to: :expired,                guard:   :is_plan_year_end?
          transitions from: :enrollment_ineligible,                 to: :canceled,               guard:   :is_plan_year_end?

          ## TODO update this renewal transition
          # transitions from: :enrollment_open,                           to: :enrollment_ineligible,  guard:  :is_open_enrollment_closed?, :after => [:renewal_employer_ineligibility_notice, :zero_employees_on_roster]

          transitions from: :enrollment_open,                       to: :enrollment_open  # avoids error when application is in enrollment_open state
        end

        ## Application eligibility determination process

        # Submit plan year application
        event :submit_application do
          transitions from: :draft, to: :enrollment_open, guard:  [:is_event_date_valid?]#, :after => [:accept_application, :initial_employer_approval_notice, :zero_employees_on_roster]
          transitions from: :draft, to: :approved #, :after => [:initial_employer_approval_notice, :zero_employees_on_roster]

          ## TODO update these renewal transitions
          # transitions from: :draft, to: :enrollment_open, guard:  [:is_application_eligible?, :is_event_date_valid?], :after => [:accept_application, :trigger_renewal_notice, :zero_employees_on_roster]
          # transitions from: :draft, to: :approved,        guard:  :is_application_eligible? , :after => [:trigger_renewal_notice, :zero_employees_on_roster]
        end

        event :review_application do
          transitions from: :draft, to: :pending
        end

        # Returns plan to draft state (or) renewing draft for edit
        event :withdraw_pending do
          transitions from: :pending, to: :draft
        end

        # Plan as submitted failed eligibility check
        event :auto_approve_application do
          transitions from: :draft, to: :draft,           guard:  :is_application_invalid?
          transitions from: :draft, to: :enrollment_open, guard:  [:is_application_eligible?, :is_event_date_valid?]#, :after => [:accept_application, :zero_employees_on_roster]
          transitions from: :draft, to: :approved,        guard:  :is_application_eligible?#, :after => :zero_employees_on_roster

          ## TODO update these renewal transitions
          # transitions from: :draft, to: :enrollment_open, guard:  [:is_application_eligible?, :is_event_date_valid?], :after => [:accept_application, :trigger_renewal_notice, :zero_employees_on_roster]
          # transitions from: :draft, to: :approved,        guard:  :is_application_eligible?, :after => [:trigger_renewal_notice, :zero_employees_on_roster]
          # transitions from: :draft, to: :pending,         :after => [:employer_renewal_eligibility_denial_notice, :notify_employee_of_renewing_employer_ineligibility]
        end

        # Employer requests review of invalid application determination
        event :request_eligibility_review do
          transitions from: :submitted, to: :pending,  guard:  :is_within_review_period?
        end

        # Upon review, application ineligible status overturned and deemed eligible
        event :approve_application do
          transitions from: APPLICATION_EXCEPTION_STATES, to: :approved
        end

        event :submit_for_review do
          transitions from: :draft, to: :pending
        end

        # Upon review, submitted application ineligible status verified ineligible
        event :deny_application do
          transitions from: APPLICATION_EXCEPTION_STATES, to: :denied
        end

        event :begin_open_enrollment do
          transitions from:   [:approved, :enrollment_open, :enrollment_closed, :enrollment_eligible, :enrollment_ineligible],
                      to:     :enrollment_open
        end

        event :end_open_enrollment do
          transitions from:   :enrollment_open,
                      to:     :enrollment_closed
        end

        event :approve_enrollment_eligiblity do
          transitions from:   ENROLLING_STATES,
                      to:     :enrollment_eligible
        end

        event :deny_enrollment_eligiblity do
          transitions from:   ENROLLING_STATES,
                      to:     :enrollment_ineligible
        end

        event :reverse_enrollment_eligiblity do
          transitions from:   :enrollment_eligible,
                      to:     :enrollment_closed
        end

        event :revert_application do #, :after => :revert_employer_profile_application do
          transitions from:   [:approved, :denied] + APPLICATION_EXCEPTION_STATES,
                      to:     :draft
        end

        event :revert_enrollment do #, :after => :revert_employer_profile_application do
          transitions from:   [
                                  :enrollment_open, :enrollment_closed,
                                  :enrollment_eligible, :enrollment_ineligible,
                                  :active,
                                ],
                      to:     :draft,
                      after:  :cancel_enrollments
        end

        event :activate_enrollment do
          transitions from:   [:enrollment_open, :enrollment_closed, :enrollment_eligible],
                      to:     :active
        end

        event :expire do
          transitions from:   [:approved, :enrollment_open, :enrollment_eligible, :active],
                      to:     :expired
        end

        # Enrollment processed stopped due to missing binder payment
        event :cancel do
          transitions from:   APPLICATION_DRAFT_STATES + ENROLLING_STATES,
                      to:     :canceled
        end

        # Coverage disabled due to non-payment
        event :suspend_enrollment do
          transitions from: :active, to: :suspended
        end

        # Coverage terminated due to non-payment
        event :terminate_enrollment do
          transitions from: [:active, :suspended], to: :terminated
        end

        # Coverage reinstated
        event :reinstate_enrollment do
          transitions from: [:suspended, :terminated], to: :active, after: :reset_termination_and_end_date
        end
      end

      def cancel_enrollments
        # TODO
      end

      def publish_state_transition
        return unless benefit_sponsorship.present?
        benefit_sponsorship.application_event_subscriber(aasm)
      end

      def benefit_sponsorship_event_subscriber(aasm)
        if (aasm.to_state == :initial_application_eligible) && may_approve_enrollment_eligiblity?
          approve_enrollment_eligiblity!
        end

        if aasm.to_state == :binder_reversed
          reverse_enrollment_eligiblity!
        end
      end

      def is_published?
        PUBLISHED_STATES.include?(aasm_state)
      end

      def benefit_groups # Deprecate in future
        warn "[Deprecated] Instead use benefit_packages" unless Rails.env.test?
        benefit_packages
      end

      def employees_are_matchable? # Deprecate in future
        warn "[Deprecated] Instead use is_published?" unless Rails.env.test?
        is_published?
      end

      private

      # AASM states used in PlanYear as mapped to new BenefitApplication model
      def plan_year_to_benefit_application_states_map
        {
          :draft                    => :draft,
          :renewing_draft           => :draft,

          :submitted                => :submitted,
          :published                => :approved,
          :renewing_published       => :approved,

          :published_invalid        => :pending,
          :publish_pending          => :pending,  # Plan application as submitted has warnings
          :renewing_publish_pending => :pending,

          :eligibility_review       => :pending,  # Plan application was submitted with warning and is under review by HBX officials

          :enrolling                => :enrollment_open,
          :renewing_enrolling       => :enrollment_open,
          :enrollment_open          => :enrollment_open,

          :enrollment_closed        => :enrollment_closed,

          :enrolled                 => :enrollment_eligible,
          :renewing_enrolled        => :enrollment_eligible,

          :application_ineligible           => :enrollment_ineligible,
          :renewing_application_ineligible  => :enrollment_ineligible,

          :active                   => :active,
          :suspended                => :suspended,
          :terminated               => :terminated,
          :expired                  => :expired,
          :conversion_expired       => :expired,    # Conversion employers who did not establish eligibility in a timely manner
          :canceled                 => :canceled,
          :renewing_canceled        => :canceled,
        }
      end


      def log_message(errors)
        msg = yield.first
        (errors[msg[0]] ||= []) << msg[1]
      end
    end
  end
end
