# frozen_string_literal: true

module FinancialAssistance
  class MemberDetermination
    include Mongoid::Document
    include Mongoid::Timestamps

    embedded_in :applicant, class_name: '::FinancialAssistance::Applicant'
    embeds_many :eligibility_overrides, class_name: '::FinancialAssistance::EligibilityOverride', cascade_callbacks: true

      # The kind of determination.
    field :kind, type: String

      # Whether or not the member is eligible for the kind of determination.
    field :criteria_met, type: Boolean

      # The reasons the member qualifies for the determination.
    field :determination_reasons, type: Array

  end
end