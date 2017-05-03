class SicCode
  include Mongoid::Document
  field :code, type: String
  field :industry_group, type: String
  field :major_group, type: String
  field :division, type: String
  field :created_at, type: DateTime, default: ->{ DateTime.now}
  field :updated_at, type: DateTime, default: ->{ DateTime.now}

  validates_presence_of :code, :industry_group, :major_group, :division
end
