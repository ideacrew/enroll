class VerificationTypeHistoryElement
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :consumer_role

  field :verification_type, type: String
  field :action, type: String
  field :modifier, type: String
  field :details, type: String
  field :update_reason, type: String
  field :details, type: String

end