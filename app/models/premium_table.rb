class PremiumTable
  include Mongoid::Document

  embedded_in :plan

  field :quarter, type: Integer
  field :insured_age, type: Integer
  field :premium_in_cents, type: Integer, default: 0
  field :ehb_in_cents, type: Integer, default: 0

end
