class EmployerStaffRole
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :person

  field :is_owner, type: Boolean
  field :is_active, type: Boolean, default: true
  field :employer_profile_id, type: BSON::ObjectId

  validates_presence_of :employer_profile_id

end
