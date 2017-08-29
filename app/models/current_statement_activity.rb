class CurrentStatementActivity
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :employer_profile_account

  MethodKinds = %w(ach credit_card check)

  field :description, type: String
  field :name, type: String
  field :type, type: String
  field :posting_date, type: Date
  field :amount, type: Money
  field :coverage_month, type: Date

end
