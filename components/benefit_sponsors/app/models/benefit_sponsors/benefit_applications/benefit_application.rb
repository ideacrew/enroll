module BenefitSponsors
  class BenefitApplications::BenefitApplication
    include Mongoid::Document
    include Mongoid::Timestamps
    include BenefitSponsors::Concerns::RecordTransition
    include AASM

    embedded_in :benefit_sponsorship,
      class_name: "::BenefitSponsors::BenefitSponsorships::BenefitSponsorship"

    APPLICATION_EXCEPTION_STATES  = [:pending, :assigned, :processing, :reviewing, :information_needed, :appealing].freeze
    APPLICATION_DRAFT_STATES      = [:draft] + APPLICATION_EXCEPTION_STATES.freeze
    APPLICATION_APPROVED_STATES   = [:approved].freeze
    ENROLLING_STATES              = [:enrollment_open, :enrollment_closed].freeze
    ENROLLMENT_ELIGIBLE_STATES    = [:enrollment_eligible].freeze
    ENROLLMENT_INELIGIBLE_STATES  = [:enrollment_ineligible].freeze
    COVERAGE_EFFECTIVE_STATES     = [:active].freeze
    TERMINATED_STATES             = [:denied, :suspended, :terminated, :canceled, :expired].freeze
    EXPIRED_STATES                = [:expired].freeze
    IMPORTED_STATES               = [:imported].freeze
    APPROVED_STATES               = [:approved, :enrollment_open, :enrollment_closed, :enrollment_eligible, :active, :suspended].freeze

    PUBLISHED_STATES = ENROLLMENT_ELIGIBLE_STATES + APPLICATION_APPROVED_STATES + ENROLLING_STATES + COVERAGE_EFFECTIVE_STATES

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
    # application
    field :recorded_sic_code,       type: String

    field :predecessor_application_id,  type: BSON::ObjectId
    field :successor_application_ids,   type: Array, default: []

    field :recorded_rating_area_id,     type: BSON::ObjectId
    field :recorded_service_area_ids,   type: Array, default: []

    field :benefit_sponsor_catalog_id,  type: BSON::ObjectId

    embeds_many :benefit_packages,
      class_name: "BenefitSponsors::BenefitPackages::BenefitPackage"

    validates_presence_of :effective_period, :open_enrollment_period, :recorded_service_areas, :recorded_rating_area

    index({ "aasm_state" => 1 })
    index({ "effective_period.min" => 1, "effective_period.max" => 1 }, { name: "effective_period" })
    index({ "open_enrollment_period.min" => 1, "open_enrollment_period.max" => 1 }, { name: "open_enrollment_period" })

    # Use chained scopes, for example: approved.effective_date_begin_on(start, end)
    scope :draft,               ->{ any_in(aasm_state: APPLICATION_DRAFT_STATES) }
    scope :approved,            ->{ any_in(aasm_state: APPLICATION_APPROVED_STATES) }

    scope :submitted,           ->{ any_in(aasm_state: APPROVED_STATES) }
    scope :exception,           ->{ any_in(aasm_state: APPLICATION_EXCEPTION_STATES) }
    scope :enrolling,                       ->{ any_in(aasm_state: ENROLLING_STATES) }
    scope :enrollment_eligible,             ->{ any_in(aasm_state: ENROLLMENT_ELIGIBLE_STATES) }
    scope :enrollment_ineligible,           ->{ any_in(aasm_state: ENROLLMENT_INELIGIBLE_STATES) }
    scope :coverage_effective,              ->{ any_in(aasm_state: COVERAGE_EFFECTIVE_STATES) }
    scope :terminated,                      ->{ any_in(aasm_state: TERMINATED_STATES) }
    scope :imported,                        ->{ any_in(aasm_state: IMPORTED_STATES) }
    scope :non_canceled,                    ->{ not_in(aasm_state: TERMINATED_STATES) }
    scope :non_draft,                       ->{ not_in(aasm_state: APPLICATION_DRAFT_STATES) }
    scope :non_imported,                    ->{ not_in(aasm_state: IMPORTED_STATES) }

    scope :expired,                         ->{ any_in(aasm_state: EXPIRED_STATES) }

    # scope :is_renewing,                     ->{ where(:predecessor_application => {:$exists => true},
    #                                                   :aasm_state.in => APPLICATION_DRAFT_STATES + ENROLLING_STATES).order_by(:'created_at'.desc)
    #                                             }

    scope :effective_date_begin_on,         ->(compare_date = TimeKeeper.date_of_record) { where(
                                                                                           :"effective_period.min" => compare_date )
                                                                                           }

    scope :effective_date_end_on,           ->(compare_date = TimeKeeper.date_of_record) { where(
                                                                                           :"effective_period.max" => compare_date )
                                                                                           }

    scope :effective_period_cover,          ->(compare_date = TimeKeeper.date_of_record) { where(
                                                                                             :"effective_period.min".lte => compare_date,
                                                                                           :"effective_period.max".gte => compare_date)
                                                                                           }
    scope :future_effective_date,           ->(compare_date = TimeKeeper.date_of_record) { where(
                                                                                           :"effective_period.min".gte => compare_date )
                                                                                           }
    scope :open_enrollment_period_cover,    ->(compare_date = TimeKeeper.date_of_record) { where(
                                                                                             :"opem_enrollment_period.min".lte => compare_date,
                                                                                           :"opem_enrollment_period.max".gte => compare_date)
                                                                                           }
    scope :open_enrollment_begin_on,        ->(compare_date = TimeKeeper.date_of_record) { where(
                                                                                           :"open_enrollment_period.min" => compare_date)
                                                                                           }
    scope :open_enrollment_end_on,          ->(compare_date = TimeKeeper.date_of_record) { where(
                                                                                           :"open_enrollment_period.max" => compare_date)
                                                                                           }
    scope :benefit_terminate_on,            ->(compare_date = TimeKeeper.date_of_record) { where(
                                                                                         :"terminated_on" => compare_date)
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

    scope :published_benefit_applications_by_date, ->(date) {
      where(
        "$and" => [
          {:aasm_state.in => APPROVED_STATES },
          {:"effective_period.min".lte => date, :"effective_period.max".gte => date}
        ]
      )
    }

    # scope :published_and_expired_plan_years_by_date, ->(date) {
    #   where(
    #     "$and" => [
    #       {:aasm_state.in => APPROVED_STATES + ['expired'] },
    #       {:"effective_period.min".lte => date, :"effective_period.max".gte => date}
    #     ]
    #     )
    # }


    # def benefit_sponsor_catalog_for(effective_date)
    #   benefit_market_catalog = benefit_sponsorship.benefit_market.benefit_market_catalog_effective_on(effective_date)
    #   if benefit_market_catalog.present?
    #     self.benefit_sponsor_catalog = benefit_market_catalog.benefit_sponsor_catalog_for(service_areas: benefit_sponsorship.service_areas, effective_date: effective_date)
    #   else
    #     nil
    #   end
    #   # benefit_market_catalog.benefit_sponsor_catalog_for(service_areas: benefit_sponsorship.service_areas, effective_date: effective_date)
    # end

    delegate :benefit_market, to: :benefit_sponsorship

    after_initialize :set_values
    after_create :renew_benefit_package_assignments

    def set_values
      if benefit_sponsorship
        recorded_sic_code      = benefit_sponsorship.sic_code unless recorded_sic_code.present?
        recorded_rating_area   = benefit_sponsorship.rating_area unless recorded_rating_area.present?
        recorded_service_areas = benefit_sponsorship.service_areas unless recorded_service_areas.present?
      end
    end

    def predecessor_application=(new_benefit_application)
      raise ArgumentError.new("expected BenefitApplication") unless new_benefit_application.is_a? BenefitSponsors::BenefitApplications::BenefitApplication
      self.predecessor_application_id = new_benefit_application._id
      @predecessor_application = new_benefit_application
    end

    def predecessor_application
      return nil if predecessor_application_id.blank?
      return @predecessor_application if @benefit_application
      @predecessor_application = benefit_sponsorship.benefit_applications_by(predecessor_application_id)
    end

    def successor_applications=(applications)
      raise ArgumentError.new("expected BenefitApplication") if applications.any?{|application| !application.is_a? BenefitSponsors::BenefitApplications::BenefitApplication}
      self.successor_application_ids = applications.map(&:_id)
      @successor_applications = applications
    end

    def successor_applications
      return nil if successor_application_ids.blank?
      return if defined? @successor_applications
      @successor_applications = benefit_sponsorship.benefit_applications_by(successor_application_ids)
    end

    def benefit_sponsor_catalog=(new_benefit_sponsor_catalog)
      raise ArgumentError.new("expected BenefitSponsorCatalog") unless new_benefit_sponsor_catalog.is_a? BenefitMarkets::BenefitSponsorCatalog
      self.benefit_sponsor_catalog_id = new_benefit_sponsor_catalog._id
      @benefit_sponsor_catalog = new_benefit_sponsor_catalog
    end

    def benefit_sponsor_catalog
      return nil if benefit_sponsor_catalog_id.blank?
      return @benefit_sponsor_catalog if defined? @benefit_sponsor_catalog
      @benefit_sponsor_catalog = BenefitMarkets::BenefitSponsorCatalog.find_by(benefit_sponsor_catalog_id)
    end

    def recorded_rating_area=(new_recorded_rating_area)
      raise ArgumentError.new("expected RatingArea") unless new_recorded_rating_area.is_a? BenefitMarkets::Locations::RatingArea
      self.recorded_rating_area_id = new_recorded_rating_area._id
      @recorded_rating_area = new_recorded_rating_area
    end

    def recorded_rating_area
      return nil if recorded_rating_area_id.blank?
      return @recorded_rating_area if defined? @recorded_rating_area
      @recorded_rating_area = BenefitMarkets::Locations::RatingArea.find(recorded_rating_area_id)
    end

    def recorded_service_areas=(new_recorded_service_areas)
      raise ArgumentError.new("expected ServiceArea") if new_recorded_service_areas.any?{|service_area| !service_area.is_a? BenefitMarkets::Locations::ServiceArea}
      self.recorded_service_area_ids = new_recorded_service_areas.map(&:_id)
      @recorded_service_areas = new_recorded_service_areas
    end

    def recorded_service_areas
      return @recorded_service_areas if defined? @recorded_service_areas
      @recorded_rating_area = BenefitMarkets::Locations::ServiceArea.find(recorded_service_area_ids)
    end

    def benefit_sponsor_catalog=(new_benefit_sponsor_catalog)
      raise ArgumentError.new("expected BenefitSponsorCatalog") unless new_benefit_sponsor_catalog.is_a? BenefitMarkets::BenefitSponsorCatalog
      self.benefit_sponsor_catalog_id = new_benefit_sponsor_catalog._id
      @benefit_sponsor_catalog = new_benefit_sponsor_catalog
    end

    def benefit_sponsor_catalog
      return nil if benefit_sponsor_catalog_id.blank?
      return @benefit_sponsor_catalog if defined? @benefit_sponsor_catalog
      @benefit_sponsor_catalog = BenefitMarkets::BenefitSponsorCatalog.find(benefit_sponsor_catalog_id)
    end

    def effective_period=(new_effective_period)
      effective_range = BenefitSponsors.tidy_date_range(new_effective_period, :effective_period)
      super(effective_range) unless effective_range.blank?
    end

    def open_enrollment_period=(new_open_enrollment_period)
      open_enrollment_range = BenefitSponsors.tidy_date_range(new_open_enrollment_period, :open_enrollment_period)
      super(open_enrollment_range) unless open_enrollment_range.blank?
    end

    def rate_schedule_date
      if benefit_sponsorship.source_kind == :mid_plan_year_conversion && predecessor_application.blank?
        end_on.prev_year + 1.day
      else
        start_on
      end
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

    # TODO: Refer to benefit_sponsorship instead of employer profile.
    def no_documents_uploaded?
      # benefit_sponsorship.employer_attestation.blank? || benefit_sponsorship.employer_attestation.unsubmitted?
      benefit_sponsorship.profile.employer_attestation.blank? || benefit_sponsorship.profile.employer_attestation.unsubmitted?
    end

    def effective_date
      start_on
    end

    def sponsor_profile
      benefit_sponsorship.profile
    end

    def default_benefit_group
      benefit_packages.detect(&:is_default)
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
        recorded_service_areas:   benefit_sponsorship.service_areas,
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

    def renew_benefit_package_assignments
      if is_renewing?
        benefit_packages.each do |benefit_package|
          benefit_package.renew_employee_assignments
        end

        default_benefit_package = benefit_packages.detect{|benefit_package| benefit_package.is_default }
        if benefit_sponsorship.census_employees.present?
          benefit_sponsorship.census_employees.non_terminated.benefit_application_unassigned(self).each do |census_employee|
            census_employee.assign_to_benefit_package(default_benefit_package, effective_period.min)
          end
        end
      end
    end

    def waived
      return @waived if defined? @waived
      @waived ||= find_census_employees.waived
    end

    def waived_count
      waived.count
    end

    def covered
      return @covered if defined? @covered
      @covered ||= find_census_employees.covered
    end

    def covered_count
      covered.count
    end

    def eligible_to_enroll_count
      eligible_to_enroll.size
    end

    def eligible_to_enroll
      return @eligible if defined? @eligible
      @eligible ||= active_census_employees
    end

    def find_census_employees
      return @census_employees if defined? @census_employees
      @census_employees ||= CensusEmployee.benefit_application_assigned(self)
    end

    def active_census_employees
      find_census_employees.active
    end

    def total_enrolled_count
      if active_census_employees.count <= Settings.aca.shop_market.small_market_active_employee_limit
        families_enrolled_under_application.size
      else
        0
      end
    end

    def employee_participation_ratio_minimum
      Settings.aca.shop_market.employee_participation_ratio_minimum.to_f
    end

    def minimum_enrolled_count
      (employee_participation_ratio_minimum * eligible_to_enroll_count).ceil
    end

    def additional_required_participants_count
      if total_enrolled_count < minimum_enrolled_count
        minimum_enrolled_count - total_enrolled_count
      else
        0.0
      end
    end

    def non_business_owner_enrolled
      total_enrolled   = families_enrolled_under_application
      
      owner_employees  = active_census_employees.select{|ce| ce.is_business_owner}
      filter_enrolled_employees(owner_employees, total_enrolled)
      
      waived_employees = active_census_employees.select{|ce| ce.waived?}
      filter_enrolled_employees(waived_employees, total_enrolled)

      total_enrolled
    end

    def filter_enrolled_employees(employees_to_filter, total_enrolled)
      families_to_filter = employees_to_filter.collect{|census_employee| census_employee.family }.compact
      total_enrolled    -= families_to_filter
    end

    def families_enrolled_under_application
      Family.enrolled_under_benefit_application(self)
    end

    def renew_benefit_package_members
      if is_renewing?
        benefit_packages.each do |benefit_package|
          benefit_package.renew_member_benefits
        end
      end
    end

    def effectuate_benefit_package_members
      benefit_packages.each do |benefit_package|
        Family.enrolled_through_benefit_package(benefit_package).each do |family|
          benefit_package.effectuate_family_coverages(family)
        end
      end
    end

    def expire_benefit_package_members
      benefit_packages.each do |benefit_package|
        benefit_package.deactivate
        Family.enrolled_through_benefit_package(benefit_package).each do |family|
          benefit_package.expire_family_coverages(family)
        end
      end
    end

    def terminate_benefit_package_members
      benefit_packages.each do |benefit_package|
        benefit_package.deactivate
        Family.enrolled_through_benefit_package(benefit_package).each do |family|
          benefit_package.terminate_family_coverages(family)
        end
      end
    end

    def cancel_benefit_package_members
      benefit_packages.each do |benefit_package|
        disable_benefit_package(benefit_package)
      end
    end

    def disable_benefit_package(benefit_package)
      benefit_package.deactivate
      Family.enrolled_through_benefit_package(benefit_package).each do |family|
        benefit_package.cancel_family_coverages(family)
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

    class << self

      def find(id)
        return nil if id.blank?
        sponsorship = BenefitSponsors::BenefitSponsorships::BenefitSponsorship.benefit_application_find(id).first
        
        if sponsorship.present?
          sponsorship.benefit_applications_by(id)
        end
      end
    end

    aasm do
      state :draft, initial: true
      state :imported             # Static state for seed application instances used to transfer Benefit Sponsors and members into the system

      state :approved             # Accepted - Application meets criteria necessary for sponsored members to shop for benefits.  Members may view benefits, but not enroll
      state :denied               # Rejected

      # TODO: Compare optional states with CCA values for Employer Attestation approval flow
      ## Begin optional states for exception processing
      state :pending              # queued for review or verification
      state :assigned             # assigned to case worker
      state :processing           # under consideration and determination
      state :reviewing            # determination under peer or supervisory review
      state :information_needed   # returned for supplementary information
      state :appealing            # request reversal of negative determination
      ## End optional states for exception processing

      state :enrollment_open, after_enter: :renew_benefit_package_members     # Approved application has entered open enrollment period
      state :enrollment_closed
      state :enrollment_eligible  # Enrollment meets criteria necessary for sponsored members to effectuate selected benefits
      state :enrollment_ineligible   # open enrollment did not meet eligibility criteria
      
      state :active,     :after_enter => :effectuate_benefit_package_members    # Application benefit coverage is in-force
      state :suspended   # Coverage is no longer in effect. members may not enroll or change enrollments
      state :terminated, :after_enter => :terminate_benefit_package_members # Coverage under this application is terminated
      state :expired,    :after_enter => :expire_benefit_package_members    # Non-published plans are expired following their end on date
      state :canceled,   :after_enter => :cancel_benefit_package_members    # Application closed prior to coverage taking effect

      after_all_transitions :publish_state_transition

      event :import do
        transitions from: :draft, to: :imported
      end

      event :review_application do
        transitions from: :draft, to: :pending
      end

      # Returns plan to draft state (or) renewing draft for edit
      event :withdraw_pending do
        transitions from: :pending, to: :draft
      end

      # Employer requests review of invalid application determination
      event :request_eligibility_review do
        transitions from: :submitted, to: :pending #,  guard:  :is_within_review_period?
      end

      # Upon review, application ineligible status overturned and deemed eligible
      event :approve_application do
        transitions from: :draft, to: :approved
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

      event :revert_application do
        transitions from:   [
          :approved, :denied,
          :enrollment_open, :enrollment_closed,
          :enrollment_eligible, :enrollment_ineligible,
          :active
        ] + APPLICATION_EXCEPTION_STATES, 
          to:     :draft, 
          after:  :cancel_benefit_package_members
      end

      event :activate_enrollment do
        transitions from:   :enrollment_eligible,
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
        transitions from: [:suspended, :terminated], to: :active #, after: :reset_termination_and_end_date
      end
    end


    def publish_state_transition
      return unless benefit_sponsorship.present?
      benefit_sponsorship.application_event_subscriber(aasm)
    end

    def benefit_sponsorship_event_subscriber(aasm)
      if (aasm.to_state == :initial_enrollment_eligible) && may_approve_enrollment_eligiblity?
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

    def employer_profile
      benefit_sponsorship.profile
    end

    def eligible_for_export?
      return false if self.aasm_state.blank?
      return false if self.imported?
      return false if self.effective_period.blank?
      return true if self.enrollment_eligible? || self.active?
      self.terminated? || self.expired?
    end

    def matching_state_for(plan_year)
      plan_year_to_benefit_application_states_map[plan_year.aasm_state.to_sym]
    end

    private

    def log_message(errors)
      msg = yield.first
      (errors[msg[0]] ||= []) << msg[1]
    end

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


  end
end
