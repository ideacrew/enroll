module SponsoredBenefits
  module BenefitApplications
    class BenefitApplication
      include Mongoid::Document
      include Mongoid::Timestamps

      embedded_in :benefit_sponsorship, class_name: "SponsoredBenefits::BenefitSponsorships::BenefitSponsorship"


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
      # field :terminated_early_on, type: Date

      # field :sponsorable_id, type: String
      # field :rosterable_id, type: String
      # field :broker_id, type: String
      # field :kind, type: :symbol

      # has_one :rosterable, as: :rosterable

      embeds_many :benefit_groups, class_name: "::BenefitGroup", cascade_callbacks: true

      # embeds_many :benefit_packages, as: :benefit_packageable, class_name: "SponsoredBenefits::BenefitPackages::BenefitPackage"
      # accepts_nested_attributes_for :benefit_packages

      # ## Override with specific benefit package subclasses
      #   embeds_many :benefit_packages, class_name: "SponsoredBenefits::BenefitPackages::BenefitPackage", cascade_callbacks: true
      #   accepts_nested_attributes_for :benefit_packages
      # ##

      validates_presence_of :effective_period, :open_enrollment_period, :message => "is missing"
      # validate :validate_application_dates

      validate :open_enrollment_date_checks

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
        effective_range = SponsoredBenefits.tidy_date_range(new_effective_period, :effective_period)
        write_attribute(:effective_period, effective_range) unless effective_range.blank?
      end

      def open_enrollment_period=(new_open_enrollment_period)
        open_enrollment_range = SponsoredBenefits.tidy_date_range(new_open_enrollment_period, :open_enrollment_period)
        write_attribute(:open_enrollment_period, open_enrollment_range) unless open_enrollment_range.blank?
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

      def employer_profile
        benefit_sponsorship.benefit_sponsorable
      end

      def plan_design_census_employees
        CensusMembers::PlanDesignCensusEmployee.where(:benefit_application_id => self.id)
      end

      class << self
        def find(id)
          application = nil
          Organizations::PlanDesignOrganization.where(:"plan_design_profile.benefit_sponsorships.benefit_applications._id" => BSON::ObjectId.from_string(id)).each do |pdo|
            sponsorships = pdo.plan_design_profile.try(:benefit_sponsorships) || []
            sponsorships.each do |sponsorship|
              application = sponsorship.benefit_applications.detect { |benefit_application| benefit_application._id == BSON::ObjectId.from_string(id) }
              break if application.present?
            end
          end
          application
        end
      end



      def open_enrollment_date_checks
        return if effective_period.blank? || effective_period.blank? || open_enrollment_period.blank? || open_enrollment_period.blank?

        if effective_period.begin != effective_period.begin.beginning_of_month
          errors.add(:effective_period, "start date must be first day of the month")
        end

        if effective_period.end != effective_period.end.end_of_month
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
          errors.add(:open_enrollment_period.begin, "can't occur earlier than 60 days before start date")
        end

        if open_enrollment_period.end > (open_enrollment_period.begin + Settings.aca.shop_market.open_enrollment.maximum_length.months.months)
          errors.add(:open_enrollment_period, "open enrollment period is greater than maximum: #{Settings.aca.shop_market.open_enrollment.maximum_length.months} months")
        end

        if (effective_period.begin + Settings.aca.shop_market.initial_application.earliest_start_prior_to_effective_on.months.months) > TimeKeeper.date_of_record
          errors.add(:effective_period, "may not start application before " \
                     "#{(effective_period.begin + Settings.aca.shop_market.initial_application.earliest_start_prior_to_effective_on.months.months).to_date} with #{effective_period.begin} effective date")
        end
      end


    end
  end
end
