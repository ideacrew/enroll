class RenewalPlanMapping
  include Mongoid::Document
  include Mongoid::Timestamps

  field :start_on, type: Date
  field :end_on,   type: Date
  field :renewal_plan_id, type: BSON::ObjectId
  field :is_active, type: Boolean, default: true

  validates_presence_of :start_on, :end_on, :renewal_plan_id

  scope :by_date, ->(new_year) { where({:"start_on".gte => Date.new(new_year, 1, 1), :"end_on".lte => Date.new(new_year, 7, 1)}) }


  def renewal_plan
    Plan.find(renewal_plan_id)
  end

end
