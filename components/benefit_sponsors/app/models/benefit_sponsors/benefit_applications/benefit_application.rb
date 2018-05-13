module BenefitSponsors
  module BenefitApplications
    class BenefitApplication
      include Mongoid::Document
      include Mongoid::Timestamps
      include AASM
      include BenefitApplicationStateMachineHelper
      include BenefitSponsors::Concerns::RecordTransition

      EXCEPTION_WORKFLOW_STATES = [:pending, :assigned, :processing, :reviewing, :information_needed, :appealing].freeze
      APPROVED_STATES           = [:approved, :enrollment_open, :enrollment_closed, :enrollment_eligible, :active, :suspended].freeze
      # APPROVED = %w(published enrolling enrolled active suspended)

      EXPIRED_STATES            = [:expired].freeze

      # TODO: is this needed?  manage state from BenefitSponsorship?
      # ENROLLING_STATES = [] + EXCEPTION_WORKFLOW_STATES.freeze
      # INITIAL_ENROLLING_STATE = %w(publish_pending eligibility_review published published_invalid enrolling enrolled)

      ELIGIBLE_STATES  = [:approved, :enrollment_open, :enrollment_closed, :enrollment_eligible].freeze
      # INITIAL_ELIGIBLE_STATE  = %w(published enrolling enrolled)


      # OPEN_ENROLLMENT_STATE   = %w(enrolling renewing_enrolling)
      # RENEWING  = %w(renewing_draft renewing_published renewing_enrolling renewing_enrolled renewing_publish_pending)
      # RENEWING_APPROVED_STATE = %w(renewing_published renewing_enrolling renewing_enrolled)

      INELIGIBLE_FOR_EXPORT_STATES = %w(draft publish_pending eligibility_review published_invalid canceled renewing_draft suspended terminated application_ineligible renewing_application_ineligible renewing_canceled conversion_expired renewing_enrolling enrolling)


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
                  counter_cache: true,
                  class_name: "::BenefitMarkets::Locations::RatingArea"

      belongs_to  :recorded_service_area,
                  counter_cache: true,
                  class_name: "::BenefitMarkets::Locations::ServiceArea"

      belongs_to  :benefit_sponsorship,
                  counter_cache: true,
                  class_name: "::BenefitSponsors::BenefitSponsorships::BenefitSponsorship"

      embeds_one  :benefit_sponsor_catalog,
                  class_name: "::BenefitMarkets::BenefitSponsorCatalog"

      embeds_many :benefit_packages,
                  class_name: "BenefitSponsors::BenefitPackages::BenefitPackage"

      validates_presence_of :effective_period, :open_enrollment_period

      # validate :validate_application_dates
      # validate :open_enrollment_date_checks

      index({ "effective_period.min" => 1, "effective_period.max" => 1 }, { name: "effective_period" })
      index({ "open_enrollment_period.min" => 1, "open_enrollment_period.max" => 1 }, { name: "open_enrollment_period" })

      # Use chained scopes, for example: approved.effective_date_begin_on(start, end)
      scope :approved,                        ->{ any_in(aasm_state: APPROVED_STATES) }
      scope :eligible,                        ->{ any_in(aasm_state: ELIGIBLE_STATES) }
      scope :expired,                         ->{ any_in(aasm_state: EXPIRED_STATES) }

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
      scope :open_enrollment_end_on,          ->(compare_date = TimeKeeper.date_of_record) { where(
                                                              :"open_enrollment_period.max" => compare_date)
                                                            }

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

      scope :published_plan_years_by_date, ->(date) {
        where(
          "$and" => [
            {:aasm_state.in => APPROVED_STATES },
            {:"effective_period.min".lte => date, :"effective_period.max".gte => date}
          ]
          )
      }

      scope :published_and_expired_plan_years_by_date, ->(date) {
        where(
          "$and" => [
            {:aasm_state.in => APPROVED_STATES + ['expired'] },
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
          new_benefit_package = renewal_application.benefit_packages.new
          benefit_package.renew(new_benefit_package)
        end

        renewal_application
      end


      # TODO Refactor - Move this to Domain logic
      # after_update :update_employee_benefit_packages
      # TODO: Refactor code into benefit package updater
      # def update_employee_benefit_packages
      #   if self.start_on_changed?
      #     bg_ids = self.benefit_groups.pluck(:_id)
      #     employees = CensusEmployee.where({ :"benefit_group_assignments.benefit_group_id".in => bg_ids })
      #     employees.each do |census_employee|
      #       census_employee.benefit_group_assignments.where(:benefit_group_id.in => bg_ids).each do |assignment|
      #         assignment.update(start_on: self.start_on)
      #         assignment.update(end_on: self.end_on) if assignment.end_on.present?
      #       end
      #     end
      #   end
      # end


      # TODO Refactor - Move this to Domain logic
      # def assigned_census_employees
      #   benefit_packages.flat_map(){ |benefit_package| benefit_package.census_employees.active }
      # end

      # TODO: Refactor
      # def is_renewing?
      #   RENEWING.include?(aasm_state)
      # end

      # TODO Refactor - Move this to Domain logic
      ## Stub for BQT
      # def estimate_group_size?
      #   true
      # end

      # TODO Refactor - Move this to Domain logic
      # def eligible_for_export?
      #   return false if self.aasm_state.blank?
      #   return false if self.is_conversion
      #   !INELIGIBLE_FOR_EXPORT_STATES.include?(self.aasm_state.to_s)
      # end


      # def employee_participation_percent
      #   return "-" if eligible_to_enroll_count == 0
      #   "#{(total_enrolled_count / eligible_to_enroll_count.to_f * 100).round(2)}%"
      # end

      # def employee_participation_percent_based_on_summary
      #   return "-" if eligible_to_enroll_count == 0
      #   "#{(enrolled_summary / eligible_to_enroll_count.to_f * 100).round(2)}%"
      # end

      # # TODO: Fix this method
      # def minimum_employer_contribution
      #   unless benefit_packages.size == 0
      #     benefit_packages.map do |benefit_package|
      #       if benefit_package#.sole_source?
      #         OpenStruct.new(:premium_pct => 100)
      #       else
      #         benefit_package.relationship_benefits.select do |relationship_benefit|
      #           relationship_benefit.relationship == "employee"
      #         end.min_by do |relationship_benefit|
      #           relationship_benefit.premium_pct
      #         end
      #       end
      #     end.map(&:premium_pct).first
      #   end
      # end

      # # TODO: Refactor -- where is this used?
      # # def to_plan_year
      # #   BenefitApplicationToPlanYearConverter.new(self).call
      # # end

      # # TODO: Refactor -- where is this used?
      # # def filter_active_enrollments_by_date(date)
      # #   enrollment_proxies = BenefitApplicationEnrollmentsQuery.new(self).call(Family, date)
      # #   return [] if (enrollment_proxies.count > 100)
      # #   enrollment_proxies.map do |ep|
      # #     OpenStruct.new(ep)
      # #   end
      # # end

      # def hbx_enrollments_by_month(date)
      #   BenefitApplicationEnrollmentsMonthlyQuery.new(self).call(date)
      # end

      def effective_period=(new_effective_period)
        effective_range = BenefitSponsors.tidy_date_range(new_effective_period, :effective_period)
        super(effective_range) unless effective_range.blank?
      end

      def open_enrollment_period=(new_open_enrollment_period)
        open_enrollment_range = BenefitSponsors.tidy_date_range(new_open_enrollment_period, :open_enrollment_period)
        super(open_enrollment_range) unless open_enrollment_range.blank?
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

      def effective_date
        start_on
      end

      def sponsor_profile
        benefit_sponsorship.benefit_sponsorable
      end

      # TODO Refactor -- use the new state: :open_enrollment_closed
      # def open_enrollment_completed?
      #   ::TimeKeeper.date_of_record > open_enrollment_period.end unless open_enrollment_period.blank?
      # end

      def default_benefit_group
        benefit_groups.detect(&:default)
      end


      # Do we differentiate applications for conversion groups that are used only for seeding renewals?

      aasm do
        state :draft, initial: true
        # state :renewing_draft, :after_enter => :renewal_group_notice # renewal_group_notice - Sends a notice three months prior to plan year renewing

        state :submitted            # Presented for approval
        state :denied               # Rejected
        state :approved             # Accepted - Application meets criteria necessary for sponsored members to shop for benefits.  Members may view benefits, but not enroll

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

        state :enrollment_open,       :after_enter => :send_employee_invites          # Approved application has entered open enrollment period
        # state :renewing_enrolling, :after_enter => [:trigger_passive_renewals, :send_employee_invites]

        state :enrollment_closed

        state :enrollment_eligible,   :after_enter => [:ratify_enrollment, :initial_employer_open_enrollment_completed] # Enrollment meets criteria necessary for sponsored members to effectuate selected benefits
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


        # Time-based transitions: Change enrollment state, in-force plan year and clean house on any plan year applications from prior year
        event :advance_date do
          transitions from: :enrollment_eligible,                       to: :active,                 guard:   :is_event_date_valid?
          transitions from: :approved,                                  to: :enrollment_open,        guard:   :is_event_date_valid?
          transitions from: [:enrollment_open, :enrollment_closed],     to: :enrollment_eligible,    guards:  [:is_open_enrollment_closed?, :is_enrollment_valid?]
          transitions from: [:enrollment_open, :enrollment_closed],     to: :enrollment_ineligible,  guard:   :is_open_enrollment_closed?, :after => [:initial_employer_ineligibility_notice, :notify_employee_of_initial_employer_ineligibility]
          transitions from: :enrollment_open,                           to: :enrollment_closed,      guard:   :is_event_date_valid?

          transitions from: :active,                                    to: :terminated,             guard:   :is_event_date_valid?
          transitions from: [:draft, :pending, :enrollment_ineligible], to: :expired,                guard:   :is_plan_year_end?

          ## TODO update this renewal transition
          # transitions from: :enrollment_open,                           to: :enrollment_ineligible,  guard:  :is_open_enrollment_closed?, :after => [:renewal_employer_ineligibility_notice, :zero_employees_on_roster]

          transitions from: :enrollment_open,                           to: :enrollment_open  # avoids error when application is in enrollment_open state
        end

        ## Application eligibility determination process

        # Submit plan year application
        event :submit do
          transitions from: :draft, to: :draft,           guard:  :is_application_unpublishable?
          transitions from: :draft, to: :enrollment_open, guard:  [:is_application_eligible?, :is_event_date_valid?]#, :after => [:accept_application, :initial_employer_approval_notice, :zero_employees_on_roster]
          transitions from: :draft, to: :approved,        guard:  :is_application_eligible?#, :after => [:initial_employer_approval_notice, :zero_employees_on_roster]

          ## TODO update these renewal transitions
          # transitions from: :draft, to: :enrollment_open, guard:  [:is_application_eligible?, :is_event_date_valid?], :after => [:accept_application, :trigger_renewal_notice, :zero_employees_on_roster]
          # transitions from: :draft, to: :approved,        guard:  :is_application_eligible? , :after => [:trigger_renewal_notice, :zero_employees_on_roster]

          transitions from: :draft, to: :pending
        end

        # Returns plan to draft state (or) renewing draft for edit
        event :withdraw_pending do
          transitions from: :pending, to: :draft
          transitions from: :pending, to: :draft
        end

        # Plan as submitted failed eligibility check
        event :auto_approve do
          transitions from: :pending, to: :pending

          transitions from: :draft, to: :draft,           guard:  :is_application_invalid?
          transitions from: :draft, to: :enrollment_open, guard:  [:is_application_eligible?, :is_event_date_valid?]#, :after => [:accept_application, :zero_employees_on_roster]
          transitions from: :draft, to: :approved,        guard:  :is_application_eligible?#, :after => :zero_employees_on_roster
          transitions from: :draft, to: :pending

          ## TODO update these renewal transitions
          # transitions from: :draft, to: :enrollment_open, guard:  [:is_application_eligible?, :is_event_date_valid?], :after => [:accept_application, :trigger_renewal_notice, :zero_employees_on_roster]
          # transitions from: :draft, to: :approved,        guard:  :is_application_eligible?, :after => [:trigger_renewal_notice, :zero_employees_on_roster]
          # transitions from: :draft, to: :pending,         :after => [:employer_renewal_eligibility_denial_notice, :notify_employee_of_renewing_employer_ineligibility]
        end

        # Employer requests review of invalid application determination
        event :request_eligibility_review do
          transitions from: :pending, to: :pending,  guard:  :is_within_review_period?
        end

        # Upon review, application ineligible status overturned and deemed eligible
        event :approve do
          transitions from: EXCEPTION_WORKFLOW_STATES, to: :approved
        end

        # Upon review, submitted application ineligible status verified ineligible
        event :deny do
          transitions from: EXCEPTION_WORKFLOW_STATES, to: :denied
        end

        # Enrollment processed stopped due to missing binder payment
        event :cancel do
          transitions from:   [:draft, :approved, :enrollment_open, :enrollment_eligible, :active],
                      to:     :canceled
        end

        event :approve_enrollment do
          transitions from:   [:approved, :enrollment_open, :enrollment_closed],
                      to:     :enrollment_eligible
        end

        # Admin ability to reset plan year application
        event :revert_submitted_application, :after => :revert_employer_profile_application do
          transitions from:   [:submitted] + EXCEPTION_WORKFLOW_STATES,
                      to:     :draft
        end

        event :revert_active_application, :after => :revert_employer_profile_application do
          transitions from:   [
                                  :enrollment_open, :enrollment_closed,
                                  :enrollment_eligible, :enrollment_ineligible,
                                  :active,
                                ],
                      to:     :draft,
                      after:  [:cancel_enrollments]
        end

        # TODO review this functionality
        # event :conversion_expire do
        #   transitions from: [:expired, :active], to: :conversion_expired,  guard:  :can_be_migrated?
        # end

        event :activate do
          transitions from:   [:approved, :enrollment_open, :enrollment_closed, :enrollment_eligible],
                      to:     :active,
                      guard:  :can_be_activated?
        end

        event :expire do
          transitions from:   [:approved, :enrollment_open, :enrollment_eligible, :active],
                      to:     :expired,
                      guard:  :can_be_expired?
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
        event :reinstate do
          transitions from: [:suspended, :terminated], to: :active, after: :reset_termination_and_end_date
        end
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
