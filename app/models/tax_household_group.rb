# frozen_string_literal: true

class TaxHouseholdGroup
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :family

  field :source, type: String
  field :application_id, type: BSON::ObjectId
  field :start_on, type: Date
  field :end_on, type: Date
  field :assistance_year, type: Integer
  field :aasm_state, type: String


  embeds_many :tax_households
  embedded_in :family

  index({application_id:  1})

  # Scopes
  scope :by_year, ->(year) { where(start_on: (Date.new(year)..Date.new(year).end_of_year)) }
  scope :active, ->{ where(end_on: nil) }
end
