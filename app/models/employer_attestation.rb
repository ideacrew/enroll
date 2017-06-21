class EmployerAttestation
  include Mongoid::Document
  include SetCurrentUser
  include Mongoid::Timestamps

  embedded_in :employer_profile

  STATUS = %w(Unsubmitted Submitted Pending Approved Denied)

  field :status, type: String


  #embeds_one  :employer_profile
  #embeds_many :employer_attestation_document

  validates_presence_of :status
end
