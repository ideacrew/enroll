class Directory::Premium
  include Mongoid::Document
  field :hbx_id, type: String
  field :hbx_plan_id, type: String
  field :premium_in_cents, type: String
  field :ehb_in_cents, type: String
end
