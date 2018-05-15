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
      SOURCE_KINDS              = [:self_serve, :conversion, :mid_plan_year_conversion, :reapplied, :restored]

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
      field :source_kind,         type: Symbol, default: :self_serve
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

      has_many    :census_employees,
                  counter_cache: true,
                  class_name: "BenefitSponsors::CensusMembers::CensusEmployee"

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

      embeds_one :employer_attestation, class_name: "BenefitSponsors::Documents::EmployerAttestation"


      validates_presence_of :organization, :profile_id, :benefit_market, :source_kind

      validates :contact_method,
        inclusion: { in: ::BenefitMarkets::CONTACT_METHOD_KINDS, message: "%{value} is not a valid contact method" },
        allow_blank: false

      validates :source_kind,
        inclusion: { in: SOURCE_KINDS, message: "%{value} is not a valid source kind" },
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

      def roster_size
        return @roster_size if defined? @roster_size
        @roster_size = census_employees.active.size
      end

      def benefit_sponsor_catalog_for(effective_date)
        return [] if benefit_market.blank?
        benefit_market.benefit_sponsor_catalog_for([], effective_date)
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
        state :initial_application_approved # Sponsor's first application is submitted and approved     
        state :initial_enrollment_closed    # Sponsor members have successfully completed open enrollment
        state :initial_enrollment_ineligible       
        state :initial_enrollment_eligible, after_enter: :publish_binder_paid  # Sponsor has paid first premium in-full and authorized to offer benefits
                                        #, :after_enter => [:notify_binder_paid,:notify_initial_binder_paid]
        state :active                   # Sponsor's members are actively enrolled in coverage
        state :suspended                # Premium payment is 61-90 days past due and Sponsor's benefit coverage has lapsed
        state :terminated               # Sponsor's ability to offer benefits under this BenefitSponsorship is permanently terminated
        state :ineligible               # Sponsor is permanently banned from sponsoring benefits due to regulation or policy

        event :approve_initial_application do
          transitions from: :new, to: :initial_application_approved
        end

        event :close_initial_enrollment do 
          transitions from: :initial_application_approved, to: :initial_enrollment_closed
        end

        event :approve_initial_enrollment_eligibility do
          transitions from: :initial_enrollment_closed, to: :initial_enrollment_eligible
          transitions from: :initial_enrollment_ineligible,  to: :initial_enrollment_eligible
        end

        event :deny_initial_enrollment_eligibility do
          transitions from: :initial_enrollment_closed, to: :initial_enrollment_ineligible
          transitions from: :initial_enrollment_eligible,  to: :initial_enrollment_ineligible
        end

        event :pay_binder do
          transitions from: :initial_enrollment_closed, to: :initial_enrollment_eligible
        end

        event :begin_coverage do
          transitions from: :initial_enrollment_eligible, to: :active
        end

        event :revert_to_new do
          transitions from: [:new, :initial_application_approved, :initial_enrollment_closed, :initial_enrollment_eligible, :initial_enrollment_ineligible], to: :new
        end

        event :terminate do 
          transitions from: [:active, :suspended], to: :terminated
        end

        event :suspend do
          transitions from: :active, to: :suspended
        end

        event :unsuspend do 
          transitions from: :suspended, to: :active
        end

        event :reinstate do
          transitions from: :terminated, to: :active
        end

        event :reactivate do
          transitions from: :terminated, to: :initial_application_approved 
        end

        event :ban do
          transitions from: [:active, :suspend, :terminated], to: :ineligible
        end

        event :cancel do
          transitions from: [:initial_application_approved, :initial_enrollment_closed], to: :new
        end
      end

      def publish_binder_paid
        benefit_applications.each do |benefit_application| 
          benefit_application.application_event_subscriber(aasm)
        end
      end

      # BenefitApplication        BenefitSponsorship
      # approved               -> initial_application_approved
      # enrollment_closed      -> initial_enrollment_closed
      # application_ineligible -> initial_enrollment_ineligible
      # application_eligible   -> initial_enrollment_eligible
      # active                 -> active
      def application_event_subscriber(aasm)
        case aasm.to_state
        when :approved
          approve_initial_application! if may_approve_initial_application?
        when :enrollment_closed
          close_initial_enrollment! if may_close_initial_enrollment?
        when :application_ineligible
          deny_initial_enrollment_eligibility! if may_deny_initial_enrollment_eligibility?
        when :active
          begin_coverage! if may_begin_coverage?
        end
      end

      def active_broker_agency_account
        broker_agency_accounts.detect { |baa| baa.is_active }
      end

      private

      def generate_hbx_id
        write_attribute(:hbx_id, BenefitSponsors::Organizations::HbxIdGenerator.generate_benefit_sponsorship_id) if hbx_id.blank?
      end

      def employer_profile_to_benefit_sponsor_states_map
        {
          :applicant            => :new,
          :registered           => :initial_applicant,
          :conversion_expired   => :new,
        }
      end

    end
  end
end
