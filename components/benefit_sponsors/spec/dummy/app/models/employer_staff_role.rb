class EmployerStaffRole
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :person
  field :is_owner, type: Boolean, default: true
  field :employer_profile_id, type: BSON::ObjectId
  field :bookmark_url, type: String
  field :is_active, type: Boolean, default: true
  # validates_presence_of :employer_profile_id
  field :aasm_state, type: String, default: 'is_active'
  field :benefit_sponsor_employer_profile_id, type: BSON::ObjectId
end