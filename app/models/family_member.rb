class FamilyMember
  include Mongoid::Document
  include SetCurrentUser
  include Mongoid::Timestamps
  include MongoidSupport::AssociationProxies
  include ApplicationHelper

  embedded_in :family

  # Responsible for updating eligibility when family member is created/updated
  after_create :family_member_created
  after_update :family_member_updated, if: :is_active_changed?

  # Person responsible for this family
  field :is_primary_applicant, type: Boolean, default: false

  # Person is applying for coverage
  field :is_coverage_applicant, type: Boolean, default: true

  # Person who authorizes auto-renewal eligibility check
  field :is_consent_applicant, type: Boolean, default: false

  field :is_active, type: Boolean, default: true

  field :person_id, type: BSON::ObjectId
  field :broker_role_id, type: BSON::ObjectId

  # Immediately preceding family where this person was a member
  field :former_family_id, type: BSON::ObjectId

  validate :no_duplicate_family_members

  scope :active, ->{ where(is_active: true).where(:created_at.ne => nil) }
  scope :by_primary_member_role, ->{ where(:is_active => true).where(:is_primary_applicant => true) }
  embeds_many :hbx_enrollment_exemptions
  accepts_nested_attributes_for :hbx_enrollment_exemptions

  embeds_many :comments, cascade_callbacks: true
  accepts_nested_attributes_for :comments, reject_if: proc { |attribs| attribs['content'].blank? }, allow_destroy: true

  delegate :id, to: :family, prefix: true

  delegate :hbx_id, to: :person, allow_nil: true
  delegate :first_name, to: :person, allow_nil: true
  delegate :last_name, to: :person, allow_nil: true
  delegate :middle_name, to: :person, allow_nil: true
  delegate :full_name, to: :person, allow_nil: true
  delegate :name_pfx, to: :person, allow_nil: true
  delegate :name_sfx, to: :person, allow_nil: true
  delegate :date_of_birth, to: :person, allow_nil: true
  delegate :dob, to: :person, allow_nil: true
  delegate :ssn, to: :person, allow_nil: true
  delegate :no_ssn, to: :person, allow_nil: true
  delegate :gender, to: :person, allow_nil: true
  # consumer fields
  delegate :race, to: :person, allow_nil: true
  delegate :ethnicity, to: :person, allow_nil: true
  delegate :language_code, to: :person, allow_nil: true
  delegate :is_tobacco_user, to: :person, allow_nil: true
  delegate :is_incarcerated, to: :person, allow_nil: true
  delegate :tribal_id, to: :person, allow_nil: true
  delegate :is_disabled, to: :person, allow_nil: true
  delegate :citizen_status, to: :person, allow_nil: true
  delegate :indian_tribe_member, to: :person, allow_nil: true
  delegate :naturalized_citizen, to: :person, allow_nil: true
  delegate :eligible_immigration_status, to: :person, allow_nil: true
  delegate :is_dc_resident?, to: :person, allow_nil: true
  delegate :ivl_coverage_selected, to: :person
  delegate :is_applying_coverage, to: :person, allow_nil: true

  validates_presence_of :person_id, :is_primary_applicant, :is_coverage_applicant

  associated_with_one :person, :person_id, "Person"

  def former_family=(new_former_family)
    raise ArgumentError.new("expected Family") unless new_former_family.is_a?(Family)
    self.former_family_id = new_former_family._id
    @former_family = new_former_family
  end

  def former_family
    return @former_family if defined? @former_family
    @former_family = Family.find(former_family_id) unless former_family_id.blank?
  end

  def parent
    raise "undefined parent family" unless family
    self.family
  end

  def households
    # TODO parent.households.coverage_households.where()
  end

  def aptc_benchmark_amount(enrollment)
    date = enrollment.effective_on
    benefit_sponsorship = HbxProfile.current_hbx.benefit_sponsorship
    benefit_coverage_period = benefit_sponsorship.benefit_coverage_periods.detect {|bcp| bcp.contains?(date)}
    # slcsp is a product
    slcsp = benefit_coverage_period.second_lowest_cost_silver_plan
    ehb = slcsp.ehb
    product = product_factory.new({product_id: slcsp.id})
    cost = product.cost_for(date, person.age_on(date))
    round_down_float_two_decimals(cost * ehb)
  end

  def broker=(new_broker)
    return unless new_broker.is_a? BrokerRole
    self.broker_role_id = new_broker._id
  end

  def broker
    BrokerRole.find(self.broker_role_id) unless self.broker_role_id.blank?
  end

  def is_primary_applicant?
    self.is_primary_applicant
  end

  def is_consent_applicant?
    self.is_consent_applicant
  end

  def is_coverage_applicant?
    self.is_coverage_applicant
  end

  def age_on(date)
    age = date.year - dob.year
    if date.month < dob.month || (date.month == dob.month && date.day < dob.day)
      age - 1
    else
      age
    end
  end

  def is_active?
    self.is_active
  end

  def primary_relationship
    if is_primary_applicant?
      "self"
    else
      family.primary_applicant_person.find_relationship_with(person) unless family.primary_applicant_person.blank? || person.blank?
    end
  end

  def relationship
    primary_relationship
  end

  def reactivate!(relationship)
    family.primary_applicant_person.ensure_relationship_with(person, relationship)
    family.add_family_member(person)
  end

  def update_relationship(relationship)
    return if (primary_relationship == relationship)
    family.remove_family_member(person)
    self.reactivate!(relationship)
    family.save!
  end

  def self.find(family_member_id)
    return [] if family_member_id.nil?
    family = Family.where("family_members._id" => BSON::ObjectId.from_string(family_member_id)).first
    family.family_members.detect { |member| member._id.to_s == family_member_id.to_s } unless family.blank?
  end

  private

  def family_member_created
    deactivate_tax_households
    create_financial_assistance_applicant
  end

  def create_financial_assistance_applicant
    ::Operations::FinancialAssistance::CreateOrUpdateApplicant.new.call({family_member: self, event: :family_member_created}) if ::EnrollRegistry.feature_enabled?(:financial_assistance)
  rescue StandardError => e
    Rails.logger.error {"FAA Engine: Unable to do action Operations::FinancialAssistance::CreateOrUpdateApplicant for family_member with object_id: #{self.id} due to #{e.message}"}
  end

  def family_member_updated
    deactivate_tax_households
    delete_financial_assistance_applicant
    create_financial_assistance_applicant
  end

  def delete_financial_assistance_applicant
    ::Operations::FinancialAssistance::DropApplicant.new.call({family_member: self}) if ::EnrollRegistry.feature_enabled?(:financial_assistance)
  rescue StandardError => e
    Rails.logger.error {"FAA Engine: Unable to do action Operations::FinancialAssistance::DropApplicant for family_member with object_id: #{self.id} due to #{e.message}"}
  end

  def deactivate_tax_households
    return unless family.persisted? && family.active_household.tax_households.present?

    Operations::Households::DeactivateFinancialAssistanceEligibility.new.call(params: {family_id: family.id, date: TimeKeeper.date_of_record})
  rescue StandardError => e
    Rails.logger.error {"Unable to do action Operations::Households::DeactivateFinancialAssistanceEligibility for family_member with object_id: #{self.id} due to #{e.message}"}
  end

  def product_factory
    ::BenefitMarkets::Products::ProductFactory
  end

  def no_duplicate_family_members
    return unless family
    family.family_members.group_by { |appl| appl.person_id }.select { |k, v| v.size > 1 }.each_pair do |k, v|
      errors.add(:family_members, "Duplicate family_members for person: #{k}\n")
    end
  end
end
