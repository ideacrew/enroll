class Invitation
  include Mongoid::Document
  include Mongoid::Timestamps
  include AASM

  INVITE_TYPES = {
    "census_employee" => "employee_role",
    "broker_role" => "broker_role",
    "broker_agency_staff_role" => "broker_agency_staff_role",
    "employer_staff_role" => "employer_staff_role"
  }
  ROLES = INVITE_TYPES.values
  SOURCE_KINDS = INVITE_TYPES.keys

  field :role, type: String
  field :source_id, type: BSON::ObjectId
  field :source_kind, type: String
  field :aasm_state, type: String
  field :invitation_email, type: String

  belongs_to :user

  validates_presence_of :invitation_email, :allow_blank => false
  validates_presence_of :source_id, :allow_blank => false
  validates :source_kind, :inclusion => { in: SOURCE_KINDS }, :allow_blank => false
  validates :role, :inclusion => { in: ROLES }, :allow_blank => false

  validate :allowed_invite_types


  aasm do
    state :sent, initial: true
    state :claimed
    
    event :claim do
      transitions from: :sent, to: :claimed, :after => Proc.new { |*args| process_claim!(*args) }
    end
  end

  def claim_invitation!(user_obj, redirection_obj)
    self.claim!(:claimed, user_obj, redirection_obj)
  end

  def process_claim!(user_obj, redirection_obj)
    self.user = user_obj
    self.save!
    case self.role
    when "employee_role"
      claim_employee_role(user_obj, redirection_obj)
    when "broker_role"
      claim_broker_role(user_obj, redirection_obj)
    when "broker_agency_staff_role"
      claim_broker_agency_staff_role(user_obj, redirection_obj)
    when "employer_staff_role"
      claim_employer_staff_role(user_obj, redirection_obj)
    else
      raise "Unrecognized role: #{self.role}"
    end
  end

  def claim_employer_staff_role(user_obj, redirection_obj)
    employer_staff_role = EmployerStaffRole.find(source_id)
    person = employer_staff_role.person
    user_obj.roles << "employer_staff" unless user_obj.roles.include?("employer_staff")
    user_obj.save!
    person.user = current_user
    person.save!
    redirect_to_employer_profile(employer_staff_role.employer_profile)
  end

  def claim_employee_role(user_obj, redirection_obj)
    census_employee = CensusEmployee.find(source_id)
    redirection_obj.redirect_to_employee_match(census_employee)
  end

  def claim_broker_role(user_obj, redirection_obj)
    b_role = BrokerRole.find(source_id)
    person = b_role.person
    person.user = user_obj
    person.save!
    broker_agency_profile = b_role.broker_agency_profile
    person.broker_agency_staff_roles << ::BrokerAgencyStaffRole.new(:broker_agency_profile => broker_agency_profile)
    person.save!
    user_obj.roles << "broker_agency_staff" unless user_obj.roles.include?("broker_agency_staff")
    user_obj.save!
    redirection_obj.redirect_to_broker_agency_profile(broker_agency_profile)
  end

  def claim_broker_agency_staff_role(user_obj, redirection_obj)
    staff_role = BrokerAgencyStaffRole.find(source_id)
    person = staff_role.person
    person.user = user_obj
    person.save!
    broker_agency_profile = staff_role.broker_agency_profile
    user_obj.roles << "broker_agency_staff" unless user_obj.roles.include?("broker_agency_staff")
    user_obj.save!
    redirection_obj.redirect_to_broker_agency_profile(broker_agency_profile)
  end

  def allowed_invite_types
    result_type = INVITE_TYPES[self.source_kind]
    check_role = result_type.blank? ? nil : result_type.downcase
    return if (self.source_kind.blank? || self.role.blank?)
    if result_type != self.role.downcase
      errors.add(:base, "a combination of source #{self.source_kind} and role #{self.role} is invalid")
    end
  end

  def send_invitation!(invitee_name)
    UserMailer.invitation_email(invitation_email, invitee_name, self).deliver_now
  end

  def self.invite_employee!(census_employee)
    if !census_employee.email_address.blank?
      invitation = self.create(
        :role => "employee_role",
        :source_kind => "census_employee",
        :source_id => census_employee.id,
        :invitation_email => census_employee.email_address
      )
      invitation.send_invitation!(census_employee.full_name)
    end
  end

  def self.invite_broker!(broker_role)
    if !broker_role.email_address.blank?
      invitation = self.create(
        :role => "broker_role",
        :source_kind => "broker_role",
        :source_id => broker_role.id,
        :invitation_email => broker_role.email_address
      )
      invitation.send_invitation!(broker_role.parent.full_name)
    end
  end

  def self.invite_broker_agency_staff!(broker_role)
    if !broker_role.email_address.blank?
      invitation = self.create(
        :role => "broker_agency_staff_role",
        :source_kind => "broker_agency_staff_role",
        :source_id => broker_role.id,
        :invitation_email => broker_role.email_address
      )
      invitation.send_invitation!(broker_role.parent.full_name)
    end
  end

end
