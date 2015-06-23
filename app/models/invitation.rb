class Invitation
  include Mongoid::Document
  include Mongoid::Timestamps
  include AASM

  INVITE_TYPES = {
    "census_employee" => "employee_role",
    "broker_role" => "broker_role",
    "employer_profile" => "employer_profile"
  }
  ROLES = INVITE_TYPES.values
  SOURCE_KINDS = INVITE_TYPES.keys

  field :role, type: String
  field :source_id, type: BSON::ObjectId
  field :source_kind, type: String
  field :aasm_state, type: String

  belongs_to :user

  validates_presence_of :role, :allow_blank => false
  validates_presence_of :source_id, :allow_blank => false
  validates :source_kind, :inclusion => { in: SOURCE_KINDS }, :allow_blank => false

  validate :allowed_invite_types

  aasm do
    state :sent, initial: true
    state :claimed

    event :claim do
      transitions from: :sent, to: :claimed, :after => Proc.new { |*args| assign_user!(*args) }
    end
  end

  def claim_invitation!(user_obj)
    self.claim!(:claimed, user_obj)
  end

  def assign_user!(user_obj)
    self.user = user_obj
    self.save!
  end

  def allowed_invite_types
    result_type = INVITE_TYPES[self.source_kind]
    check_role = result_type.blank? ? nil : result_type.downcase
    return if (self.source_kind.blank? || self.role.blank?)
    if result_type != self.role.downcase
      errors.add(:base, "a combination of source #{self.source_kind} and role #{self.role} is invalid")
    end
  end
end
