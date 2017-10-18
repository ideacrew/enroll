class SuperAdminRole
  include Mongoid::Document
  include SetCurrentUser
  include Mongoid::Timestamps

  embedded_in :person

  field :hbx_profile_id, type: BSON::ObjectId
  field :is_active, type: Boolean, default: true

  accepts_nested_attributes_for :person

  validates_presence_of :hbx_profile_id

  alias_method :is_active?, :is_active
  #subrole is for documentation. should be redundant with permission_id
  field :subrole, type: String, default: ""
  field :permission_id, type: BSON::ObjectId

  def permission
    Permission.find(permission_id)
  end

  def self.find(id)
    return nil if id.blank?
    people = Person.where("sub_admin_role._id" => BSON::ObjectId.from_string(id))
    people.any? ? people[0].sub_admin_role : nil
  end


end
