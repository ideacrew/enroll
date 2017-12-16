module SponsoredBenefits
  module BenefitApplications
    class AcaShopBenefitApplication
      include Mongoid::Document
      include Mongoid::Timestamps

      PUBLISHED = %w(published enrolling enrolled active suspended)
      RENEWING  = %w(renewing_draft renewing_published renewing_enrolling renewing_enrolled renewing_publish_pending)
      RENEWING_PUBLISHED_STATE = %w(renewing_published renewing_enrolling renewing_enrolled)

      INELIGIBLE_FOR_EXPORT_STATES = %w(draft publish_pending eligibility_review published_invalid canceled renewing_draft suspended terminated application_ineligible renewing_application_ineligible renewing_canceled conversion_expired)

      OPEN_ENROLLMENT_STATE   = %w(enrolling renewing_enrolling)
      INITIAL_ENROLLING_STATE = %w(publish_pending eligibility_review published published_invalid enrolling enrolled)
      INITIAL_ELIGIBLE_STATE  = %w(published enrolling enrolled)

      KINDS = [:dc_broker, :mhc_broker, :dc_employer, :mhc_employer, :mhc_conversion_employer, :congress]

      field :benefit_coverage_period, type: Range

      field :open_enrollment_period,    type: Range

      field :terminated_on, type: Date

      field :sponsorable_id, type: String
      field :rosterable_id, type: String
      field :broker_id, type: String
      field :kind, type: :symbol

      belongs_to :sponsorable, polymorphic: true

      has_one :rosterable, as: :rosterable
      embeds_many :benefit_packages, as: :packageable

      accepts_nested_attributes_for :benefit_packages

      validates_presence_of :benefit_coverage_period, :open_enrollment_period
      validate :date_range_integrity
      validate :open_enrollment_date_checks

      def benefit_sponsor=(new_sponsor)
        self.sponsorable_id = new_sponsor.id
      end

      def broker=(new_broker)
        self.broker_id = new_broker.id
      end

      def effective_on
        benefit_coverage_period.begin.beginning_of_day
      end

      alias_method :effective_begin_on, :effective_on

      def effective_end_on
        terminated_on.end_of_day || benefit_coverage_period.end.end_of_day
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

      def calculate_start_on_dates
        ::PlanYear.calculate_start_on_dates
      end

      private

        def date_range_integrity
          errors.add(:effective_on, "must precede application end date")  unless benefit_coverage_period && benefit_coverage_period.begin < benefit_coverage_period.end
          errors.add(:effective_on, "must be first day of the month")     unless benefit_coverage_period && benefit_coverage_period.begin == benefit_coverage_period.begin.beginning_of_month
          errors.add(:effective_on, "must be last day of the month")      unless benefit_coverage_period && benefit_coverage_period.end == benefit_coverage_period.end.end_of_month

          errors.add(:open_enrollment_begin_on, "must precede open enrollment end date") unless open_enrollment_period && open_enrollment_period.begin < open_enrollment_period.end
          errors.add(:open_enrollment_end_on,   "must precede effective start date") unless open_enrollment_period && benefit_coverage_period && open_enrollment_period.end < benefit_coverage_period.begin
        end
    end
  end
end
