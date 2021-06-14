# frozen_string_literal: true

module Seeds
  # Provides rows which have rows from CSVs that have hashes
  # used to provide seed data.
  class Seed
    include Mongoid::Document
    include Mongoid::Timestamps
    include AASM

    embeds_many :rows, class_name: "Seeds::Row"

    belongs_to :user, class_name: "User"
    field :aasm_state, type: String
    field :filename, type: String
    
    # TODO: Need to update the current template, there might be some duplicated keys
    REQUIRED_CSV_HEADERS = [
      "additional_family_relationships", "age", "age_when_left",
      "amount", "app_ref_number", "applying_for_coverage",
      "aptc_amount", "blind", "case_name", "citizen_status",
      "claimed_by", "csr", "deduction_amount", "deduction_frequency",
      "deduction_from", "deduction_to", "deduction_type", "doc_type",
      "due_date", "eligible_or_enrolled", "environment", "expected",
      "former_foster_care", "frequency", "from", "gender",
      "had_medicaid", "has_disability", "help_paying_for_coverage",
      "in_waiting_period", "incarcerated", "income_amount",
      "income_frequency_kind", "income_from", "income_to",
      "is_primary_applicant?", "minimum_value",
      "native_american", "needs_adl_help",
      "no_ssn_due_to_religious_objection", "pass_or_fail",
      "person_number", "pregnant", "pregnant_last_60_days",
      "program", "relationship_to_primary", "residency_type",
      "state", "tax_filing_status", "to", "type", "username", "who_can_be_covered"
    ].freeze 

    aasm do
      state :draft, initial: true
      state :processing, after_enter: :create_records!
      state :completed
      state :failure

      event :process do
        transitions from: :draft, to: :processing
      end

      event :complete do
        transitions from: :processing, to: :completed
      end
    end

    def create_records!
      row_ids = rows.map(&:id)
      row_ids.map do |row_id|
        SeedRowWorker.perform_async(row_id, self.id)
      end
      complete!
      save
    end
  end
end
