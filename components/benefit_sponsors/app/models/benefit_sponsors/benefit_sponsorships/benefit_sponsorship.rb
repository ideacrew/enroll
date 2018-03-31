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
module BenefitSponsors
  module BenefitSponsorships
    class BenefitSponsorship
      include Mongoid::Document
      include Mongoid::Timestamps
      # include Concerns::Observable

      field :hbx_id,                  type: String
      field :sponsorship_profile_id,  type: BSON::ObjectId
      field :contact_method,          type: Symbol

      # This sponsorship's workflow status
      field :aasm_state,              type: String, default: :applicant


      belongs_to  :organization,
                  class_name: "BenefitSponsors::Organizations::Organization"

      belongs_to  :benefit_market, counter_cache: true,
                  class_name: "::BenefitMarkets::BenefitMarket"

      belongs_to  :rating_area, counter_cache: true,
                  class_name: "BenefitSponsors::Locations::RatingArea"

      has_many    :service_areas, 
                  class_name: "BenefitSponsors::Locations::ServiceArea"

      has_many    :benefit_applications,
                  class_name: "BenefitSponsors::BenefitApplications::BenefitApplication"

      validates_presence_of :organization, :sponsorship_profile_id, :benefit_market

      validates :contact_method,
        inclusion: { in: ::BenefitMarkets::CONTACT_METHOD_KINDS, message: "%{value} is not a valid contact method" },
        allow_blank: false


      before_create :generate_hbx_id

      index({ aasm_state: 1 })



      def sponsorship_profile=(sponsorship_profile)
        write_attribute(:sponsorship_profile_id, sponsorship_profile._id)
        @sponsorship_profile = sponsorship_profile
      end

      def sponsorship_profile
        return @sponsorship_profile if defined?(@sponsorship_profile)
        @sponsorship_profile = organization.sponsorship_profiles.detect { |sponsorship_profile| sponsorship_profile._id == self.sponsorship_profile_id }
      end


# TODO -- point this to main app census employees
      def census_employees
        BenefitSponsors::CensusMembers::PlanDesignCensusEmployee.find_by_benefit_sponsorship(self)
      end




# TODO move this to Profile
      def sic_code
        sponsorship_profile.sic_code
      end
###

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
          organization = BenefitSponsors::Organizations::PlanDesignOrganization.where("benefit_sponsorships._id" => BSON::ObjectId.from_string(id)).first || BenefitSponsors::Organizations::PlanDesignOrganization.find('5abbe7b6c324df1134000005')
          return if organization.blank?
          organization.benefit_sponsorships.detect{|sponsorship| sponsorship.id.to_s == id.to_s}
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

      def generate_hbx_id
        write_attribute(:hbx_id, BenefitSponsors::Organizations::HbxIdGenerator.generate_benefit_sponsorship_id) if hbx_id.blank?
      end

    end
  end
end
