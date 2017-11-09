class AssistedVerificationDocument < Document

  VLP_DOCUMENTS_VERIF_STATUS = ['not submitted', 'downloaded', 'verified', 'rejected']


  # admin action list for verification process, dropdown for each verification type
  ADMIN_VERIFICATION_ACTIONS = ["Verify", "Return for Deficiency", "Reject Document", "Clear Status", "View History", "Call HUB"]

  # reasons admin can provide when verifying type
  VERIFICATION_REASONS = ["Document in EnrollApp", "Document in DIMS", "SAVE system", "E-Verified in Curam"]

  field :comment, type: String
  field :title, type: String
  field :status, type: String

  scope :uploaded, ->{ where(identifier: {:$exists => true}) }

end
