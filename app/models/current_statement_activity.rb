class CurrentStatementActivity
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :employer_profile_account

  MethodKinds = %w(ach credit_card check)

  field :desc, type: String

end
