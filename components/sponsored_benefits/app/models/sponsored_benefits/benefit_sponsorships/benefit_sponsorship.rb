# Manage enrollment-related behavior for a benefit-sponsoring organization (e.g. employers, congress, HBX, etc.)
# The model design assumes a once annual enrollment period and effective date.  For scenarios where there's a once-yearly
# open enrollment, new sponsors may join mid-year for initial enrollment, subsequently renewing on-schedule in following
# cycles.  Scenarios where enollments are conducted on a rolling monthly basis are also supported.

# OrganzationProfiles will typically embed many BenefitSponsorships.  A new BenefitSponsorship is in order when
# a significant change occurs, such as the following supported scenarios:
# - Benefit Sponsor (employer) terminates and later returns after some elapsed period
# - Existing Benefit Sponsor changes effective date

# Referencing a new BenefitSponsorship helps ensure integrity on subclassed and associated data models and
# enables history tracking as part of the models structure
module SponsoredBenefits
  module BenefitSponsorships
    class BenefitSponsorship
      include Mongoid::Document
      include Mongoid::Timestamps

      embedded_in :benefit_sponsorable, polymorphic: true

      # Obtain this value from site settings
      field :benefit_market, type: Symbol, default: :aca_shop_cca

      ## Example sponsor enrollment periods
      # DC Individual Market Initial & Renewal:  Jan 1 - Dec 31
      # DC/MA SHOP Market Initial & Renewal: Monthly rolling
      # Congress: Jan 1 - Dec 31
      # GIC Initial: Monthly rolling
      # GIC Renewal: July 1 - June 30
      # Enrollment periods are stored locally to enable sponsor-level exceptions

      # Store separate initial and on-going enrollment renewal values to handle mid-year start situations
      field :initial_enrollment_period, type: Range
      field :annual_enrollment_period_begin_month_of_year, type: Integer
      field :contact_method, type: String

      embeds_many :benefit_applications, class_name: "SponsoredBenefits::BenefitApplications::BenefitApplication"

      validates_presence_of :initial_enrollment_period
      validates :annual_enrollment_period_begin_month_of_year,
        numericality: {only_integer: true},
        inclusion: { in: 1..12 },
        allow_blank: false

      # Prevent changes to immutable fields. Instantiate a new model instead
      # before_validation {
      #     if persisted?
      #       false if initial_enrollment_period.changed? || annual_enrollment_period_begin_month_of_year.changed
      #     end
      #   }

      after_create :build_nested_models

      def census_employees
        PlanDesignCensusEmployee.find_by_benefit_sponsor(self)
      end

      def build_nested_models
        # build_inbox if inbox.nil?
      end

      def save_inbox
        welcome_subject = "Welcome to #{Settings.site.short_name}"
        welcome_body = "#{Settings.site.short_name} is the #{Settings.aca.state_name}'s on-line marketplace to shop, compare, and select health insurance that meets your employee's health needs and budget."
        @inbox.save
        @inbox.messages.create(subject: welcome_subject, body: welcome_body)
      end

      # TODO - turn this in to counter_cache -- see: https://gist.github.com/andreychernih/1082313
      def roster_size
        return @roster_size if defined? @roster_size
        @roster_size = census_employees.active.size
      end

      def earliest_plan_year_start_on_date
        plan_years = (self.plan_years.published_or_renewing_published + self.plan_years.where(:aasm_state.in => ["expired", "terminated"]))
        plan_years.reject!{|py| py.can_be_migrated? }
        plan_year = plan_years.sort_by {|test| test[:start_on]}.first
        if !plan_year.blank?
          plan_year.start_on
        end
      end

      class << self
        def find(id)
          sponsorship = nil
          Organizations::PlanDesignOrganization.all.each do |pdo|
            sponsorships = pdo.plan_design_profile.try(:benefit_sponsorships) || []
            sponsorship = sponsorships.select { |sponsorship| sponsorship._id == BSON::ObjectId.from_string(id)}
          end
          sponsorship.first
        end

        def find_broker_for_sponsorship(id)
          organization = nil
          Organizations::PlanDesignOrganization.all.each do |pdo|
            sponsorships = pdo.plan_design_profile.try(:benefit_sponsorships) || []
            organization = pdo if sponsorships.any? { |sponsorship| sponsorship._id == BSON::ObjectId.from_string(id)}
          end
          organization
        end
      end

    end

  end
end
