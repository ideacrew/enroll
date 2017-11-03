module SponsoredApplications
  class SponsoredApplication
    include Mongoid::Document
    include Mongoid::Timestamps
    include AASM

    # embedded_in :sponsorable, polymorphic: true
    # has_one :sponsor, as: :sponsorable, class_name: "Organization"

    KINDS = [:dc_broker, :mhc_broker, :dc_employer, :mhc_employer, :mhc_conversion_employer, :congress]

    PUBLISHED = %w(published enrolling enrolled active suspended)
    RENEWING  = %w(renewing_draft renewing_published renewing_enrolling renewing_enrolled renewing_publish_pending)
    RENEWING_PUBLISHED_STATE = %w(renewing_published renewing_enrolling renewing_enrolled)

    INELIGIBLE_FOR_EXPORT_STATES = %w(draft publish_pending eligibility_review published_invalid canceled renewing_draft suspended terminated application_ineligible renewing_application_ineligible renewing_canceled conversion_expired)

    OPEN_ENROLLMENT_STATE   = %w(enrolling renewing_enrolling)
    INITIAL_ENROLLING_STATE = %w(publish_pending eligibility_review published published_invalid enrolling enrolled)
    INITIAL_ELIGIBLE_STATE  = %w(published enrolling enrolled)

    # Application type
    field :kind, type: Symbol

    # Application coverage period
    field :effective_term,        type: Range

    # Open enrollment period
    field :open_enrollment_term,  type: Range

    field :terminated_on, type: Date

    # Workflow status
    field :aasm_state, type: String, default: :draft

    embeds_many :benefit_groups, class_name: "SponsoredApplications::BenefitGroup"
    # embeds_many :workflow_state_transitions, as: :transitional

    accepts_nested_attributes_for :benefit_groups
    # accepts_nested_attributes_for :workflow_state_transitions

    validates_presence_of :effective_term, :open_enrollment_term
    validate :date_range_integrity

    after_update :update_employee_benefit_packages


    def effective_on
      effective_term.begin.beginning_of_day
    end

    alias_method :effective_begin_on, :effective_on

    def effective_end_on
      terminated_on.end_of_day || effective_term.end.end_of_day
    end

    def open_enrollment_begin_on
      open_enrollment_term.begin
    end

    def open_enrollment_end_on
      open_enrollment_term.end
    end

    def open_enrollment_completed?
      open_enrollment_term.blank? ? false : (TimeKeeper.date_of_record > open_enrollment_term.end)
    end

    def binder_paid?
      base.binder_paid?
    end

    # Application meets criteria necessary for sponsored group to shop for benefits
    def is_open_enrollment_eligible?

    end


    # Application meets criteria necessary for sponsored group to effectuate selected benefits
    def is_coverage_effective_eligible?
    end


    def benefit_enrollments
      @benefit_enrollments = [] if benefit_groups.size == 0
      return @benefit_enrollments if defined? @benefit_enrollments
      @benefit_enrollments = HbxEnrollment.find_by_benefit_groups(benefit_groups)
    end


  private

    def date_range_integrity
      errors.add(:effective_on, "must precede application end date")  unless effective_term && effective_term.begin < effective_term.end
      errors.add(:effective_on, "must be first day of the month")     unless effective_term && effective_term.begin == effective_term.begin.beginning_of_month
      errors.add(:effective_on, "must be last day of the month")      unless effective_term && effective_term.end == effective_term.end.end_of_month

      errors.add(:open_enrollment_begin_on, "must precede open enrollment end date") unless open_enrollment_term && open_enrollment_term.begin < open_enrollment_term.end
      errors.add(:open_enrollment_end_on,   "must precede effective start date") unless open_enrollment_term && effective_term && open_enrollment_term.end < effective_term.begin
    end


  end
end
