class PremiumTable
  include Mongoid::Document

  field :age, type: Integer
  field :cost, type: Float
  field :start_on, type: Date
  field :end_on, type: Date
end
