class CurrentStatementActivity
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :employer_profile_account

  field :description, type: String
  field :amount, type: Money
  field :name, type: String
  field :posting_date, type: Date
  field :type, type: String

end
