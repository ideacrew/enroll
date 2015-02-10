class PremiumTable
  include Mongoid::Document

  embedded_in :plan

  field :quarter, type: Integer
  field :age, type: Integer
  field :premium, type: Integer, default: 0

end
