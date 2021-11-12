# frozen_string_literal: true

module Eligibilities
  # Use Visitor Development Pattern to access Eligibilities and Eveidences
  # distributed across models
  class Eligibility
    include Mongoid::Document
    include Mongoid::Timestamps

    # embeds_one :enrollment_period

    field :key, type: String
    field :any_eligibility_verifications_outstanding, type: Boolean, default: false

    embeds_many :evidences, class_name: 'Eligibilities::Evidence'

    # scope :eligibility_verifications_outstanding

    def verifications_outstanding
      evidences.reduce([]) do |list, evidence|
        list << evidence unless evidence.is_satisfied
        list
      end
    end
  end
end
