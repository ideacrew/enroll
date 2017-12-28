module SponsoredBenefits
  module CensusMembers
    class PlanDesignCensusEmployee < CensusMember

      include AASM
      include Sortable
      include Searchable
      include Autocomplete

      EMPLOYMENT_ACTIVE_STATES = %w(eligible employee_role_linked employee_termination_pending newly_designated_eligible newly_designated_linked cobra_eligible cobra_linked cobra_termination_pending)
      EMPLOYMENT_TERMINATED_STATES = %w(employment_terminated cobra_terminated rehired)
      EMPLOYMENT_ACTIVE_ONLY = %w(eligible employee_role_linked employee_termination_pending newly_designated_eligible newly_designated_linked)
      COBRA_STATES = %w(cobra_eligible cobra_linked cobra_terminated cobra_termination_pending)

      field :is_business_owner, type: Boolean, default: false
      field :hired_on, type: Date
      field :aasm_state, type: String
      field :expected_selection, type: String, default: "enroll"

      # field :employer_profile_id, type: BSON::ObjectId
      field :benefit_sponsorship_id, type: BSON::ObjectId

      has_many :census_survivors, class_name: "SponsoredBenefits::CensusMembers::CensusSurvivor"

      embeds_many :census_dependents, as: :census_dependent, class_name: "SponsoredBenefits::CensusMembers::CensusDependent",
      cascade_callbacks: true,
      validate: true

      accepts_nested_attributes_for :census_dependents

      embeds_many :benefit_group_assignments, as: :benefit_assignable,
      cascade_callbacks: true,
      validate: true

      validates_presence_of :dob

      validate :active_census_employee_is_unique
      validate :check_census_dependents_relationship
      validate :no_duplicate_census_dependent_ssns
      validate :check_hired_on_before_dob

      before_save :allow_nil_ssn_updates_dependents

      scope :by_employer_profile_id,    ->(employer_profile_id) { where(employer_profile_id: employer_profile_id) }
      scope :by_sponsorship_id,    ->(benefit_sponsorship_id) { where(benefit_sponsorship_id: benefit_sponsorship_id) }
      scope :by_ssn,    ->(ssn) { where(encrypted_ssn: SponsoredBenefits::CensusMembers::CensusMember.encrypt_ssn(ssn)) }

      scope :active,            ->{ any_in(aasm_state: EMPLOYMENT_ACTIVE_STATES) }
      scope :terminated,        ->{ any_in(aasm_state: EMPLOYMENT_TERMINATED_STATES) }
      scope :by_cobra,          ->{ any_in(aasm_state: COBRA_STATES) }
      scope :active_alone,      ->{ any_in(aasm_state: EMPLOYMENT_ACTIVE_ONLY) }

      def initialize(*args)
        super(*args)
        write_attribute(:employee_relationship, "self")
      end

      def no_duplicate_census_dependent_ssns
        return if ssn.blank?
        dependents_ssn = census_dependents.map(&:ssn).select(&:present?)
        if dependents_ssn.uniq.length != dependents_ssn.length ||
          dependents_ssn.any?{|dep_ssn| dep_ssn==self.ssn}
          errors.add(:base, "SSN's must be unique for each dependent and subscriber")
        end
      end

      def active_census_employee_is_unique
        return if ssn.blank?
        potential_dups = self.class.by_ssn(ssn).by_sponsorship_id(benefit_sponsorship_id)
        if potential_dups.detect { |dup| dup.id != self.id  }
          message = "Employee with this identifying information is already active. "\
          "Update or terminate the active record before adding another."
          errors.add(:base, message)
        end
      end

      def check_census_dependents_relationship
        return true if census_dependents.blank?

        relationships = census_dependents.map(&:employee_relationship)
        if relationships.count{|rs| rs=='spouse' || rs=='domestic_partner'} > 1
          errors.add(:census_dependents, "can't have more than one spouse or domestic partner.")
        end
      end

      def check_hired_on_before_dob
        if hired_on && dob && hired_on <= dob
          errors.add(:hired_on, "date can't be before  date of birth.")
        end
      end

      def allow_nil_ssn_updates_dependents
        census_dependents.each do |cd|
          if cd.ssn.blank?
            cd.unset(:encrypted_ssn)
          end
        end
      end

      def employer_profile=(new_employer_profile)
        raise ArgumentError.new("expected EmployerProfile") unless new_employer_profile.is_a?(SponsoredBenefits::Organizations::PlanDesignProfile)
        self.employer_profile_id = new_employer_profile._id
        @employer_profile = new_employer_profile
      end

      def benefit_application=(benefit_application)
        raise ArgumentError.new("expected Benefit Application") unless benefit_application.is_a?(SponsoredBenefits::BenefitApplications::BenefitApplication)
        self.benefit_application_id = benefit_application._id
        @benefit_application = benefit_application
      end

      def employer_profile
        return @employer_profile if defined? @employer_profile
        @employer_profile = Organizations::PlanDesignProfile.find(self.employer_profile_id) unless self.employer_profile_id.blank?
      end

      def benefit_sponsorship
        SponsoredBenefits::BenefitSponsorships::BenefitSponsorship.find(self.benefit_sponsorship_id)
      end

      def plan_design_proposal
        benefit_sponsorship.benefit_sponsorable.plan_design_proposal
      end

      def benefit_application
        return @benefit_application if defined? @benefit_application
        if employer_profile.present?
          employer_profile.benefit_sponsorships.each do |sponsorship|
            @benefit_application = sponsorship.benefit_applications.detect{|application| application.id  == benefit_application_id}
          end          
        end
        @benefit_application
      end
      
      aasm do
        state :eligible, initial: true
        state :cobra_eligible
        state :newly_designated_eligible
        state :employee_role_linked
        state :cobra_linked
        state :newly_designated_linked
        state :cobra_termination_pending
        state :employee_termination_pending
        state :employment_terminated
        state :cobra_terminated
        state :rehired
      end

      class << self

        def find(id)
          unscoped.where(id: BSON::ObjectId.from_string(id)).first
        end

        def find_by_benefit_sponsor(sponsor)
          unscoped.where(benefit_sponsorship_id: sponsor._id).order_name_asc
        end

        def find_all_by_benefit_group(benefit_group)
          unscoped.where("benefit_group_assignments.benefit_group_id" => benefit_group._id)
        end

        def find_all_by_employer_profile(employer_profile)
          unscoped.where(employer_profile_id: employer_profile._id).order_name_asc
        end

        alias_method :find_by_employer_profile, :find_all_by_employer_profile
      end
    end
  end
end
