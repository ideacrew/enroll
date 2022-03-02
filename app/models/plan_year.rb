class PlanYear
  include Mongoid::Document
  include SetCurrentUser
  include Mongoid::Timestamps
  include AASM
  include Acapi::Notifiers
  include ScheduledEventService
  include Config::AcaModelConcern
  include Concerns::Observable
  include ModelEvents::PlanYear
  include Config::BankHolidaysHelper

  embedded_in :employer_profile

  PUBLISHED = %w(published enrolling enrolled active suspended)
  RENEWING  = %w(renewing_draft renewing_published renewing_enrolling renewing_enrolled renewing_publish_pending)
  RENEWING_PUBLISHED_STATE = %w(renewing_published renewing_enrolling renewing_enrolled)
  DRAFT_STATES = %w(draft renewing_draft)

  INELIGIBLE_FOR_EXPORT_STATES = %w(draft publish_pending eligibility_review published_invalid canceled renewing_draft suspended application_ineligible renewing_application_ineligible renewing_canceled conversion_expired)

  OPEN_ENROLLMENT_STATE   = %w(enrolling renewing_enrolling)
  INITIAL_ENROLLING_STATE = %w(publish_pending eligibility_review published published_invalid enrolling enrolled)
  INITIAL_ELIGIBLE_STATE  = %w(published enrolling enrolled)

  # Plan Year time period
  field :start_on, type: Date
  field :end_on, type: Date

  field :open_enrollment_start_on, type: Date
  field :open_enrollment_end_on, type: Date

  field :terminated_on, type: Date
  field :termination_kind, type: String

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

  # Workflow attributes
  field :aasm_state, type: String, default: :draft

  # SIC code, frozen when the plan year is published,
  # otherwise comes from employer_profile
  field :recorded_sic_code, type: String
  field :recorded_rating_area, type: String

  validates_inclusion_of :recorded_rating_area, :in => market_rating_areas, :allow_nil => true

  embeds_many :benefit_groups, cascade_callbacks: true
  embeds_many :workflow_state_transitions, as: :transitional

  accepts_nested_attributes_for :benefit_groups, :workflow_state_transitions

  validates_presence_of :start_on, :end_on, :open_enrollment_start_on, :open_enrollment_end_on, :message => "is invalid"

  validate :open_enrollment_date_checks

  # scope :not_yet_active, ->{ any_in(aasm_state: %w(published enrolling enrolled)) }

  scope :published,         ->{ any_in(aasm_state: PUBLISHED) }
  scope :renewing_published_state, ->{ any_in(aasm_state: RENEWING_PUBLISHED_STATE) }
  scope :renewing,          ->{ any_in(aasm_state: RENEWING) }
  scope :draft,             ->{ any_in(aasm_state: DRAFT_STATES) }

  scope :published_or_renewing_published, -> { any_of([published.selector, renewing_published_state.selector]) }

  scope :by_date_range,     ->(begin_on, end_on) { where(:"start_on".gte => begin_on, :"start_on".lte => end_on) }
  scope :published_plan_years_within_date_range, ->(begin_on, end_on) {
    where(
      "$and" => [
        {:aasm_state.in => PUBLISHED },
        {"$or" => [
          { :start_on => {"$gte" => begin_on, "$lte" => end_on }},
          { :end_on => {"$gte" => begin_on, "$lte" => end_on }}
        ]
      }
    ]
    )
  }

  scope :published_plan_years_by_date, ->(date) {
    where(
      "$and" => [
        {:aasm_state.in => PUBLISHED },
        {:"start_on".lte => date, :"end_on".gte => date}
      ]
    )
  }

  scope :published_and_expired_plan_years_by_date, ->(date) {
    where(
      "$and" => [
        {:aasm_state.in => PUBLISHED + ['expired'] },
        {:"start_on".lte => date, :"end_on".gte => date}
      ]
    )
  }

  scope :non_canceled, -> { not_in(aasm_state: ['canceled, renewing_canceled']) }

  after_update :update_employee_benefit_packages

  after_save :notify_on_save

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

  def ensure_benefit_group_is_valid
    self.benefit_groups.each do |bg|
      if bg.sole_source?
        if bg.composite_tier_contributions.empty?
          bg.build_composite_tier_contributions
        end
        bg.estimate_composite_rates
      end
    end
    self.save!
  end

  def filter_active_enrollments_by_date(date)
    id_list = benefit_groups.collect(&:_id).uniq
    enrollment_proxies = Family.collection.aggregate([
      # Thin before expanding to make better use of indexes
      {"$match" => { "households.hbx_enrollments" => {
        "$elemMatch" => {
        "benefit_group_id" => {
          "$in" => id_list
        },
        "aasm_state" => { "$in" => (HbxEnrollment::ENROLLED_STATUSES + HbxEnrollment::RENEWAL_STATUSES + HbxEnrollment::TERMINATED_STATUSES + HbxEnrollment::WAIVED_STATUSES)},
        "effective_on" =>  {"$lte" => date.end_of_month, "$gte" => self.start_on}
      }}}},
      {"$unwind" => "$households"},
      {"$unwind" => "$households.hbx_enrollments"},
      {"$match" => {
        "households.hbx_enrollments.benefit_group_id" => {
          "$in" => id_list
        },
        "households.hbx_enrollments.aasm_state" => { "$in" => (HbxEnrollment::ENROLLED_STATUSES + HbxEnrollment::RENEWAL_STATUSES + HbxEnrollment::TERMINATED_STATUSES + HbxEnrollment::WAIVED_STATUSES)},
        "households.hbx_enrollments.effective_on" =>  {"$lte" => date.end_of_month, "$gte" => self.start_on},
        "$or" => [
         {"households.hbx_enrollments.terminated_on" => {"$eq" => nil} },
         {"households.hbx_enrollments.terminated_on" => {"$gte" => date.end_of_month}}
        ]
      }},
      {"$sort" => {
        "households.hbx_enrollments.submitted_at" => 1
      }},
      {"$group" => {
        "_id" => {
          "bga_id" => "$households.hbx_enrollments.benefit_group_assignment_id",
          "coverage_kind" => "$households.hbx_enrollments.coverage_kind"
        },
        "hbx_enrollment_id" => {"$last" => "$households.hbx_enrollments._id"},
        "aasm_state" => {"$last" => "$households.hbx_enrollments.aasm_state"},
        "plan_id" => {"$last" => "$households.hbx_enrollments.plan_id"},
        "benefit_group_id" => {"$last" => "$households.hbx_enrollments.benefit_group_id"},
        "benefit_group_assignment_id" => {"$last" => "$households.hbx_enrollments.benefit_group_assignment_id"},
        "family_members" => {"$last" => "$family_members"}
      }},
      {"$match" => {"aasm_state" => {"$nin" => HbxEnrollment::WAIVED_STATUSES}}}
    ])
    return [] if (enrollment_proxies.count > Settings.aca.shop_market.small_market_active_employee_limit)
    enrollment_proxies.map do |ep|
      OpenStruct.new(ep)
    end
  end

  def hbx_enrollments_by_month(date)
    id_list = benefit_groups.collect(&:_id).uniq
    families = Family.where({
      :"households.hbx_enrollments.benefit_group_id".in => id_list,
      :"households.hbx_enrollments.aasm_state".in => (HbxEnrollment::ENROLLED_STATUSES + HbxEnrollment::RENEWAL_STATUSES + HbxEnrollment::TERMINATED_STATUSES)
      }).limit(Settings.aca.shop_market.small_market_active_employee_limit)

    families.inject([]) do |enrollments, family|
      valid_enrollments = family.active_household.hbx_enrollments.where({
        :benefit_group_id.in => id_list,
        :effective_on.lte => date.end_of_month,
        :aasm_state.in => (HbxEnrollment::ENROLLED_STATUSES + HbxEnrollment::RENEWAL_STATUSES + HbxEnrollment::TERMINATED_STATUSES)
      }).order_by(:'submitted_at'.desc)

      health_enrollments = valid_enrollments.where({:coverage_kind => 'health'})
      dental_enrollments = valid_enrollments.where({:coverage_kind => 'dental'})

      coverage_filter = lambda do |enrollments, date|
        enrollments = enrollments.select{|e| e.terminated_on.blank? || e.terminated_on >= date}

        if enrollments.size > 1
          enrollment = enrollments.detect{|e| (HbxEnrollment::ENROLLED_STATUSES + HbxEnrollment::TERMINATED_STATUSES).include?(e.aasm_state.to_s)}
          enrollment || enrollments.detect{|e| HbxEnrollment::RENEWAL_STATUSES.include?(e.aasm_state.to_s)}
        else
          enrollments.first
        end
      end

      enrollments << coverage_filter.call(health_enrollments, date)
      enrollments << coverage_filter.call(dental_enrollments, date)
    end.compact
  end

  def open_enrollment_completed?
    return false if open_enrollment_end_on.blank?
    (TimeKeeper.date_of_record > open_enrollment_end_on)
  end

  def binder_paid?
    employer_profile.binder_paid?
  end

  def past_transmission_threshold?
    return false if start_on.blank?
    return true if transmit_employers_immediately?
    t_threshold_date = (start_on - 1.month).beginning_of_month + 14.days
    (TimeKeeper.date_of_record > t_threshold_date)
  end

  def eligible_for_export?
    return false if self.aasm_state.blank?
    return false if self.is_conversion
    if start_on.blank?
      return(false)
    end
    if INELIGIBLE_FOR_EXPORT_STATES.include?(self.aasm_state.to_s)
      return false
    end
    if (TimeKeeper.date_of_record < start_on)
      if enrolled?
        if open_enrollment_completed? && binder_paid? && past_transmission_threshold?
          return true
        end
      elsif renewing_enrolled?
        if open_enrollment_completed? && past_transmission_threshold?
          return true
        end
      end
      return false
    end
    true
  end

  def overlapping_published_plan_years
    self.employer_profile.plan_years.published_plan_years_within_date_range(self.start_on, self.end_on)
  end

  def parent
    raise "undefined parent employer_profile" unless employer_profile?
    self.employer_profile
  end

  def start_on=(new_date)
    new_date = Date.parse(new_date) if new_date.is_a? String
    write_attribute(:start_on, new_date.beginning_of_day)
  end

  def end_on=(new_date)
    new_date = Date.parse(new_date) if new_date.is_a? String
    write_attribute(:end_on, new_date.end_of_day)
  end

  def open_enrollment_start_on=(new_date)
    new_date = Date.parse(new_date) if new_date.is_a? String
    write_attribute(:open_enrollment_start_on, new_date.beginning_of_day)
  end

  def has_renewal_history?
    workflow_state_transitions.where(:to_state.in => PlanYear::RENEWING).any?
  end

  def enrollment_quiet_period
    PlanYear.enrollment_quiet_period(start_on: start_on, open_enrollment_end_on: open_enrollment_end_on, is_renewing: has_renewal_history?)
  end

  def self.enrollment_quiet_period(start_on:, open_enrollment_end_on: nil, is_renewing: false)
    if open_enrollment_end_on.blank?
      prev_month = start_on.prev_month
      quiet_period_start = Date.new(prev_month.year, prev_month.month, Settings.aca.shop_market.open_enrollment.monthly_end_on + 1)
    else
      quiet_period_start = open_enrollment_end_on + 1.day
    end

    quiet_period_end = is_renewing ? renewal_quiet_period_end(start_on) : initial_quiet_period_end(start_on)
    TimeKeeper.start_of_exchange_day_from_utc(quiet_period_start)..TimeKeeper.end_of_exchange_day_from_utc(quiet_period_end)
  end

  def self.initial_quiet_period_end(start_on)
    start_on + (Settings.aca.shop_market.initial_application.quiet_period.month_offset.months) + (Settings.aca.shop_market.initial_application.quiet_period.mday - 1).days
  end

  def self.renewal_quiet_period_end(start_on)
    start_on + (Settings.aca.shop_market.renewal_application.quiet_period.month_offset.months) + (Settings.aca.shop_market.renewal_application.quiet_period.mday - 1).days
  end

  def open_enrollment_end_on=(new_date)
    new_date = Date.parse(new_date) if new_date.is_a? String
    write_attribute(:open_enrollment_end_on, new_date.end_of_day)
  end

  alias_method :effective_date=, :start_on=
  alias_method :effective_date, :start_on

  def terminate_application(termination_date)
    if coverage_period_contains?(termination_date)
      self.terminated_on = termination_date
      terminate
    end
  end

  def hbx_enrollments
    @hbx_enrollments = [] if benefit_groups.size == 0
    return @hbx_enrollments if defined? @hbx_enrollments
    @hbx_enrollments = HbxEnrollment.find_by_benefit_groups(benefit_groups)
  end

  def employee_participation_percent
    return "-" if eligible_to_enroll_count == 0
    "#{(total_enrolled_count / eligible_to_enroll_count.to_f * 100).round(2)}%"
  end

  def employee_participation_percent_based_on_summary
    return "-" if eligible_to_enroll_count == 0
    "#{(enrolled_summary / eligible_to_enroll_count.to_f * 100).round(2)}%"
  end

  def external_plan_year?
    employer_profile.is_conversion? && coverage_period_contains?(employer_profile.registered_on)
  end

  def editable?
    !benefit_groups.any?(&:assigned?)
  end

  def open_enrollment_contains?(compare_date)
    (open_enrollment_start_on.beginning_of_day <= compare_date.beginning_of_day) &&
    (compare_date.end_of_day <= open_enrollment_end_on.end_of_day)
  end

  def coverage_period_contains?(compare_date)
    return (start_on <= compare_date) if (end_on.blank?)
    (start_on.beginning_of_day <= compare_date.beginning_of_day) &&
    (compare_date.end_of_day <= end_on.end_of_day)
  end

  def is_renewing?
    RENEWING.include?(aasm_state)
  end

  def is_published?
    PUBLISHED.include?(aasm_state)
  end

  def default_benefit_group
    benefit_groups.detect(&:default)
  end

  def is_offering_dental?
    benefit_groups.any?{|bg| bg.is_offering_dental?}
  end

  def carriers_offered
    benefit_groups.inject([]) do |carriers, bg|
      carriers += bg.carriers_offered
    end.uniq
  end

  def dental_carriers_offered
    return [] unless is_offering_dental?
    benefit_groups.inject([]) do |carriers, bg|
      carriers += bg.dental_carriers_offered
    end.uniq
  end

  def default_renewal_benefit_group
    # benefit_groups.detect { |bg| bg.is_default? && is_coverage_renewing? }
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

  def assigned_census_employees
    benefit_groups.flat_map(){ |benefit_group| benefit_group.census_employees.active }
  end

  def assigned_census_employees_without_owner
    benefit_groups.flat_map(){ |benefit_group| benefit_group.census_employees.active.non_business_owner }
  end

  def is_application_unpublishable?
    open_enrollment_date_errors.present? || application_errors.present?
  end

  def is_application_valid?
    application_errors.blank?
  end

  def is_application_invalid?
    application_errors.present?
  end

  def is_application_eligible?
    application_eligibility_warnings.blank?
  end

  def due_date_for_publish
    if employer_profile.plan_years.renewing.any?
      Date.new(start_on.prev_month.year, start_on.prev_month.month, PlanYear.shop_market_renewal_application_publish_due_day_of_month)
    else
      Date.new(start_on.prev_month.year, start_on.prev_month.month, PlanYear.shop_market_initial_application_publish_due_day_of_month)
    end
  end

  def is_publish_date_valid?
    event_name = aasm.current_event.to_s.gsub(/!/, '')
    event_name == "force_publish" ? true : (TimeKeeper.datetime_of_record <= due_date_for_publish.end_of_day)
  end

  def open_enrollment_date_errors
    errors = {}

    if is_renewing?
      minimum_length = Settings.aca.shop_market.renewal_application.open_enrollment.minimum_length.days
      enrollment_end = PlanYear.shop_market_renewal_application_monthly_open_enrollment_end_on
    else
      minimum_length = Settings.aca.shop_market.open_enrollment.minimum_length.days
      enrollment_end = PlanYear.shop_market_open_enrollment_monthly_end_on
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

    if benefit_groups.any?{|bg| bg.reference_plan_id.blank? }
      log_message(errors){{benefit_groups: "Reference plans have not been selected for benefit groups. Please edit the plan year and select reference plans."}}
    end

    if benefit_groups.blank?
      log_message(errors) {{benefit_groups: "You must create at least one benefit group to publish a plan year"}}
    end

    if employer_profile.census_employees.active.to_set != assigned_census_employees.to_set
      log_message(errors) {{benefit_groups: "Every employee must be assigned to a benefit group defined for the published plan year"}}
    end

    if employer_profile.ineligible?
      log_message(errors) {{employer_profile:  "This employer is ineligible to enroll for coverage at this time"}}
    end

    if overlapping_published_plan_year?
      log_message(errors) {{ publish: "You may only have one published plan year at a time" }}
    end

    if !is_publish_date_valid?
      log_message(errors) {{publish: "Plan year starting on #{start_on.strftime("%m-%d-%Y")} must be published by #{due_date_for_publish.strftime("%m-%d-%Y")}"}}
    end

    errors
  end

  def no_documents_uploaded?
    employer_profile.employer_attestation.blank? || employer_profile.employer_attestation.unsubmitted?
  end

  # Check plan year application for regulatory compliance
  def application_eligibility_warnings
    warnings = {}

    if employer_attestation_is_enabled?
      unless employer_profile.is_attestation_eligible?
        if employer_profile.employer_attestation.blank? || employer_profile.employer_attestation.unsubmitted?
          warnings.merge!({attestation_ineligible: "Employer attestation documentation not provided. Select <a href=/employers/employer_profiles/#{employer_profile.id}?tab=documents>Documents</a> on the blue menu to the left and follow the instructions to upload your documents."})
        elsif employer_profile.employer_attestation.denied?
          warnings.merge!({attestation_ineligible: "Employer attestation documentation was denied. This employer not eligible to enroll on the #{EnrollRegistry[:enroll_app].setting(:long_name).item}"})
        else
          warnings.merge!({attestation_ineligible: "Employer attestation error occurred: #{employer_profile.employer_attestation.aasm_state.humanize}. Please contact customer service."})
        end
      end
    end

    unless employer_profile.is_primary_office_local?
      warnings.merge!({primary_office_location: "Is a small business located in #{Settings.aca.state_name}"})
    end

    # Application is in ineligible state from prior enrollment activity
    if aasm_state == "application_ineligible" || aasm_state == "renewing_application_ineligible"
      warnings.merge!({ineligible: "Application did not meet eligibility requirements for enrollment"})
    end

    # Maximum company size at time of initial registration on the HBX
    if fte_count < 1 || fte_count > Settings.aca.shop_market.small_market_employee_count_maximum
      warnings.merge!({ fte_count: "Has 1 -#{Settings.aca.shop_market.small_market_employee_count_maximum} full time equivalent employees" })
    end

    # Exclude Jan 1 effective date from certain checks
    unless effective_date.yday == 1
      # Employer contribution toward employee premium must meet minimum
      if benefit_groups.size > 0 && (minimum_employer_contribution < Settings.aca.shop_market.employer_contribution_percent_minimum)
        warnings.merge!({ minimum_employer_contribution:  "Employer contribution percent toward employee premium (#{minimum_employer_contribution.to_i}%) is less than minimum allowed (#{Settings.aca.shop_market.employer_contribution_percent_minimum.to_i}%)" })
      end
    end

    warnings
  end

  def overlapping_published_plan_year?
    self.employer_profile.plan_years.published_or_renewing_published.any? do |py|
      (py.start_on..py.end_on).cover?(self.start_on) && (py != self)
    end
  end

  # All active employees present on the roster with benefit groups belonging to this plan year
  def eligible_to_enroll
    return @eligible if defined? @eligible
    @eligible ||= find_census_employees.active
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

  def find_census_employees
    return @census_employees if defined? @census_employees
    @census_employees ||= CensusEmployee.by_benefit_group_ids(benefit_group_ids)
  end

  def covered_count
    covered.count
  end

  def progressbar_covered_count
    find_census_employees.covered_progressbar.count
  end

  def benefit_group_ids
    benefit_groups.collect(&:id)
  end

  def eligible_to_enroll_count
    eligible_to_enroll.size
  end

  # Employees who selected or waived and are not owners or direct family members of owners
  def non_business_owner_enrolled
    enrolled.select{|ce| !ce.is_business_owner && !ce.waived?}
  end

  # Any employee who selected or waived coverage
  def enrolled
    calc_active_health_assignments_for(eligible_to_enroll)
    #    eligible_to_enroll.select{ |ce| ce.has_active_health_coverage?(self) }
  end

  def enrolled_by_bga
    candidate_benefit_group_assignments = eligible_to_enroll.map{|ce| enrolled_bga_for_ce(ce)}.compact
    enrolled_benefit_group_assignment_ids = HbxEnrollment.enrolled_shop_health_benefit_group_ids(candidate_benefit_group_assignments.map(&:id).uniq)
    bgas = candidate_benefit_group_assignments.select do |bga|
      enrolled_benefit_group_assignment_ids.include?(bga.id)
    end
  end

  def enrolled_bga_for_ce ce
    if is_renewing?
      ce.renewal_benefit_group_assignment
    else
      ce.active_benefit_group_assignment
    end
  end

  def calc_active_health_assignments_for(employee_pool)
    benefit_group_ids = self.benefit_groups.pluck(:_id)
    candidate_benefit_group_assignments = employee_pool.map do |ce|
      bg_assignment = nil
      bg_assignment = ce.active_benefit_group_assignment if benefit_group_ids.include?(ce.active_benefit_group_assignment.try(:benefit_group_id))
      bg_assignment = ce.renewal_benefit_group_assignment if benefit_group_ids.include?(ce.renewal_benefit_group_assignment.try(:benefit_group_id))
      bg_assignment ? [ce, bg_assignment] : nil
    end
    benefit_group_assignment_pairs = candidate_benefit_group_assignments.compact
    benefit_group_assignment_ids = benefit_group_assignment_pairs.map do |bgap|
      bgap.last._id
    end
    enrolled_benefit_group_assignment_ids = HbxEnrollment.enrolled_shop_health_benefit_group_ids(benefit_group_assignment_ids)
    have_shop_health_bgap = benefit_group_assignment_pairs.select do |bgap|
      enrolled_benefit_group_assignment_ids.include?(bgap.last.id)
    end
    have_shop_health_bgap.map(&:first)
  end

  def total_enrolled_count
    if self.employer_profile.census_employees.active.count <= Settings.aca.shop_market.small_market_active_employee_limit
      #enrolled.count
      enrolled_by_bga.count
    else
      0
    end
  end

  def enrollment_ratio
    if eligible_to_enroll_count == 0
      0
    else
      ((total_enrolled_count * 1.0)/ eligible_to_enroll_count)
    end
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

  def is_enrollment_valid?
    enrollment_errors.blank? ? true : false
  end

  def is_open_enrollment_closed?
    open_enrollment_end_on.end_of_day < TimeKeeper.date_of_record.beginning_of_day
  end

  def is_application_period_ended?
    start_on.beginning_of_day <= TimeKeeper.date_of_record.beginning_of_day
  end

  # Determine enrollment composition compliance with HBX-defined guards
  def enrollment_errors
    errors = {}

    # At least one employee must be enrollable.
    if eligible_to_enroll_count == 0
      errors.merge!(eligible_to_enroll_count: "at least one employee must be eligible to enroll")
    end

    # At least one employee who isn't an owner or family member of owner must enroll
    if non_business_owner_enrolled.count < eligible_to_enroll_count
      if non_business_owner_enrolled.count < non_owner_participation_count_minimum
        errors.merge!(non_business_owner_enrollment_count: "at least #{non_owner_participation_count_minimum} non-owner employee must enroll")
      end
    end

    # January 1 effective date exemption(s)
    unless effective_date.yday == 1
      # Verify ratio for minimum number of eligible employees that must enroll is met
      if enrollment_ratio < employee_participation_ratio_minimum
        errors.merge!(enrollment_ratio: "number of eligible participants enrolling (#{total_enrolled_count}) is less than minimum required #{eligible_to_enroll_count * employee_participation_ratio_minimum}")
      end
    end

    errors
  end

  def employees_are_matchable?
    %w(renewing_published renewing_enrolling renewing_enrolled published enrolling enrolled active).include? aasm_state
  end

  def application_warnings
    if !is_application_eligible?
      application_eligibility_warnings.each_pair(){ |key, value| self.errors.add(:base, value) }
    end
  end

  class << self
    def find(id)
      organizations = Organization.where("employer_profile.plan_years._id" => BSON::ObjectId.from_string(id))
      organizations.size > 0 ? organizations.first.employer_profile.plan_years.unscoped.detect { |py| py._id.to_s == id.to_s} : nil
    end

    def shop_enrollment_timetable(new_effective_date)
      effective_date = new_effective_date.to_date.beginning_of_month
      prior_month = effective_date - 1.month
      plan_year_start_on = effective_date
      plan_year_end_on = effective_date + 1.year - 1.day
      employer_initial_application_earliest_start_on = (effective_date + Settings.aca.shop_market.initial_application.earliest_start_prior_to_effective_on.months.months + Settings.aca.shop_market.initial_application.earliest_start_prior_to_effective_on.day_of_month.days)
      employer_initial_application_earliest_submit_on = employer_initial_application_earliest_start_on
      employer_initial_application_latest_submit_on   = ("#{prior_month.year}-#{prior_month.month}-#{HbxProfile::ShopPlanYearPublishedDueDayOfMonth}").to_date
      open_enrollment_earliest_start_on     = effective_date - Settings.aca.shop_market.open_enrollment.maximum_length.months.months
      open_enrollment_latest_start_on       = ("#{prior_month.year}-#{prior_month.month}-#{HbxProfile::ShopOpenEnrollmentBeginDueDayOfMonth}").to_date
      open_enrollment_latest_end_on         = ("#{prior_month.year}-#{prior_month.month}-#{PlanYear.shop_market_open_enrollment_monthly_end_on}").to_date
      binder_payment_due_date               = first_banking_date_prior ("#{prior_month.year}-#{prior_month.month}-#{PlanYear.shop_market_binder_payment_due_on}")
      advertised_due_date_of_month          = ("#{prior_month.year}-#{prior_month.month}-#{HbxProfile::ShopOpenEnrollmentAdvBeginDueDayOfMonth}").to_date


      timetable = {
        effective_date: effective_date,
        plan_year_start_on: plan_year_start_on,
        plan_year_end_on: plan_year_end_on,
        employer_initial_application_earliest_start_on: employer_initial_application_earliest_start_on,
        employer_initial_application_earliest_submit_on: employer_initial_application_earliest_submit_on,
        employer_initial_application_latest_submit_on: employer_initial_application_latest_submit_on,
        open_enrollment_earliest_start_on: open_enrollment_earliest_start_on,
        open_enrollment_latest_start_on: open_enrollment_latest_start_on,
        open_enrollment_latest_end_on: open_enrollment_latest_end_on,
        binder_payment_due_date: binder_payment_due_date,
        advertised_due_date_of_month: advertised_due_date_of_month
      }

      timetable
    end

    def check_start_on(start_on)
      start_on = start_on.to_date
      shop_enrollment_times = shop_enrollment_timetable(start_on)

      if start_on.day != 1
        result = "failure"
        msg = "start on must be first day of the month"
      elsif TimeKeeper.date_of_record > shop_enrollment_times[:open_enrollment_latest_start_on]
        result = "failure"
        msg = "must choose a start on date #{(TimeKeeper.date_of_record - HbxProfile::ShopOpenEnrollmentBeginDueDayOfMonth + Settings.aca.shop_market.open_enrollment.maximum_length.months.months).beginning_of_month} or later"
      end
      {result: (result || "ok"), msg: (msg || "")}
    end

    def calculate_start_on_dates
      # Today - 5 + 2.months).beginning_of_month
      # July 6 => Sept 1
      # July 1 => Aug 1
      start_on = (TimeKeeper.date_of_record - HbxProfile::ShopOpenEnrollmentBeginDueDayOfMonth + Settings.aca.shop_market.open_enrollment.maximum_length.months.months).beginning_of_month
      end_on = (TimeKeeper.date_of_record - Settings.aca.shop_market.initial_application.earliest_start_prior_to_effective_on.months.months - enrollment_shopping_start_day_offset).beginning_of_month
      dates = (start_on..end_on).select {|t| t == t.beginning_of_month}
    end

    def calculate_start_on_options
      calculate_start_on_dates.map {|date| [date.strftime("%B %Y"), date.to_s(:db) ]}
    end

    def calculate_open_enrollment_date(start_on)
      start_on = start_on.to_date

      # open_enrollment_start_on = [start_on - 1.month, TimeKeeper.date_of_record].max
      # candidate_open_enrollment_end_on = Date.new(open_enrollment_start_on.year.to_i, open_enrollment_start_on.month.to_i, Settings.aca.shop_market.open_enrollment.monthly_end_on)

      # open_enrollment_end_on = if (candidate_open_enrollment_end_on - open_enrollment_start_on) < (Settings.aca.shop_market.open_enrollment.minimum_length.days - 1)
      #   candidate_open_enrollment_end_on.next_month
      # else
      #   candidate_open_enrollment_end_on
      # end

      open_enrollment_start_on = [(start_on - Settings.aca.shop_market.open_enrollment.maximum_length.months.months), TimeKeeper.date_of_record].max

      #candidate_open_enrollment_end_on = Date.new(open_enrollment_start_on.year, open_enrollment_start_on.month, Settings.aca.shop_market.open_enrollment.monthly_end_on)

      #open_enrollment_end_on = if (candidate_open_enrollment_end_on - open_enrollment_start_on) < (Settings.aca.shop_market.open_enrollment.minimum_length.days - 1)
      #  candidate_open_enrollment_end_on.next_month
      #else
      #  candidate_open_enrollment_end_on
      #end

      open_enrollment_end_on = shop_enrollment_timetable(start_on)[:open_enrollment_latest_end_on]

      binder_payment_due_date = map_binder_payment_due_date_by_start_on(start_on)

      {open_enrollment_start_on: open_enrollment_start_on,
       open_enrollment_end_on: open_enrollment_end_on,
       binder_payment_due_date: binder_payment_due_date}
    end

    def map_binder_payment_due_date_by_start_on(start_on)
      #list of bank holidays.
      event_arr = [
        { event_name: "New Year's Day", event_date: schedule_time(Date.new(Date.today.year, 1, 1)) },
        { event_name: "Martin birthday", event_date: nth_wday(3, 1, 1, Date.today.year)},
        { event_name: "President's Day", event_date: nth_wday(3, 1, 2, Date.today.year) },
        { event_name: "Memorial Day", event_date: last_monday_may(Date.today.year, 5, 31) },
        { event_name: "Labor day", event_date: nth_wday(1, 1, 9, Date.today.year) },
        { event_name: "Columbus Day", event_date: nth_wday(2, 1, 10, Date.today.year) },
        { event_name: "Veterans Day", event_date: schedule_time(Date.new(Date.today.year, 11, 11)) },
        { event_name: "Thanksgiving Day", event_date: nth_wday(4, 4, 11, Date.today.year) },
        { event_name: "Christmas Day", event_date: schedule_time(Date.new(Date.today.year, 12, 25)) },
        { event_name: "Independence Day", event_date: schedule_time(Date.new(Date.today.year, 7, 4)) }
      ]
      event_date_arr = event_arr.map{|hsh| schedule_time(hsh[:event_date])}
      due_day = Settings.aca.shop_market.binder_payment_due_on
      dates_map = {}
      month = start_on.month
      key = Date.new(TimeKeeper.date_of_record.year, month, 1)
      year = TimeKeeper.date_of_record.year
      if (month == 0)
        month = 12
        year -=1
      end

      to_date = start_on.prev_month + (Settings.aca.shop_market.binder_payment_due_on).days - 1
      while event_date_arr.include?(to_date) || to_date.wday == 6 || to_date.wday == 0 || to_date.wday == 1
        to_date = to_date+1.day #If to_date is in holidays arr, we are adding +1 day
      end
      dates_map[key] = to_date
      dates_map[start_on]  || shop_enrollment_timetable(start_on)[:binder_payment_due_date]
    end

    ## TODO - add holidays
    def first_banking_date_prior(date_value)
      date = date_value.to_date
      date = date - 1 if date.saturday?
      date = date - 2 if date.sunday?
      date
    end

    def first_banking_date_after(date_value)
      date = date_value.to_date
      date = date + 2 if date.saturday?
      date = date + 1 if date.sunday?
      date
    end

    def open_enrollment_start_period_with_offset(date)
      date - Settings.aca.shop_market.initial_application.earliest_start_prior_to_effective_on.months.months + Settings.aca.shop_market.initial_application.earliest_start_prior_to_effective_on.day_of_month.days
    end
    ## end class method
  end

  def open_enrollment_start_period_with_offset(date)
    date - Settings.aca.shop_market.initial_application.earliest_start_prior_to_effective_on.months.months + Settings.aca.shop_market.initial_application.earliest_start_prior_to_effective_on.day_of_month.days
  end

  aasm do
    state :draft, initial: true

    state :publish_pending      # Plan application as submitted has warnings
    state :eligibility_review   # Plan application was submitted with warning and is under review by HBX officials
    state :published,         :after_enter => [:accept_application, :link_census_employees]     # Plan is finalized. Employees may view benefits, but not enroll
    state :published_invalid, :after_enter => :decline_application    # Non-compliant plan application was forced-published
    state :enrolled,  :after_enter => [:ratify_enrollment, :finalize_composite_rates] # Published plan open enrollment has ended and is eligible for coverage,
    state :enrolling, :after_enter => [:send_employee_invites, :link_census_employees]  # Published plan has entered open enrollment
    #   but effective date is in future
    state :application_ineligible, :after_enter => :deny_enrollment   # Application is non-compliant for enrollment
    state :expired              # Non-published plans are expired following their end on date
    state :canceled,          :after_enter => :cancel_application             # Published plan open enrollment has ended and is ineligible for coverage
    state :active               # Published plan year is in-force

    state :renewing_draft#, :after_enter => :renewal_group_notice # renewal_group_notice - Sends a notice three months prior to plan year renewing
    state :renewing_published
    state :renewing_publish_pending
    state :renewing_enrolling, :after_enter => [:trigger_passive_renewals, :send_employee_invites]
    state :renewing_enrolled, :after_enter => [:renewal_successful, :finalize_composite_rates]
    state :renewing_application_ineligible, :after_enter => :deny_enrollment  # Renewal application is non-compliant for enrollment
    state :renewing_canceled,          :after_enter => :cancel_application

    state :suspended            # Premium payment is 61-90 days past due and coverage is currently not in effect
    state :terminated, :after_enter => :terminate_application           # Coverage under this application is terminated
    state :conversion_expired   # Conversion employers who did not establish eligibility in a timely manner
    state :termination_pending

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
      transitions from: :enrolling, to: :application_ineligible,  :guard => :is_open_enrollment_closed?

      # transitions from: :enrolling, to: :canceled,  :guard  => :is_open_enrollment_closed?, :after => :deny_enrollment  # Talk to Dan

      transitions from: :active, to: :terminated, :guard => :is_event_date_valid?
      transitions from: [:draft, :ineligible, :publish_pending, :published_invalid, :eligibility_review], to: :expired, :guard => :is_plan_year_end?

      transitions from: :renewing_enrolled,   to: :active,              :guard  => :is_event_date_valid?
      transitions from: :renewing_published,  to: :renewing_enrolling,  :guard  => :is_event_date_valid?
      transitions from: :renewing_enrolling,  to: :renewing_enrolled,   :guards => [:is_open_enrollment_closed?, :is_enrollment_valid?]
      transitions from: :renewing_enrolling,  to: :renewing_application_ineligible, :guard => :is_open_enrollment_closed?#, :after => [:renewal_employer_ineligibility_notice, :zero_employees_on_roster] DC side changes

      transitions from: :enrolling, to: :enrolling  # prevents error when plan year is already enrolling
    end

    ## Application eligibility determination process

    # Submit plan year application
    event :publish, :after => :record_transition do
      transitions from: :draft, to: :draft,     :guard => :is_application_unpublishable?
      transitions from: :draft, to: :enrolling, :guard => [:is_application_eligible?, :is_event_date_valid?], :after => [:accept_application, :record_sic_and_rating_area]
      transitions from: :draft, to: :published, :guard => :is_application_eligible?, :after => :record_sic_and_rating_area
      transitions from: :draft, to: :publish_pending

      transitions from: :renewing_draft, to: :renewing_draft,     :guard => :is_application_unpublishable?
      transitions from: :renewing_draft, to: :renewing_enrolling, :guard => [:is_application_eligible?, :is_event_date_valid?], :after => [:accept_application, :record_sic_and_rating_area]
      transitions from: :renewing_draft, to: :renewing_published, :guard => :is_application_eligible? , :after => [:record_sic_and_rating_area]
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
      transitions from: :draft, to: :enrolling, :guard => [:is_application_eligible?, :is_event_date_valid?], :after => [:accept_application, :record_sic_and_rating_area]
      transitions from: :draft, to: :published, :guard => :is_application_eligible?, :after => :record_sic_and_rating_area
      transitions from: :draft, to: :publish_pending

      transitions from: :renewing_draft, to: :renewing_draft,     :guard => :is_application_invalid?
      transitions from: :renewing_draft, to: :renewing_enrolling, :guard => [:is_application_eligible?, :is_event_date_valid?], :after => [:accept_application, :record_sic_and_rating_area]
      transitions from: :renewing_draft, to: :renewing_published, :guard => :is_application_eligible?, :after => [:record_sic_and_rating_area]
      transitions from: :renewing_draft, to: :renewing_publish_pending #:after => :employer_renewal_eligibility_denial_notice, :notify_employee_of_renewing_employer_ineligibility
    end

    # Employer requests review of invalid application determination
    event :request_eligibility_review, :after => :record_transition do
      transitions from: :published_invalid, to: :eligibility_review, :guard => :is_within_review_period?
    end

    # Upon review, application ineligible status overturned and deemed eligible
    event :grant_eligibility, :after => :record_transition do
      transitions from: :eligibility_review, to: :published, :after => :record_sic_and_rating_area
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

    event :terminate, :after => :record_transition do
      transitions from: [:active, :suspended, :termination_pending], to: :terminated
    end

    # Termination pending due to attestation document rejection
    event :schedule_termination, :after => :record_transition do
      transitions from: :active, to: :termination_pending, :after => [:set_termination_date, :schedule_employee_terminations]
    end

    # Coverage reinstated
    event :reinstate_plan_year, :after => :record_transition do
      transitions from: :terminated, to: :active, after: :reset_termination_and_end_date
    end

    event :renew_plan_year, :after => :record_transition do
      transitions from: :draft, to: :renewing_draft
    end

    event :renew_publish, :after => :record_transition do
      transitions from: :renewing_draft, to: :renewing_published, :after => :record_sic_and_rating_area
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

  def cancel_enrollments
    self.hbx_enrollments.each do |enrollment|
      enrollment.cancel_coverage! if enrollment.may_cancel_coverage?
    end
  end

  def trigger_passive_renewals
    open_enrollment_factory = Factories::EmployerOpenEnrollmentFactory.new
    open_enrollment_factory.employer_profile = self.employer_profile
    open_enrollment_factory.date = TimeKeeper.date_of_record
    open_enrollment_factory.renewing_plan_year = self
    open_enrollment_factory.process_family_enrollment_renewals
  end

  def revert_employer_profile_application
    employer_profile.revert_application! if employer_profile.may_revert_application?
    record_transition
  end

  def adjust_open_enrollment_date
    if TimeKeeper.date_of_record > open_enrollment_start_on && TimeKeeper.date_of_record < open_enrollment_end_on
      update_attributes(:open_enrollment_start_on => TimeKeeper.date_of_record)
    end
  end

  def schedule_employee_terminations(terminated_on=TimeKeeper.date_of_record.end_of_month)
    hbx_enrollments.each do |hbx_enrollment|
      if hbx_enrollment.may_schedule_coverage_termination?
        hbx_enrollment.schedule_coverage_termination!(terminated_on)
      end
    end
  end

  def set_termination_date(termination_date = TimeKeeper.date_of_record.end_of_month)
    self.update_attributes({ end_on: termination_date, terminated_on: termination_date })
  end

  def terminate_application
    employer_profile.benefit_terminated! if employer_profile.may_benefit_terminated?
  end

  def cancel_application
    cancel_employee_enrollments
    employer_profile.benefit_canceled! if canceled? && employer_profile.may_benefit_canceled?
  end

  def cancel_employee_enrollments
    id_list = benefit_groups.pluck(:id)
    families = Family.where(:"households.hbx_enrollments.benefit_group_id".in => id_list)
    families.each do |family|
      family.active_household.hbx_enrollments.where(:benefit_group_id.in => id_list).non_expired_and_non_terminated.each do |en|
        en.cancel_coverage! if en.may_cancel_coverage?
      end
    end
  end

  def accept_application
    adjust_open_enrollment_date
    transition_success = employer_profile.application_accepted! if employer_profile.may_application_accepted?
  end

  def decline_application
    employer_profile.application_declined!
  end

  def ratify_enrollment
    employer_profile.enrollment_ratified! if employer_profile.may_enrollment_ratified?
  end

  def deny_enrollment
    if employer_profile.may_enrollment_denied?
      employer_profile.enrollment_denied!
    end
  end

  def is_eligible_to_match_census_employees?
    (benefit_groups.size > 0) and
      (published? or enrolling? or enrolled? or active?)
  end

  def is_within_review_period?
    published_invalid? and
      (latest_workflow_state_transition.transition_at >
       (TimeKeeper.date_of_record - Settings.aca.shop_market.initial_application.appeal_period_after_application_denial.days))
  end

  def latest_workflow_state_transition
    workflow_state_transitions.order_by(:'transition_at'.desc).limit(1).first
  end

  def is_before_start?
    TimeKeeper.date_of_record.end_of_day < start_on
  end

  # Checks for external plan year
  def can_be_migrated?
    self.employer_profile.is_conversion? && self.is_conversion
  end

  def link_census_employees
    self.employer_profile.census_employees.eligible_without_term_pending.each do |census_employee|
      census_employee.save # This assigns default benefit package if none
    end
  end

  alias_method :external_plan_year?, :can_be_migrated?

  def estimate_group_size?
    [
      "draft",
      "publish_pending",
      "eligibility_review",
      "published",
      "published_invalid",
      "enrolling",
      "application_ineligible",
      "canceled",
      "renewing_draft",
      "renewing_published",
      "renewing_publish_pending",
      "renewing_enrolling",
      "renewing_application_ineligible",
      "renewing_canceled"
    ].include?(aasm_state)
  end

  def sic_code
    recorded_sic_code.blank? ? employer_profile.sic_code : recorded_sic_code
  end

  def rating_area
    recorded_rating_area.blank? ? employer_profile.rating_area : recorded_rating_area
  end

  def service_area
    recorded_service_area.blank? ? employer_profile.service_area : recorded_service_area
  end

  def products_offered_in_service_area
    return(true) unless constrain_service_areas?
    return(true) if employer_profile.nil?
    return(true) if start_on.blank?
    if employer_profile.service_areas_available_on(start_on).empty?
      errors.add(:start_on, "No products are available in your area at this time.")
      return(false)
    end
    true
  end

  private

  def log_message(errors)
    msg = yield.first
    (errors[msg[0]] ||= []) << msg[1]
  end

  def can_be_expired?
    if PUBLISHED.include?(aasm_state) && TimeKeeper.date_of_record >= end_on
      true
    else
      false
    end
  end

  def can_be_activated?
    if (PUBLISHED + RENEWING_PUBLISHED_STATE).include?(aasm_state) && TimeKeeper.date_of_record >= start_on
      true
    else
      false
    end
  end

  def is_event_date_valid?
    today = TimeKeeper.date_of_record
    valid = case aasm_state
            when "published", "draft", "renewing_published", "renewing_draft"
              today >= open_enrollment_start_on
            when "enrolling", "renewing_enrolling"
              today > open_enrollment_end_on
            when "enrolled", "renewing_enrolled"
              today >= start_on
            when "active"
              today > end_on
            else
              false
            end

    valid
  end

  def is_plan_year_end?
    TimeKeeper.date_of_record.end_of_day == end_on
  end

  # When publishing happens, 'freeze' the sic code and rating area
  # Also do any composite estimation needed
  def record_sic_and_rating_area
    self.recorded_sic_code = employer_profile.sic_code
    self.recorded_rating_area = employer_profile.rating_area
    self.benefit_groups.each do |bg|
      bg.estimate_composite_rates
    end
  end

  def trigger_renewal_notice
    return true if benefit_groups.any?{|bg| bg.is_congress?}
    event_name = aasm.current_event.to_s.gsub(/!/, '')
    if event_name == "publish"
      begin
        self.employer_profile.trigger_notices("planyear_renewal_3a", "acapi_trigger" =>  true)
      rescue Exception => e
        Rails.logger.error { "Unable to deliver employer renewal publish notice for #{self.employer_profile.organization.legal_name} due to #{e}" }
      end
    elsif event_name == "force_publish"
      begin
        self.employer_profile.trigger_notices("planyear_renewal_3b", "acapi_trigger" =>  true)
      rescue Exception => e
        Rails.logger.error { "Unable to deliver employer renewal force publish notice for #{self.employer_profile.organization.legal_name} due to #{e}" }
      end
    end
  end

  def renewal_group_notice
    event_name = aasm.current_event.to_s.gsub(/!/, '')
    return true if (benefit_groups.any?{|bg| bg.is_congress?} || ["publish","withdraw_pending","revert_renewal"].include?(event_name))
    if self.employer_profile.is_converting?
      begin
        self.employer_profile.trigger_notices("conversion_group_renewal")
      rescue Exception => e
        Rails.logger.error { "Unable to deliver employer conversion group renewal notice for #{self.employer_profile.organization.legal_name} due to #{e}" }
      end
    else
      begin
        self.employer_profile.trigger_notices("group_renewal_5", "acapi_trigger" => true)
      rescue Exception => e
        Rails.logger.error { "Unable to deliver employer group_renewal_5 notice for #{self.employer_profile.organization.legal_name} due to #{e}" }
      end
    end
  end

  #notice will be sent to employees when a renewing employer has his primary office address outside of DC.
  def notify_employee_of_renewing_employer_ineligibility
    return true if benefit_groups.any?{|bg| bg.is_congress?}
    if application_eligibility_warnings.include?(:primary_office_location)
      self.employer_profile.census_employees.non_terminated.each do |ce|
        begin
          ShopNoticesNotifierJob.perform_later(ce.id.to_s, "notify_employee_of_renewing_employer_ineligibility")
        rescue Exception => e
          Rails.logger.error { "Unable to deliver employee employer renewal denial notice for #{self.employer_profile.organization.legal_name} due to #{e}" }
        end
      end
    end
  end

  def initial_employer_open_enrollment_begins
    return true if (benefit_groups.any?{|bg| bg.is_congress?})
    self.employer_profile.trigger_notices("initial_eligibile_employer_open_enrollment_begins")
  end

  def finalize_composite_rates
    benefit_groups.each do |bg|
      bg.finalize_composite_rates
    end
  end

  def renewal_successful
    if transmit_employers_immediately?
      employer_profile.transmit_renewal_eligible_event
    end
  end

  def renewal_employer_open_enrollment_completed
    return true if benefit_groups.any?{|bg| bg.is_congress?}
    self.employer_profile.trigger_notices("renewal_employer_open_enrollment_completed")
  end

  def renewal_employer_ineligibility_notice
    return true if benefit_groups.any? { |bg| bg.is_congress? }
    begin
      self.employer_profile.trigger_notices("renewal_employer_ineligibility_notice", "acapi_trigger" =>  true)
    rescue Exception => e
      Rails.logger.error { "Unable to deliver employer renewal ineligiblity denial notice for #{self.employer_profile.organization.legal_name} due to #{e}" }
    end
  end

  def employer_renewal_eligibility_denial_notice
    if application_eligibility_warnings.include?(:primary_office_location)
      begin
        ShopNoticesNotifierJob.perform_later(self.employer_profile.id.to_s, "employer_renewal_eligibility_denial_notice")
      rescue Exception => e
        Rails.logger.error { "Unable to deliver employer renewal eligiblity denial notice for #{self.employer_profile.organization.legal_name} due to #{e}" }
      end
    end
  end

  def initial_employee_plan_selection_confirmation
    return true if (benefit_groups.any?{|bg| bg.is_congress?})
    self.employer_profile.census_employees.non_terminated.each do |ce|
      begin
        ShopNoticesNotifierJob.perform_later(ce.id.to_s, "initial_employee_plan_selection_confirmation")
      rescue Exception => e
        puts "Unable to send Employee Open Enrollment begin notice to #{ce.full_name}" unless Rails.env.test?
      end
    end
  end

  def record_transition
    self.workflow_state_transitions << WorkflowStateTransition.new(
      from_state: aasm.from_state,
      to_state: aasm.to_state,
      event: aasm.current_event
    )
  end

  def send_employee_renewal_invites
    benefit_groups.each do |bg|
      bg.census_employees.non_terminated.each do |ce|
        Invitation.invite_renewal_employee!(ce)
      end
    end
  end

  def send_employee_initial_enrollment_invites
    benefit_groups.each do |bg|
      bg.census_employees.non_terminated.each do |ce|
        Invitation.invite_initial_employee!(ce)
      end
    end
  end

  def send_active_employee_invites
    benefit_groups.each do |bg|
      bg.census_employees.non_terminated.each do |ce|
        Invitation.invite_employee!(ce)
      end
    end
  end

  def send_employee_invites
    return true if benefit_groups.any?{|bg| bg.is_congress?}
    if is_renewing?
      notify("acapi.info.events.plan_year.employee_renewal_invitations_requested", {:plan_year_id => self.id.to_s})
    elsif enrolling?
      notify("acapi.info.events.plan_year.employee_initial_enrollment_invitations_requested", {:plan_year_id => self.id.to_s})
    else
      notify("acapi.info.events.plan_year.employee_enrollment_invitations_requested", {:plan_year_id => self.id.to_s})
    end
  end

  def within_review_period?
    (latest_workflow_state_transition.transition_at.end_of_day + Settings.aca.shop_market.initial_application.appeal_period_after_application_denial.days) > TimeKeeper.date_of_record
  end

  def duration_in_days(duration)
    (duration / 1.day).to_i
  end

  def open_enrollment_date_checks
    return if canceled? || expired? || renewing_canceled?
    return if start_on.blank? || end_on.blank? || open_enrollment_start_on.blank? || open_enrollment_end_on.blank?
    return if imported_plan_year

    if start_on != start_on.beginning_of_month
      errors.add(:start_on, "must be first day of the month")
    end

    if end_on > start_on.years_since(Settings.aca.shop_market.benefit_period.length_maximum.year)
      errors.add(:end_on, "benefit period may not exceed #{Settings.aca.shop_market.benefit_period.length_maximum.year} year")
    end

    if open_enrollment_end_on > start_on
      errors.add(:start_on, "can't occur before open enrollment end date")
    end

    if open_enrollment_end_on < open_enrollment_start_on
      errors.add(:open_enrollment_end_on, "can't occur before open enrollment start date")
    end

    if open_enrollment_start_on < (start_on - Settings.aca.shop_market.open_enrollment.maximum_length.months.months)
      errors.add(:open_enrollment_start_on, "can't occur before 60 days before start date")
    end

    if open_enrollment_end_on > (open_enrollment_start_on + Settings.aca.shop_market.open_enrollment.maximum_length.months.months)
      errors.add(:open_enrollment_end_on, "open enrollment period is greater than maximum: #{Settings.aca.shop_market.open_enrollment.maximum_length.months} months")
    end

    if (start_on + Settings.aca.shop_market.initial_application.earliest_start_prior_to_effective_on.months.months) > TimeKeeper.date_of_record
      errors.add(:start_on, "may not start application before " \
                 "#{(start_on + Settings.aca.shop_market.initial_application.earliest_start_prior_to_effective_on.months.months).to_date} with #{start_on} effective date")
    end

    if !['canceled', 'suspended', 'terminated','termination_pending'].include?(aasm_state)
      #groups terminated for non-payment get 31 more days of coverage from their paid through date
      if end_on != end_on.end_of_month
        errors.add(:end_on, "must be last day of the month")
      end


      if end_on != (start_on + Settings.aca.shop_market.benefit_period.length_minimum.year.years - 1.day)
        errors.add(:end_on, "plan year period should be: #{duration_in_days(Settings.aca.shop_market.benefit_period.length_minimum.year.years - 1.day)} days")
      end
    end
  end

  def reset_termination_and_end_date
    update_attributes!({terminated_on: nil, end_on: start_on.next_year.prev_day})
  end
end
