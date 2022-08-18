# frozen_string_literal: true

module FinancialAssistance
  class EligibilityDetermination
    require 'autoinc'

    include Mongoid::Document
    include Mongoid::Timestamps
    include Mongoid::Autoinc

    embedded_in :application, class_name: "::FinancialAssistance::Application", inverse_of: :eligibility_determinations

    field :max_aptc, type: Money, default: 0.00

    # DEPRECATED - csr_percent_as_integer is deprecated.
    # CSR determination is a member level determination and exists on model '::FinancialAssistance::Applicant'
    field :csr_percent_as_integer, type: Integer, default: 0  #values in DC: 0, 73, 87, 94

    field :source, type: String
    field :aptc_csr_annual_household_income, type: Money, default: 0.00
    field :aptc_annual_income_limit, type: Money, default: 0.00
    field :csr_annual_income_limit, type: Money, default: 0.00
    field :effective_starting_on, type: Date
    field :effective_ending_on, type: Date
    field :is_eligibility_determined, type: Boolean
    field :hbx_assigned_id, type: Integer
    increments :hbx_assigned_id, seed: 9999

    field :determined_at, type: Date


    scope :eligibility_determination_with_year, ->(year) { where(effective_starting_on: (Date.new(year)..Date.new(year).end_of_year), is_eligibility_determined: true) }
    scope :active_eligibility_determination, ->{ where(effective_ending_on: nil, is_eligibility_determined: true) }

    scope :is_aptc_eligible, -> { where(:max_aptc.gte => 0.00) }
    scope :is_csr_eligible, -> { where(:csr_percent_as_integer.ne => 0) }

    def applicants
      application.applicants.in(eligibility_determination_id: id)
    end

    def aptc_applicants
      applicants.aptc_eligible
    end

    def medicaid_or_chip_applicants
      applicants.medicaid_or_chip_eligible
    end

    # UQHP, is_without_assistance
    def uqhp_applicants
      applicants.uqhp_eligible
    end

    def ineligible_applicants
      applicants.ineligible
    end

    # is_eligible_for_non_magi_reasons, is_non_magi_medicaid_eligible
    def applicants_with_non_magi_reasons
      applicants.eligible_for_non_magi_reasons
    end

    def csr_limited_applicants
      applicants.select(&:is_csr_limited?)
    end

    def is_aptc_eligible?
      BigDecimal((max_aptc || 0).to_s) > 0
    end

    def is_csr_eligible?
      csr_percent_as_integer != 0
    end
  end
end

