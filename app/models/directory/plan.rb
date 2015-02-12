class Directory::Plan
  include Mongoid::Document

  field :hbx_id, type: String
  field :hbx_plan_id, type: String
  field :hbx_carrier_id, type: String
  field :hios_id, type: String
  field :active_period, type: Range
  field :name, type: String
  field :abbrev, type: String
  field :type, type: String
  field :metal_level, type: String
  field :doc_url, type: String


end
