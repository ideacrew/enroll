# frozen_string_literal: true

class AptcAccumulator
  include Mongoid::Document
  include Mongoid::Timestamps

  field :maximum_amount, type: Money
  field :balance, type: Money

  embeds_many :accumulator_adjustments
  embedded_in :tax_household
end
