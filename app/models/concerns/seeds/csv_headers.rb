# frozen_string_literal: true

module Seeds
  # Constants that hold CSV Headers which are required for the different seeds.
  # These may be changed/updated overtime as the code is improved.
  module CsvHeaders
    extend ActiveSupport::Concern

    # TODO: Need to update the current template, there might be some duplicated keys
    # TODO: Make this flexiblee for other templates
    INDIVIDUAL_MARKET_SEED = [
      "2_aptc_amount", "2_csr", "2_income_amount", "2_income_frequency",
      "2_income_from", "2_income_to", "2_income_type",
      "Amount", "Frequency", "From", "To", "Type",
      "additional_family_relationships", "age",
      "age_when_left", "app_ref_number", "applying_for_coverage",
      "aptc_amount", "blind", "case_name", "case_notes",
      "citizen_status", "claimed_by", "csr", "date",
      "doc_type", "due_date", "eligible_or_enrolled",
      "employer_coverage_amount", "employer_coverage_minimum_value",
      "employere_coverage_frequency", "former_foster_care", "gender",
      "had_disability", "had_medicaid", "health_program_1",
      "health_program_2", "help_paying_for_coverage",
      "in_waiting_period", "incarcerated", "income_amount",
      "income_frequency", "income_from", "income_to",
      "income_type", "medicaid_state", "native_american",
      "needs_adl_help", "no_ssn_due_to_religious_objection",
      "number_of_children_expected", "person_number", "pregnant",
      "pregnant_last_60_days", "relationship_to_primary",
      "residency_type", "same_as_primary", "scenario_number",
      "tax_filing_status", "username", "who_can_be_covered"
    ].freeze

    REQUIRED_CSV_HEADER_TEMPLATES = {
      individual_market_seed: INDIVIDUAL_MARKET_SEED
    }.freeze
  end
end
