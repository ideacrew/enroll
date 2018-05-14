# BenefitSponsorship
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
      include AASM

      # Origination of this BenefitSponsorship instance in association
      # with BenefitMarkets::APPLICATION_INTERVAL_KINDS
      #   :self_serve               =>  sponsor independently joined HBX with initial effective date
      #                                 coinciding with standard benefit application interval
      #   :conversion               =>  sponsor transferred to HBX with initial effective date
      #                                 immediately following benefit expiration in prior system
      #   :mid_plan_year_conversion =>  sponsor transferred to HBX with effective date during active plan
      #                                 year, before benefit expiration in prior system, and benefits are
      #                                 carried over to HBX
      #   :reapplied                =>  sponsor, previously active on HBX, voluntarily terminated early
      #                                 and sponsorship continued without interuption, or sponsor returned
      #                                 following time period gap in benefit coverage
      #   :restored                 =>  sponsor, previously active on HBX, was involuntarily terminated
      #                                 and sponsorship resumed according to HBX policy
      ORIGIN_KINDS              = [:self_serve, :conversion, :mid_plan_year_conversion, :reapplied, :restored]

      TERMINATION_KINDS         = [:voluntary, :involuntary]
      TERMINATION_REASON_KINDS  = [:nonpayment, :ineligible, :fraud]


      field :hbx_id,              type: String
      field :profile_id,          type: BSON::ObjectId
      field :contact_method,      type: Symbol, default: :paper_and_electronic

      # Effective begin/end are the date period during which this benefit sponsorship is active
      # Date when initial application coverage starts for this sponsor
      field :effective_begin_on,  type: Date

      # When present, date when all benefit applications are terminated and sponsorship ceases
      field :effective_end_on,    type: Date
      field :termination_kind,    type: Symbol

      # Immutable value indicating origination of this BenefitSponsorship
      field :origin_kind,         type: Symbol, default: :self_serve
      field :registered_on,       type: Date,   default: ->{ TimeKeeper.date_of_record }

      # This sponsorship's workflow status
      field :aasm_state,    type: String, default: :applicant do
        error_on_all_events { |e| raise WMS::MovementError.new(e.message, original_exception: e, model: self) }
      end

      delegate :sic_code,     :sic_code=,     to: :profile, allow_nil: true

      belongs_to  :organization,
                  inverse_of: :benefit_sponorships,
                  counter_cache: true,
                  class_name: "BenefitSponsors::Organizations::Organization"

      has_many    :benefit_applications,
                  class_name: "BenefitSponsors::BenefitApplications::BenefitApplication"

      # has_many    :census_employees,
      #             class_name: "BenefitSponsors::CensusMembers::CensusEmployee"

      has_many    :census_employees

      belongs_to  :benefit_market,
                  counter_cache: true,
                  class_name: "::BenefitMarkets::BenefitMarket"

      belongs_to  :rating_area,
                  counter_cache: true,
                  class_name: "::BenefitMarkets::Locations::RatingArea"

      belongs_to  :service_area,
                  counter_cache: true,
                  class_name: "::BenefitMarkets::Locations::ServiceArea"

      embeds_many :broker_agency_accounts, class_name: "BenefitSponsors::Accounts::BrokerAgencyAccount",
                  validate: true

      embeds_many :general_agency_accounts, class_name: "BenefitSponsors::Accounts::GeneralAgencyAccount",
                  validate: true

      has_many    :documents,
                  inverse_of: :benefit_sponsorship_docs,
                  class_name: "BenefitSponsors::Documents::Document"


      validates_presence_of :organization, :profile_id, :benefit_market

      validates :contact_method,
        inclusion: { in: ::BenefitMarkets::CONTACT_METHOD_KINDS, message: "%{value} is not a valid contact method" },
        allow_blank: false

      validates :origin_kind,
        inclusion: { in: ORIGIN_KINDS, message: "%{value} is not a valid origin kind" },
        allow_blank: false


      before_create :generate_hbx_id

      index({ aasm_state: 1 })

      # Inverse of Profile#benefit_sponsorship
      def profile
        return @profile if defined?(@profile)
        @profile = organization.profiles.detect { |profile| profile._id == self.profile_id }
      end

      def profile=(profile)
        write_attribute(:profile_id, profile._id)
        @profile = profile
      end

      # # TODO: add find_by_benefit_sponsorhip scope to CensusEmployee
      # def census_employees
      #   return @census_employees if is_defined?(@census_employees)
      #   @census_employees = ::CensusEmployee.find_by_benefit_sponsorship(self)
      # end

      # TODO - turn this in to counter_cache -- see: https://gist.github.com/andreychernih/1082313
      def roster_size
        return @roster_size if defined? @roster_size
        @roster_size = census_employees.active.size
      end

      def benefit_sponsor_catalog_for(effective_date)
        return [] if benefit_market.blank?
        benefit_market.benefit_sponsor_catalog_for([], effective_date)
      end


      def employer_profile_to_benefit_sponsor_states_map
        {
          :applicant            => :new,
          :registered           => :initial_application_submitted,
          :conversion_expired   => :initial_application_expired,
        }
      end

      # TODO Refactor (moved from PlanYear)
      # def overlapping_published_plan_years
      #   benefit_sponsorship.benefit_applications.published_benefit_applications_within_date_range(start_on, end_on)
      # end

      # TODO Refactor (moved from PlanYear)
      # def overlapping_published_plan_year?
      #   self.benefit_sponsorship.benefit_applications.published_or_renewing_published.any? do |benefit_application|
      #     benefit_application.effective_period.cover?(self.start_on) && (benefit_application != self)
      #   end
      # end


      def renew_benefit_application
      end



      # Workflow for self service
      aasm do
        state :new, initial: true


        # What is initial state for conversion groups?

        state :initial_application_transferred
        state :initial_application_generated

        state :initial_application_submitted

        state :initial_application_approved
        state :initial_application_canceled
        state :initial_application_expired
        state :initial_application_denied

        state :initial_enrollment_open
        state :initial_enrollment_closed
        state :initial_enrollment_eligible
        state :initial_enrollment_ineligible

        # state :initial_enrollment_binder_paid  => pay_binder event should transition to :initial_enrollment_effectuated
        state :initial_enrollment_effectuated
        state :initial_enrollment_issuer_effectuated  # Sponsor's Group transmitted to Issuer


        state :enrolled                   # Sponsor eligibility to offer benefits is approved, members are enrolled, and coverage is active

        state :suspended                  # Premium payment is 61-90 days past due and Sponsor's benefit coverage has lapsed
        state :terminated                 # Sponsor's ability to offer benefits under this BenefitSponsorship is permanently terminated
        state :ineligible                 # Sponsor is permanently banned from sponsoring benefits due to regulation or policy

        # state :conversion_expired   # Conversion employers who did not establish eligibility in a timely manner


        state :approved
        state :eligible


        state :application_submitted  # Sponsor has submitted valid initial benefit application
        state :application_pending    # Sponsor has submitted valid initial benefit application
        state :application_denied     # Sponsor has submitted valid initial benefit application
        state :application_appealing  # Sponsor has submitted valid initial benefit application
        state :eligible                   # Initial open enrollment is complete and members eligible for coverage


        state :binder_paid, :after_enter => [:notify_binder_paid,:notify_initial_binder_paid]
      # state :lapsed                     # Sponsor benefit coverage has reached end of term without renewal


        event :application_accepted, :after => :record_transition do
          transitions from: [:registered], to: :registered
          transitions from: [:applicant, :ineligible], to: :registered
        end

      end

      def find_benefit_application(id)
        benefit_applications.find(BSON::ObjectId.from_string(id))
      end

      def active_broker_agency_account
        broker_agency_accounts.detect { |baa| baa.is_active }
      end

      class << self
        def find(id)
          organization = BenefitSponsors::Organizations::Organization.where(:"benefit_sponsorships._id" => BSON::ObjectId.from_string(id)).first
          organization.benefit_sponsorships.find(id)
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
