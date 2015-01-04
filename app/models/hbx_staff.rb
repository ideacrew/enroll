class HbxStaff
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :person

  field :job_title, type: String, default: ""
  field :department, type: String, default: ""
  field :is_active, type: Boolean, default: true

  def is_active?
    self.is_active
  end


end