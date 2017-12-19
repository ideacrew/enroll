module SponsoredBenefits
  module BenefitApplications
    class BenefitApplication
      include Mongoid::Document
      include Mongoid::Timestamps

      embedded_in :benefit_sponsorship, class_name: "SponsoredBenefits::BenefitSponsorship"

     ### Deprecate -- use effective_period attribute
      # field :start_on, type: Date
      # field :end_on, type: Date

      # The date range when this application is active
      field :effective_period,        type: Range

      ### Deprecate -- use open_enrollment_period attribute
      # field :open_enrollment_start_on, type: Date
      # field :open_enrollment_end_on, type: Date

      # The date range when members may enroll in benefit products
      field :open_enrollment_period,  type: Range

      # Populate when enrollment is terminated prior to open_enrollment_period.end
      field :terminated_early_on, type: Date

      # field :sponsorable_id, type: String
      # field :rosterable_id, type: String
      # field :broker_id, type: String
      # field :kind, type: :symbol

      # has_one :rosterable, as: :rosterable
      embeds_many :benefit_packages, as: :benefit_packageable, class_name: "SponsoredBenefits::BenefitPackages::BenefitPackage"
      # embeds_many :benefit_packages, class_name: "SponsoredBenefits::BenefitPackages::AcaShopCcaBenefitPackage"
      accepts_nested_attributes_for :benefit_packages


      # ## Override with specific benefit package subclasses
      #   embeds_many :benefit_packages, class_name: "SponsoredBenefits::BenefitPackages::BenefitPackage", cascade_callbacks: true
      #   accepts_nested_attributes_for :benefit_packages
      # ##

      validates_presence_of :effective_period, :open_enrollment_period, :message => "is missing"
      validate :validate_application_dates

      scope :by_date_range,    ->(begin_on, end_on) { where(:"effective_period.max".gte => begin_on, :"effective_period.max".lte => end_on) }
      scope :terminated_early, ->{ where(:aasm_state.in => TERMINATED, :"effective_period.max".gt => :"terminated_on") }

      #
      # Are these correct? I don't think you can move an embedded object just by changing an id?
      #
      # def benefit_sponsor=(new_sponsor)
      #   self.sponsorable_id = new_sponsor.id
      # end
      #
      # BrokerAgencyProfile embeds this entire chain - this can't be the way we adjust it
      #
      # def broker=(new_broker)
      #   self.broker_id = new_broker.id
      # end

      def effective_period=(new_effective_period)
        write_attribute(:effective_period, tidy_date_range(new_effective_period))
      end

      def open_enrollment_period=(new_open_enrollment_period)
        write_attribute(:open_enrollment_period, tidy_date_range(new_open_enrollment_period))
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

      class << self
        def find(id)
          application = nil
          Organizations::PlanDesignOrganization.all.each do |pdo|
            sponsorships = pdo.plan_design_profile.try(:benefit_sponsorships) || []
            sponsorships.each do |sponsorship|
              application = sponsorship.benefit_applications.select { |benefit_application| benefit_application._id == BSON::ObjectId.from_string(id) }
            end
          end
          application.first
        end
      end

    private

      # Ensure class type and integrity of date period ranges
      def tidy_date_range(range_period)
        if range_period.class == String
          beginning = range_period.split("..")[0]
          ending = range_period.split("..")[1]
          range_period = Date.strptime(beginning)..Date.strptime(ending)
        end
        # Check that end isn't before start. Note: end == start is not trapped as an error
        errors.add(:effective_period, "Range period end date may not preceed begin date") if range_period.begin > range_period.end
        return range_period if range_period.begin.is_a?(Date) && range_period.end.is_a?(Date)

        if range_period.begin.is_a?(Time) || range_period.end.is_a?(Time)
          begin_on  = range_period.begin.to_date
          end_on    = range_period.end.to_date
          (begin_on..end_on)
        else
          errors.add(:effective_period, "Range period values must be a Date or Time")
        end
        range_period
      end

    end

  end
end
