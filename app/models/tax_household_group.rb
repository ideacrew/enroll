# frozen_string_literal: true

class TaxHouseholdGroup
  include Mongoid::Document
  include Mongoid::Timestamps

  field :source, type: String
  field :application_id, type: BSON::ObjectId
  field :start_on, type: Date
  field :end_on, type: Date
  field :assistance_year, type: Integer
  field :aasm_state, type: String

  embeds_many :tax_households

  index({application_id:  1})
end
