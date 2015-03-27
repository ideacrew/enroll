class ElectedPlan
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :benefit_group
  belongs_to :plan
  validates_presence_of :plan_id
end
