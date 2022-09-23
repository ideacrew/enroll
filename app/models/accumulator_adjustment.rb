# frozen_string_literal: true

class AccumulatorAdjustment
  include Mongoid::Document
  include Mongoid::Timestamps

  field :enrollment_id, type: BSON::ObjectId
  field :enrolled_member_id, type: BSON::ObjectId
  field :start_on, type: Date
  field :end_on, type: Date
  field :amount, type: Money

  embedded_in :aptc_accumulator
end
