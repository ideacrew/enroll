class Directory::Carrier < Directory::ApplicationDirectory
  include Mongoid::Document

  field :hbx_id, type: String
  field :hbx_carrier_id, type: String
  field :name, type: String
  field :abbrev, type: String


end
