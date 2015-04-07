class EnrollmentPeriod
  include Mongoid::Document
  include Mongoid::Timestamps
  
  embedded_in :hbx_profile

  field :title, type: String
  field :begin_on, type: Date
  field :end_on, type: Date

  field :affected_markets, type: Array, default: []
  field :affected_products, type: Array, default: []
  field :updated_by, type: String

end
