class BillFile
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :urn, type: String
  field :creation_date, type: Date
end