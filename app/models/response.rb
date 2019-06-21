class Response
  include Mongoid::Document

  field :name, type: String
  field :operator, type: String
  field :value, type: Date
  field :value_2, type: Date

  field :result, type: Symbol
end
