module SponsoredBenefits
  class CensusMembers::PlanDesignCensusEmployee < CensusMembers::CensusMember
    include AASM
    include Sortable
    include Searchable
    include Autocomplete

    EMPLOYMENT_ACTIVE_STATES = %w(eligible cobra_eligible)

    field :is_business_owner, type: Boolean, default: false
    field :hired_on, type: Date
    field :aasm_state, type: String
    field :expected_selection, type: String, default: "enroll"

    # Employer for this employee
    field :employer_profile_id, type: BSON::ObjectId
    field :benefit_application_id, type: BSON::ObjectId

    has_many :census_survivors, class_name: "SponsoredBenefits::CensusMembers::CensusSurvivor"

    embeds_many :census_dependents, as: :census_dependent, class_name: "SponsoredBenefits::CensusMembers::CensusDependent",
      cascade_callbacks: true,
      validate: true

    validates_presence_of :dob

    validate :active_census_employee_is_unique
    validate :check_census_dependents_relationship
    validate :no_duplicate_census_dependent_ssns
    validate :check_hired_on_before_dob

    before_save :allow_nil_ssn_updates_dependents

    scope :by_employer_profile_id,    ->(employer_profile_id) { where(employer_profile_id: employer_profile_id) }
    scope :by_ssn,    ->(ssn) { where(encrypted_ssn: SponsoredBenefits::CensusMembers::CensusMember.encrypt_ssn(ssn)) }
    scope :active,            ->{ any_in(aasm_state: EMPLOYMENT_ACTIVE_STATES) }


    def initialize(*args)
      super(*args)
      write_attribute(:employee_relationship, "self")
    end

    def no_duplicate_census_dependent_ssns
      dependents_ssn = census_dependents.map(&:ssn).select(&:present?)
      if dependents_ssn.uniq.length != dependents_ssn.length ||
        dependents_ssn.any?{|dep_ssn| dep_ssn==self.ssn}
        errors.add(:base, "SSN's must be unique for each dependent and subscriber")
      end
    end

    def active_census_employee_is_unique
      potential_dups = self.class.by_ssn(ssn).by_employer_profile_id(employer_profile_id)
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
      raise ArgumentError.new("expected EmployerProfile") unless new_employer_profile.is_a?(SponsoredBenefits::BenefitSponsorships::PlanDesignEmployerProfile)
      self.employer_profile_id = new_employer_profile._id
      @employer_profile = new_employer_profile
    end

    def employer_profile
      return @employer_profile if defined? @employer_profile
      @employer_profile = PlanDesignEmployerProfile.find(self.employer_profile_id) unless self.employer_profile_id.blank?
    end

    def benefit_application
      if employer_profile.present?
        sponsorship = employer_profile.benefit_sponsorships.where(:"benefit_applications.id" => benefit_application_id).first
        sponsorship.benefit_applications.detect{|application| application.id  == benefit_application_id}
      end
    end

    class << self
      def find_all_by_employer_profile(employer_profile)
        unscoped.where(employer_profile_id: employer_profile._id).order_name_asc
      end

      alias_method :find_by_employer_profile, :find_all_by_employer_profile
    end

    aasm do
      state :eligible, initial: true
      state :cobra_eligible
    end
  end
end
