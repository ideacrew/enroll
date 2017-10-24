class FinancialAssistance::AssistedVerification
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :applicant, class_name: "::FinancialAssistance::Applicant"
  embeds_many :assisted_verification_documents, as: :documentable

  VERIFICATION_TYPES = %W(Income MEC)
  VERIFICATION_STATUSES = %W(submitted external_source not_required pending unverified outstanding verified)

  field :status, type: String, default: "submitted"
  field :verification_type, type: String
  field :verification_failed, type: Boolean

  embeds_one :verification_response, class_name:"EventResponse"

  validates :status,
      inclusion: { in: VERIFICATION_STATUSES, message: "%{value} is not a defined verification type" }

  validates :verification_type,
      inclusion: { in: VERIFICATION_TYPES, message: "%{value} is not a defined verification type" }

  scope :income, ->{ where(:"verification_type" => "Income") }
  scope :mec, ->{ where(:"verification_type" => "MEC") }

  def family
    applicant.family
  end
end
