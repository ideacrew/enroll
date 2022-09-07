# frozen_string_literal: true

class TaxHouseholdEnrollment
  include Mongoid::Document
  include Mongoid::Timestamps

  field :source, type: String
  field :application_id, type: BSON::ObjectId
  field :start_on, type: Date
  field :end_on, type: Date
  field :assistance_year, type: Integer
  field :aasm_state, type: String
  field :tax_household_id, type: BSON::ObjectId
  field :enrollment_id, type: BSON::ObjectId
  field :household_benchmark_ehb_premium, type: Money

  embeds_many :tax_household_members_enrollment_members

  index({application_id:  1})
end
