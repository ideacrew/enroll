module SponsoredBenefits
  class BenefitApplications::BenefitApplication
    include Mongoid::Document
    include Mongoid::Timestamps

    # Move generic PlanYear code here

    embedded_in :benefit_sponsorship, class_name: "SponsoredBenefits::BenefitSponsorship"

    ## Refactor States ##
    # SUBMITTED         = %w()
    # INITIAL_ENROLLING = %w(enrolling)
    # RENEWAL_ENROLLING = %w(enrolling)
    # APPROVED          = %w(published enrolled active suspended)

    # deprecate PUBLISHED
    PUBLISHED = %w(published enrolling enrolled active suspended)
    RENEWING  = %w(renewing_draft renewing_published renewing_enrolling renewing_enrolled renewing_publish_pending)
    RENEWING_PUBLISHED_STATE = %w(renewing_published renewing_enrolling renewing_enrolled)

    INELIGIBLE_FOR_EXPORT_STATES = %w(draft publish_pending eligibility_review published_invalid canceled renewing_draft suspended terminated application_ineligible renewing_application_ineligible renewing_canceled conversion_expired)

    OPEN_ENROLLMENT_STATE   = %w(enrolling renewing_enrolling)
    INITIAL_ENROLLING_STATE = %w(publish_pending eligibility_review published published_invalid enrolling enrolled)
    INITIAL_ELIGIBLE_STATE  = %w(published enrolling enrolled)

    TERMINATED = %w(expired terminated)

    ### Deprecate -- use effective_period attribute
    # field :start_on, type: Date
    # field :end_on, type: Date

    ### Deprecate -- use open_enrollment_period attribute
    # field :open_enrollment_start_on, type: Date
    # field :open_enrollment_end_on, type: Date

    # The date range when this application is active
    field :effective_period,        type: Range

    # The date range when members may enroll in benefit products
    field :open_enrollment_period,  type: Range

    # Populate 
    field :terminated_on, type: Date


    ## Override with specific benefit package subclasses
      embeds_many :benefit_packages, class_name: "SponsoredBenefits::BenefitPackages::BenefitPackage", cascade_callbacks: true
      accepts_nested_attributes_for :benefit_packages
    ## 

    validates_presence_of :effective_period, :open_enrollment_period, :message => "is missing"
    validate :open_enrollment_date_checks
    after_update :validate_application_dates

    scope :by_date_range,    ->(begin_on, end_on) { where(:"effective_period.max".gte => begin_on, :"effective_period.max".lte => end_on) }
    scope :terminated_early, ->{ where(:aasm_state.in => TERMINATED, :"effective_period.max".gt => :"terminated_on") }


    def effective_period=(new_effective_period)
      write_attribute(:effective_period, dateify_range(new_effective_period))
    end

    def open_enrollment_period=(new_open_enrollment_period)
      write_attribute(:open_enrollment_period, dateify_range(new_open_enrollment_period))
    end

  private

    # Ensure class type and integrity of date period ranges
    def dateify_range(range_period)

      # Check that end isn't before start. Note: end == start is not trapped as an error
      raise "Range period end date may not preceed begin date" if range_period.begin > range_period.end
      return if range_period.begin.is_a?(Date) && range_period.end.is_a?(Date)

      if range_period.begin.is_a?(Time) || range_period.end.is_a?(Time)
        begin_on  = range_period.begin.to_date
        end_on    = range_period.end.to_date
        begin_on..end_on
      else
        raise "Range period values must be a Date or Time"
      end
    end


    def validate_application_dates
    end


  end
end
