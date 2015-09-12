class EmployerStaffRole
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :person

  field :is_owner, type: Boolean, default: false
  field :is_active, type: Boolean, default: true
  field :employer_profile_id, type: BSON::ObjectId
  field :bookmark_url, type: String
  validates_presence_of :employer_profile_id

end
