class Directory::Premium
  include Mongoid::Document

  field :hbx_id, type: String
  field :hbx_plan_id, type: String
  field :age, type: Integer
  field :gender, type: String

  field :amount_in_cents, type: String
  field :ehb_in_cents, type: String

  index({hbx_plan_id: 1})
  index({age: 1, gender: 1})

  def self.lookup(age, gender)
    where({ gender: gender, age: age }).first
  end

end
