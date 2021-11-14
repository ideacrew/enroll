# frozen_string_literal: true

module Eligibilities
  # Use Visitor Development Pattern to access Eligibilities and Eveidences
  # distributed across models
  class Eligibility
    include Mongoid::Document
    include Mongoid::Timestamps

    # embeds_one :enrollment_period

    field :key, type: Symbol
    field :title, type: String
    field :description, type: String
    field :is_satisfied, type: Boolean, default: false
    field :has_unsatisfied_evidences, type: Boolean, default: true

    embeds_many :evidences, class_name: 'Eligibilities::Evidence'

    before_save :update_evidence_status

    # scope :eligibility_verifications_outstanding

    def unsatisfied_evidences
      evidences.reduce([]) do |list, evidence|
        list << evidence unless evidence.is_satisfied
        list
      end
    end

    private

    def update_evidence_status
      if unsatisfied_evidences.empty?
        write_attribute(:has_unsatisfied_evidences, false)
      else
        write_attribute(:has_unsatisfied_evidences, true)
      end
    end
  end
end
