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

  def assisted_income_verified?
    assisted_income_validation == "valid"
  end

  def assisted_mec_verified?
    assisted_mec_validation == "valid"
  end

  def assisted_verification_doument
    applicant.person.consumer_role.assisted_verification_documents.where(assisted_verification_id: self.id).first
  end

  def family
    applicant.family
  end

    # elsif v_type == "Minimal Essential Coverage"
    #   update_attributes(:assisted_mec_validation => "valid", :assisted_mec_reason => update_reason)
    # elsif v_type == "Income"
    #   update_attributes(:assisted_income_validation => "valid", :assisted_income_reason => update_reason)


    #   when "Income"
    #     assisted_income_verified?
    #   when "Minimal Essential Coverage"
    #     assisted_mec_verified?


end
