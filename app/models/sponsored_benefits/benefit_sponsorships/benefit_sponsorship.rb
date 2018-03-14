# Manage enrollment-related behavior for a benefit-sponsoring organization (e.g. employers, congress, HBX, etc.)
# The model design assumes a once annual enrollment period and effective date.  For scenarios where there's a once-yearly
# open enrollment, new sponsors may join mid-year for initial enrollment, subsequently renewing on-schedule in following
# cycles.  Scenarios where enollments are conducted on a rolling monthly basis are also supported.

# Organzations may embed many BenefitSponsorships.  Significant changes result in new BenefitSponsorship,
# such as the following supported scenarios:
# - Benefit Sponsor (employer) voluntarily terminates and later returns after some elapsed period
# - Benefit Sponsor is involuntarily terminated (such as for non-payment) and later becomes eligible
# - Existing Benefit Sponsor changes effective date

# Referencing a new BenefitSponsorship helps ensure integrity on subclassed and associated data models and
# enables history tracking as part of the models structure
module SponsoredBenefits
  module BenefitSponsorships
    class BenefitSponsorship
      include Mongoid::Document
      include Mongoid::Timestamps
      # include Concerns::Observable

      belongs_to  :organization,
                  class_name: "SponsoredBenefits::Organizations::Organization"

      # This sponsorship's workflow status
      field :site_id,                 type: String
      field :initial_effective_date,  type: Date
      field :sponsorship_profile_id,  type: BSON::ObjectId

      field :contact_method_kind,     type: Symbol
      field :aasm_state,              type: String, default: :applicant


      belongs_to  :rating_area,
                  class_name: "SponsoredBenefits::Locations::RatingArea"

      has_many    :service_areas,
                  class_name: "SponsoredBenefits::Locations::ServiceArea"

      belongs_to  :benefit_market, counter_cache: true,
                  class_name: "SponsoredBenefits::BenefitMarkets::BenefitMarket"

      has_many    :benefit_applications,
                  class_name: "SponsoredBenefits::BenefitApplications::BenefitApplication"

      validates_presence_of :benefit_market, :sponsorship_profile_id

      after_create :build_nested_models

# TODO move this to concern
      def sic_code
        sponsorship_profile.sic_code
      end
###
      def sponsorship_profile=(sponsorship_profile)
        write_attribute(:sponsorship_profile_id, sponsorship_profile._id)
        @sponsorship_profile = sponsorship_profile
      end

      def sponsorship_profile
        return @sponsorship_profile if defined?(@sponsorship_profile)
        @sponsorship_profile = organization.sponsorship_profiles.detect { |sponsorship_profile| sponsorship_profile._id == self.sponsorship_profile_id }
      end

      def census_employees
        SponsoredBenefits::CensusMembers::PlanDesignCensusEmployee.find_by_benefit_sponsor(self)
      end

      def initial_enrollment_period=(new_initial_enrollment_period)
        initial_enrollment_range = SponsoredBenefits.tidy_date_range(new_initial_enrollment_period, :initial_enrollment_period)
        write_attribute(:initial_enrollment_period, initial_enrollment_range) if initial_enrollment_range.present?
      end

      def initial_enrollment_period_to_s
        date_start = initial_enrollment_period.begin
        date_end = initial_enrollment_period.end
        "#{date_start.strftime('%B')} #{date_start.day.ordinalize} #{date_start.strftime('%Y')}  -  #{date_end.strftime('%B')} #{date_end.day.ordinalize} #{date_end.strftime('%Y')}"
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
          organization = SponsoredBenefits::Organizations::PlanDesignOrganization.where("plan_design_proposals.profile.benefit_sponsorships._id" => BSON::ObjectId.from_string(id)).first
          return if organization.blank?
          proposal = organization.plan_design_proposals.where("profile.benefit_sponsorships._id" => BSON::ObjectId.from_string(id)).first
          proposal.profile.benefit_sponsorships.detect{|sponsorship| sponsorship.id.to_s == id.to_s}
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

      private

      def build_nested_models
        # build_inbox if inbox.nil?
      end

      def save_inbox
        welcome_subject = "Welcome to #{Settings.site.short_name}"
        welcome_body = "#{Settings.site.short_name} is the #{Settings.aca.state_name}'s on-line marketplace to shop, compare, and select health insurance that meets your employee's health needs and budget."
        @inbox.save
        @inbox.messages.create(subject: welcome_subject, body: welcome_body)
      end


    end
  end
end
