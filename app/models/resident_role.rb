class ResidentRole
  include Mongoid::Document
  include Mongoid::Timestamps
  include AASM
  
  embedded_in :person


  delegate :hbx_id,           to: :person, allow_nil: true
  delegate :ssn, :ssn=,       to: :person, allow_nil: true
  delegate :dob, :dob=,       to: :person, allow_nil: false
  delegate :gender, :gender=, to: :person, allow_nil: false

  validates_presence_of :dob, :gender

  accepts_nested_attributes_for :person

end
