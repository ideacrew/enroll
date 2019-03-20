class PremiumTable
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :plan

  field :age, type: Integer
  field :start_on, type: Date
  field :end_on, type: Date
  field :cost, type: Float
end
