class HbxStaffRole
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :person

  field :hbx_profile_id, type: BSON::ObjectId
  field :job_title, type: String, default: ""
  field :department, type: String, default: ""
  field :is_active, type: Boolean, default: true

  validates_presence_of :hbx_profile_id

  # belongs_to Hbx
  def hbx_profile=(new_hbx_profile)
    raise ArgumentError.new("expected EmployerProfile") unless new_hbx_profile.is_a? EmployerProfile
    self.hbx_profile_id = new_hbx_profile._id
    @hbx_profile = new_hbx_profile
  end

  def hbx_profile
    return @hbx_profile if defined? @hbx_profile
    @hbx_profile = EmployerProfile.find(self.hbx_profile_id)
  end



  def is_active?
    self.is_active
  end
end
