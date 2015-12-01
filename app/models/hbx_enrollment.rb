require 'ostruct'

class HbxEnrollment
  include Mongoid::Document
  include SetCurrentUser
  include Mongoid::Timestamps
  include HasFamilyMembers
  include AASM
  include MongoidSupport::AssociationProxies
  include Acapi::Notifiers
  extend Acapi::Notifiers
  Kinds = %W[unassisted_qhp insurance_assisted_qhp employer_sponsored streamlined_medicaid emergency_medicaid hcr_chip individual]
  Authority = [:open_enrollment]
  WAIVER_REASONS = [
    "I have coverage through spouse’s employer health plan",
    "I have coverage through parent’s employer health plan",
    "I have coverage through any other employer health plan",
    "I have coverage through an individual market health plan",
    "I have coverage through Medicare",
    "I have coverage through Tricare",
    "I have coverage through Medicaid",
    "I do not have other coverage"
  ]

  ENROLLMENT_CREATED_EVENT_NAME = "acapi.info.events.policy.created"
  ENROLLMENT_UPDATED_EVENT_NAME = "acapi.info.events.policy.updated"

  ENROLLED_STATUSES = [
      "coverage_selected",
      "transmitted_to_carrier",
      "coverage_enrolled",
      "coverage_renewed",
      "enrolled_contingent",
      "unverified"
    ]

  TERMINATED_STATUSES = ["coverage_terminated", "coverage_canceled", "unverified"]
  RENEWAL_STATUSES = %w(auto_renewing renewing_coverage_selected renewing_transmitted_to_carrier renewing_coverage_enrolled)

  ENROLLMENT_KINDS = ["open_enrollment", "special_enrollment"]

  ENROLLMENT_TRAIN_STOPS_STEPS = {"coverage_selected" => 1, "transmitted_to_carrier" => 2, "coverage_enrolled" => 3,
                                  "auto_renewing" => 1, "renewing_coverage_selected" => 1, "renewing_transmitted_to_carrier" => 2, "renewing_coverage_enrolled" => 3}
  ENROLLMENT_TRAIN_STOPS_STEPS.default = 0

  COVERAGE_KINDS = %w[health dental]

  embedded_in :household

  field :coverage_household_id, type: String
  field :kind, type: String
  field :enrollment_kind, type: String, default: 'open_enrollment'
  field :coverage_kind, type: String, default: 'health'

  # FIXME: This unblocks people with legacy data where this field exists,
  #        preventing user registration as in #3394.  This is NOT a correct
  #        fix to that issue and it still needs to be addressed.
  field :elected_amount, type: Money, default: 0.0

  field :elected_premium_credit, type: Money, default: 0.0
  field :applied_premium_credit, type: Money, default: 0.0
  # TODO need to understand these two fields
  field :elected_aptc_pct, type: Float, default: 0.0
  field :applied_aptc_amount, type: Money, default: 0.0
  field :changing, type: Boolean, default: false

  field :effective_on, type: Date
  field :terminated_on, type: Date

  field :plan_id, type: BSON::ObjectId
  field :broker_agency_profile_id, type: BSON::ObjectId
  field :writing_agent_id, type: BSON::ObjectId
  field :employee_role_id, type: BSON::ObjectId
  field :benefit_group_id, type: BSON::ObjectId
  field :benefit_group_assignment_id, type: BSON::ObjectId
  field :hbx_id, type: String
  field :special_enrollment_period_id, type: BSON::ObjectId

  field :consumer_role_id, type: BSON::ObjectId
  field :benefit_package_id, type: BSON::ObjectId

  field :original_application_type, type: String

  field :submitted_at, type: DateTime

  field :aasm_state, type: String
  field :aasm_state_date, type: Date
  field :updated_by, type: String
  field :is_active, type: Boolean, default: true
  field :waiver_reason, type: String
  field :published_to_bus_at, type: DateTime

  associated_with_one :benefit_group, :benefit_group_id, "BenefitGroup"
  associated_with_one :benefit_group_assignment, :benefit_group_assignment_id, "BenefitGroupAssignment"
  associated_with_one :employee_role, :employee_role_id, "EmployeeRole"
  associated_with_one :consumer_role, :consumer_role_id, "ConsumerRole"

  delegate :total_premium, :total_employer_contribution, :total_employee_cost, to: :decorated_hbx_enrollment, allow_nil: true
  delegate :premium_for, to: :decorated_hbx_enrollment, allow_nil: true

  scope :active,              ->{ where(is_active: true).where(:created_at.ne => nil) }
  scope :open_enrollments,    ->{ where(enrollment_kind: "open_enrollment") }
  scope :special_enrollments, ->{ where(enrollment_kind: "special_enrollment") }
  scope :my_enrolled_plans,   ->{ where(:aasm_state.ne => "shopping", :plan_id.ne => nil ) } # a dummy plan has no plan id
  scope :current_year,        ->{ where(:effective_on.gte => TimeKeeper.date_of_record.beginning_of_year, :effective_on.lte => TimeKeeper.date_of_record.end_of_year) }
  scope :by_year,             ->(year) { where(effective_on: (Date.new(year)..Date.new(year).end_of_year)) }
  scope :with_aptc,           ->{ gt("applied_aptc_amount.cents": 0) }
  scope :enrolled,            ->{ where(:aasm_state.in => ENROLLED_STATUSES ) }
  scope :renewing,            ->{ where(:aasm_state.in => RENEWAL_STATUSES )}
  scope :waived,              ->{ where(:aasm_state.in => ["inactive", "renewing_waived"] )}
  scope :changing,            ->{ where(changing: true) }
  scope :with_in,             ->(time_limit){ where(:created_at.gte => time_limit) }
  scope :shop_market,         ->{ where(:kind => "employer_sponsored") }
  scope :individual_market,   ->{ where(:kind.ne => "employer_sponsored") }

  scope :terminated, -> { where(:aasm_state.in => TERMINATED_STATUSES, :terminated_on.gte => TimeKeeper.date_of_record.beginning_of_day) }
  scope :show_enrollments, -> { any_of([enrolled.selector, renewing.selector, terminated.selector]) }
  scope :with_plan, -> { where(:plan_id.ne => nil) }

  embeds_many :workflow_state_transitions, as: :transitional

  embeds_many :hbx_enrollment_members
  accepts_nested_attributes_for :hbx_enrollment_members, reject_if: :all_blank, allow_destroy: true

  embeds_many :comments
  accepts_nested_attributes_for :comments, reject_if: proc { |attribs| attribs['content'].blank? }, allow_destroy: true

  validates :kind,
            presence: true,
            allow_blank: false,
            allow_nil:   false,
            inclusion: {in: Kinds, message: "%{value} is not a valid enrollment type"}

  validates :enrollment_kind,
    allow_blank: false,
    inclusion: {
      in: ENROLLMENT_KINDS,
      message: "%{value} is not a valid enrollment kind"
    }

  validates :coverage_kind,
    allow_blank: false,
    inclusion: {
      in: COVERAGE_KINDS,
      message: "%{value} is not a valid coverage type"
    }

  before_save :generate_hbx_id

  def record_transition
    self.workflow_state_transitions << WorkflowStateTransition.new(
      from_state: aasm.from_state,
      to_state: aasm.to_state
    )
  end

  def self.by_hbx_id(policy_hbx_id)
    families = Family.with_enrollment_hbx_id(policy_hbx_id)
    households = families.flat_map(&:households)
    households.flat_map(&:hbx_enrollments).select do |hbxe|
      hbxe.hbx_id == policy_hbx_id
    end
  end

  def self.update_individual_eligibilities_for(consumer_role)
    found_families = Family.find_all_by_person(consumer_role.person)
    found_families.each do |ff|
      ff.households.each do |hh|
        hh.hbx_enrollments.active.each do |he|
          he.evaluate_individual_market_eligiblity
        end
      end
    end
  end

  def evaluate_individual_market_eligiblity
    eligibility_ruleset = ::RuleSet::HbxEnrollment::IndividualMarketVerification.new(self)
    if eligibility_ruleset.applicable?
      self.send(eligibility_ruleset.determine_next_state)
    end
  end

  def coverage_kind
    read_attribute(:coverage_kind) || self.plan.coverage_kind
  end

  def census_employee
    if employee_role.present?
      employee_role.census_employee
    else
      benefit_group_assignment.census_employee
    end
  end

  def benefit_sponsored?
    benefit_group.present?
  end

  def affected_by_verifications_made_today?
    return false if shopping?
    return true if terminated_on.blank?
    terminated_on >= TimeKeeper.date_of_record
  end

  def currently_active?
    return false if shopping?
    return false unless (effective_on <= TimeKeeper.date_of_record)
    return true if terminated_on.blank?
    terminated_on >= TimeKeeper.date_of_record
  end

  def generate_hbx_id
    write_attribute(:hbx_id, HbxIdGenerator.generate_policy_id) if hbx_id.blank?
  end

  def propogate_terminate(term_date = TimeKeeper.date_of_record.end_of_month)
    self.terminated_on = term_date
    if benefit_group_assignment
      benefit_group_assignment.end_benefit(term_date)
      benefit_group_assignment.save
    end

    if should_transmit_update?
      notify(ENROLLMENT_UPDATED_EVENT_NAME, {policy_id: self.hbx_id})
    end
  end

  def propogate_waiver
    benefit_group_assignment.try(:waive_coverage!) if benefit_group_assignment
  end

  def propogate_selection
    if benefit_group_assignment
      benefit_group_assignment.select_coverage if benefit_group_assignment.may_select_coverage?
      benefit_group_assignment.hbx_enrollment = self
      benefit_group_assignment.save
    end
    if consumer_role.present?
      hbx_enrollment_members.each do |hem|
        hem.person.consumer_role.start_individual_market_eligibility!(effective_on)
      end
      notify(ENROLLMENT_CREATED_EVENT_NAME, {policy_id: self.hbx_id})
      self.published_to_bus_at = Time.now
    else
      if is_shop_sep?
        notify(ENROLLMENT_CREATED_EVENT_NAME, {policy_id: self.hbx_id})
        self.published_to_bus_at = Time.now
      end
    end
  end

  def is_active?
    self.is_active
  end

  def should_transmit_update?
    !self.published_to_bus_at.blank?
  end

  def is_coverage_waived?
    inactive?
  end

  def is_shop?
    kind == "employer_sponsored"
  end

  def is_shop_sep?
    is_shop? && is_special_enrollment?
  end

  def is_open_enrollment?
    enrollment_kind == "open_enrollment"
  end

  def is_special_enrollment?
    enrollment_kind == "special_enrollment"
  end

  def transmit_shop_enrollment!
    if !consumer_role.present?
      if !is_shop_sep?
        notify(ENROLLMENT_CREATED_EVENT_NAME, {policy_id: self.hbx_id})
        self.published_to_bus_at = Time.now
        self.save!
      end
    end
  end

  def subscriber
    hbx_enrollment_members.detect(&:is_subscriber)
  end

  def family
    household.family if household.present?
  end

  def applicant_ids
    hbx_enrollment_members.map(&:applicant_id)
  end

  def employer_profile
    if self.employee_role.present?
      self.employee_role.employer_profile
    elsif !self.benefit_group_id.blank?
      self.benefit_group.employer_profile
    else
      nil
    end
  end

  def enroll_step
    ENROLLMENT_TRAIN_STOPS_STEPS[self.aasm_state]
  end

  def special_enrollment_period
    return @special_enrollment_period if defined? @special_enrollment_period
    return nil if special_enrollment_period_id.blank?
    @special_enrollment_period = family.special_enrollment_periods.detect {|sep| sep.id == special_enrollment_period_id}
  end

  def plan=(new_plan)
    raise ArgumentError.new("expected Plan") unless new_plan.is_a? Plan
    self.plan_id = new_plan._id
    @plan = new_plan
  end

  def plan
    return @plan if defined? @plan
    @plan = Plan.find(self.plan_id) unless plan_id.blank?
  end

  def broker_agency_profile=(new_broker_agency_profile)
    raise ArgumentError.new("expected BrokerAgencyProfile") unless new_broker_agency_profile.is_a? BrokerAgencyProfile
    self.broker_agency_profile_id = new_broker_agency_profile._id
    @broker_agency_profile = new_broker_agency_profile
  end

  def broker_agency_profile
    return @broker_agency_profile if defined? @broker_agency_profile
    @broker_agency_profile = BrokerAgencyProfile.find(self.broker_agency_profile_id) unless broker_agency_profile_id.blank?
  end

  def has_broker_agency_profile?
    broker_agency_profile_id.present?
  end

  def can_complete_shopping?
    household.family.is_eligible_to_enroll?
  end

  def humanized_dependent_summary
    hbx_enrollment_members.count - 1
  end

  def phone_number
    if plan.present?
      phone = plan.try(:carrier_profile).try(:organization).try(:primary_office_location).try(:phone)
      "#{phone.try(:area_code)}#{phone.try(:number)}"
    else
      ""
    end
  end

  def rebuild_members_by_coverage_household(coverage_household:)
    applicant_ids = hbx_enrollment_members.map(&:applicant_id)
    coverage_household.coverage_household_members.each do |coverage_member|
      next if applicant_ids.include? coverage_member.family_member_id
      enrollment_member = HbxEnrollmentMember.new_from(coverage_household_member: coverage_member)
      enrollment_member.eligibility_date = self.effective_on
      enrollment_member.coverage_start_on = self.effective_on
      self.hbx_enrollment_members << enrollment_member
    end
    self
  end

  def update_current(updates)
    household.hbx_enrollments.where(id: id).update_all(updates)
  end

  def update_hbx_enrollment_members_premium(decorated_plan)
    return if decorated_plan.blank? and hbx_enrollment_members.blank?

    hbx_enrollment_members.each do |member|
      #TODO update applied_aptc_amount error like hbx_enrollment
      member.update_current(applied_aptc_amount: decorated_plan.aptc_amount(member))
    end
  end

  def decorated_elected_plans(coverage_kind)
    benefit_sponsorship = HbxProfile.current_hbx.benefit_sponsorship

    if enrollment_kind == 'special_enrollment' && family.is_under_special_enrollment_period?
      special_enrollment_id = family.current_special_enrollment_periods.first.id
      benefit_coverage_period = benefit_sponsorship.benefit_coverage_period_by_effective_date(family.current_sep.effective_on)
    else
      benefit_coverage_period = benefit_sponsorship.current_benefit_period
    end

    tax_household = household.latest_active_tax_household rescue nil
    elected_plans = benefit_coverage_period.elected_plans_by_enrollment_members(hbx_enrollment_members, coverage_kind, tax_household)
    elected_plans.collect {|plan| UnassistedPlanCostDecorator.new(plan, self)}
  end

  # FIXME: not sure what this is or if it should be removed - Sean
  def inactive_related_hbxs
    hbxs = if employee_role.present?
      household.hbx_enrollments.ne(id: id).select do |hbx|
        hbx.employee_role.present? and hbx.employee_role.employer_profile_id == employee_role.employer_profile_id
      end
    #elsif consumer_role_id.present?
    #  #FIXME when have more than one individual hbx
    #  household.hbx_enrollments.ne(id: id).select do |hbx|
    #    hbx.consumer_role_id.present? and hbx.consumer_role_id == consumer_role_id
    #  end
    else
      []
    end
    household.hbx_enrollments.any_in(id: hbxs.map(&:_id)).update_all(is_active: false)
  end

  def inactive_pre_hbx(pre_hbx_id)
    return if pre_hbx_id.blank?
    pre_hbx = HbxEnrollment.find(pre_hbx_id)
    if self.consumer_role.present? and self.consumer_role_id == pre_hbx.consumer_role_id
      pre_hbx.update_current(is_active: false, changing: false)
    end
  end

  # TODO: Fix this to properly respect mulitiple possible employee roles for the same employer
  #       This should probably be done by comparing the hired_on date with todays date.
  #       Also needs to ignore any that were already terminated before a certain date.
  def self.calculate_start_date_from(employee_role, coverage_household, benefit_group)
    benefit_group.effective_on_for(employee_role.hired_on)
  end

  def self.calculate_effective_on_from(market_kind: 'shop', qle: false, family: nil, employee_role: nil, benefit_group: nil, benefit_sponsorship: HbxProfile.current_hbx.benefit_sponsorship)
    return nil if family.blank?

    case market_kind
    when 'shop'
      if qle and family.is_under_special_enrollment_period?
        family.current_sep.effective_on
      else
        benefit_group.effective_on_for(employee_role.hired_on)
      end
    when 'individual'
      if qle and family.is_under_special_enrollment_period?
        family.current_sep.effective_on
      else
        benefit_sponsorship.current_benefit_period.earliest_effective_date
      end
    end
  rescue => e
    log(e.message, {:severity => "error"})
    nil
  end

  def self.employee_current_benefit_group(employee_role, hbx_enrollment, qle)
    if qle
      qle_effective_date = hbx_enrollment.family.earliest_effective_sep.effective_on
    else
      if employee_role.is_under_open_enrollment?
        open_enrollment_effective_date = employee_role.employer_profile.show_plan_year.start_on
        if open_enrollment_effective_date < employee_role.effective_on
          raise "You're not currently eligible to enroll under this open enrollment period"
        end
      else
        raise "You may not enroll until you're eligible under an enrollment period"
      end
    end

    effective_date = qle_effective_date || open_enrollment_effective_date

    plan_year = employee_role.employer_profile.find_plan_year_by_effective_date(effective_date)
    if plan_year.blank?
      raise "Unable to find employer-sponsored benefits for enrollment year #{effective_date.year}"
    end

    census_employee = employee_role.census_employee
    benefit_group_assignment = plan_year.is_renewing? ? 
        census_employee.renewal_benefit_group_assignment : census_employee.active_benefit_group_assignment

    if benefit_group_assignment.blank? || benefit_group_assignment.plan_year != plan_year
       raise "Unable to find an active or renewing benefit group assignment for enrollment year #{effective_date.year}"
    end

    return benefit_group_assignment.benefit_group, benefit_group_assignment
  end

  def self.new_from(employee_role: nil, coverage_household:, benefit_group: nil, benefit_group_assignment: nil, consumer_role: nil, benefit_package: nil, qle: false, submitted_at: nil)
    enrollment = HbxEnrollment.new

    enrollment.household = coverage_household.household
    enrollment.submitted_at = submitted_at

    case
    when employee_role.present?
      if benefit_group.blank?
        benefit_group, benefit_group_assignment = employee_current_benefit_group(employee_role, enrollment, qle)
      end

      enrollment.kind = "employer_sponsored"
      enrollment.employee_role = employee_role

      if qle && enrollment.family.is_under_special_enrollment_period?
        enrollment.effective_on = enrollment.family.current_sep.effective_on
        enrollment.enrollment_kind = "special_enrollment"
      else
        enrollment.effective_on = calculate_start_date_from(employee_role, coverage_household, benefit_group)
        enrollment.enrollment_kind = "open_enrollment"
      end
  
      enrollment.benefit_group_id = benefit_group.id
      enrollment.benefit_group_assignment_id = benefit_group_assignment.id
    when consumer_role.present?
      enrollment.consumer_role = consumer_role
      enrollment.kind = "individual"
      enrollment.benefit_package_id = benefit_package.try(:id)

      benefit_sponsorship = HbxProfile.current_hbx.benefit_sponsorship
      if qle and enrollment.family.is_under_special_enrollment_period?
        enrollment.effective_on = enrollment.family.current_sep.effective_on
        enrollment.enrollment_kind = "special_enrollment"
      else
        enrollment.effective_on = benefit_sponsorship.current_benefit_period.earliest_effective_date
        enrollment.enrollment_kind = "open_enrollment"
      end
    else
      raise "either employee_role or consumer_role is required"
    end

    coverage_household.coverage_household_members.each do |coverage_member|
      enrollment_member = HbxEnrollmentMember.new_from(coverage_household_member: coverage_member)
      enrollment_member.eligibility_date = enrollment.effective_on
      enrollment_member.coverage_start_on = enrollment.effective_on
      enrollment.hbx_enrollment_members << enrollment_member
    end
    enrollment
  end

  def self.create_from(employee_role: nil, coverage_household:, benefit_group: nil, benefit_group_assignment: nil, consumer_role: nil, benefit_package: nil)
    enrollment = self.new_from(
      employee_role: employee_role,
      coverage_household: coverage_household,
      benefit_group: benefit_group,
      benefit_group_assignment: benefit_group_assignment,
      consumer_role: consumer_role,
      benefit_package: benefit_package
    )
    enrollment.save
    enrollment
  end

  def covered_members_first_names
    hbx_enrollment_members.inject([]) do |names, member|
      names << member.person.first_name
    end
  end

  def status_step
    case
    when coverage_selected?  #submitted
      1
    when transmitted_to_carrier? #transmitted
      2
    when enrolled_contingent? #acknowledged
      3
    when coverage_enrolled? #enrolled
      4
    when coverage_canceled? || coverage_terminated? #canceled/terminated
      5
    end
  end

  def can_terminate_coverage?
    may_terminate_coverage? and effective_on <= TimeKeeper.date_of_record
  end

  def self.find(id)
    id = BSON::ObjectId.from_string(id) if id.is_a? String
    families = Family.where({
      "households.hbx_enrollments._id" => id
    })
    found_value = catch(:found) do
      families.each do |family|
        family.households.each do |household|
          household.hbx_enrollments.each do |enrollment|
            if enrollment.id == id
              throw :found, enrollment
            end
          end
        end
      end
      raise Mongoid::Errors::DocumentNotFound.new(self, id)
    end
    return found_value
  rescue
    log("Can not find hbx_enrollments with id #{id}", {:severity => "error"})
    nil
  end

  def self.find_by_benefit_groups(benefit_groups = [])
    id_list = benefit_groups.collect(&:_id).uniq

    families = Family.where(:"households.hbx_enrollments.benefit_group_id".in => id_list)
    families.inject([]) do |enrollments, family|
      enrollments += family.active_household.hbx_enrollments.where(:benefit_group_id.in => id_list).active.enrolled.to_a
    end
  end

  # def self.find_by_benefit_group_assignments(benefit_group_assignments = [])
  #   id_list = benefit_group_assignments.collect(&:_id)

  #   # families = nil
  #   # if id_list.size == 1
  #   #   families = Family.where(:"households.hbx_enrollments.benefit_group_assignment_id" => id_list.first)
  #   # else
  #   #   families = Family.any_in(:"households.hbx_enrollments.benefit_group_assignment_id" => id_list )
  #   # end

  #   families = Family.where(:"households.hbx_enrollments.benefit_group_assignment_id".in => id_list)

  #   enrollment_list = []
  #   families.each do |family|
  #     family.households.each do |household|
  #       household.hbx_enrollments.active.each do |enrollment|
  #         enrollment_list << enrollment if id_list.include?(enrollment.benefit_group_assignment_id)
  #       end
  #     end
  #   end
  #   enrollment_list
  # end

  # def self.covered(enrollments)
  #   enrollments.select{|e| ENROLLED_STATUSES.include?(e.aasm_state) && e.is_active? }
  # end


  aasm do
    state :shopping, initial: true
    state :coverage_selected
    state :transmitted_to_carrier
    state :coverage_enrolled      # effectuated

    state :coverage_canceled      # coverage never took effect
    state :coverage_terminated    # coverage ended

    state :inactive   # :after_enter inform census_employee

    state :auto_renewing
    state :renewing_waived
    state :renewing_coverage_selected
    state :renewing_transmitted_to_carrier
    state :renewing_coverage_enrolled      # effectuated


    state :unverified
    state :enrolled_contingent

    event :advance_date, :after => :record_transition  do
    end

    event :renew_enrollment do
      transitions from: :shopping, to: :auto_renewing
    end

    event :renew_waived do
      transitions from: :shopping, to: :renewing_waived
    end

    event :select_coverage do
      transitions from: :shopping, to: :coverage_selected, after: :propogate_selection
      transitions from: :auto_renewing, to: :renewing_coverage_selected, after: :propogate_selection
    end

    event :transmit_coverage do
      transitions from: :coverage_selected, to: :transmitted_to_carrier
      transitions from: :auto_renewing, to: :renewing_transmitted_to_carrier
      transitions from: :renewing_coverage_selected, to: :renewing_transmitted_to_carrier
    end

    event :effectuate_coverage do
      transitions from: :transmitted_to_carrier, to: :coverage_enrolled
      transitions from: :renewing_transmitted_to_carrier, to: :renewing_coverage_enrolled
    end

    event :waive_coverage do
      transitions from: [:shopping, :coverage_selected, :auto_renewing, :renewing_coverage_selected], to: :inactive, after: :propogate_waiver
    end

    event :terminate_coverage do
      transitions from: :coverage_selected, to: :coverage_terminated, after: :propogate_terminate
      transitions from: :auto_renewing, to: :coverage_terminated, after: :propogate_terminate
      transitions from: :renewing_coverage_selected, to: :coverage_terminated, after: :propogate_terminate
      transitions from: :enrolled_contingent, to: :coverage_terminated, after: :propogate_terminate
      transitions from: :unverified, to: :coverage_terminated, after: :propogate_terminate
      transitions from: :coverage_enrolled, to: :coverage_terminated, after: :propogate_terminate
    end

    event :move_to_enrolled! do
      transitions from: :coverage_selected, to: :coverage_selected
      transitions from: :unverified, to: :coverage_selected
      transitions from: :enrolled_contingent, to: :coverage_selected
      transitions from: :coverage_selected, to: :coverage_selected
    end

    event :move_to_contingent! do
      transitions from: :shopping, to: :enrolled_contingent
      transitions from: :coverage_selected, to: :enrolled_contingent
      transitions from: :unverified, to: :enrolled_contingent
      transitions from: :enrolled_contingent, to: :enrolled_contingent
      transitions from: :coverage_enrolled, to: :enrolled_contingent
    end

    event :move_to_pending! do
      transitions from: :shopping, to: :unverified
      transitions from: :unverified, to: :unverified
      transitions from: :coverage_selected, to: :unverified
      transitions from: :enrolled_contingent, to: :unverified
      transitions from: :coverage_enrolled, to: :unverified
    end
  end

  def decorated_hbx_enrollment
    if plan.present? && benefit_group.present?
      if benefit_group.is_congress #is_a? BenefitGroupCongress
        PlanCostDecoratorCongress.new(plan, self, benefit_group)
      else
        PlanCostDecorator.new(plan, self, benefit_group, benefit_group.reference_plan)
      end
    elsif plan.present? && consumer_role.present?
      UnassistedPlanCostDecorator.new(plan, self)
    else
      log("#3835 hbx_enrollment without benefit_group and consumer_role. hbx_enrollment_id: #{self.id}, plan: #{plan}", {:severity => "error"})
      OpenStruct.new(:total_premium => 0.00, :total_employer_contribution => 0.00, :total_employee_cost => 0.00)
    end
  end
end
