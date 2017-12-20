# Manage enrollment-related behavior for a benefit-sponsoring organization (e.g. employers, HBX, etc.)
module SponsoredBenefits
  module BenefitSponsorships
    class BenefitSponsorship
      include Mongoid::Document
      include Mongoid::Timestamps

      embedded_in :benefit_sponsorable, polymorphic: true

      # Obtain this value from site settings
      field :benefit_market, type: Symbol, default: :aca_shop_cca

      ## Sponsor plan year and enrollment period examples
      # DC IVL Initial & Renwal:  Jan - Dec
      # DC/MA SHOP Initial & Renewal: Monthly rolling
      # GIC Initial: Monthly rolling
      # GIC Renewal: July - June

      # Enrollment periods are stored locally to enable sponsor-level exceptions
      # Store separate initial and on-going enrollment renewal values to handle mid-year start situations
      field :initial_enrollment_period, type: Range
      field :annual_enrollment_period_begin_month_of_year, type: Integer

      embeds_one  :geographic_rating_area,  class_name: "SponsoredBenefits::Locations::GeographicRatingArea"
      embeds_many :benefit_applications,    class_name: "SponsoredBenefits::BenefitApplications::BenefitApplication"

      after_create :build_nested_models

      def determine_geographic_rating_area
        build_geographic_rating_area if geographic_rating_area.blank?

        ## Use Zip and County to look up primary office geographic rating area
      end

      def census_employees
        PlanDesignCensusEmployee.find_by_benefit_sponsor(self)
      end

      def build_nested_models
        determine_geographic_rating_area if geographic_rating_area.blank?
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
