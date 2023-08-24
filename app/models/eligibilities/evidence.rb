# frozen_string_literal: true

module Eligibilities
  # A fact - usually obtained from an external service - that contributes to determining
  # whether a subject is eligible to make use of a benefit resource
  class Evidence
    include Mongoid::Document
    include Mongoid::Timestamps
    include AASM
    include ::EventSource::Command
    include Dry::Monads[:result, :do, :try]
    include GlobalID::Identification
    include Eligibilities::Eventable

    DUE_DATE_STATES = %w[review outstanding rejected].freeze

    ADMIN_VERIFICATION_ACTIONS = ["Verify", "Reject", "View History", "Call HUB", "Extend"].freeze

    VERIFY_REASONS = EnrollRegistry[:verification_reasons].item
    REJECT_REASONS = ["Illegible", "Incomplete Doc", "Wrong Type", "Wrong Person", "Expired", "Too old"].freeze

    OUTSTANDING_STATES = ['outstanding', 'rejected'].freeze

    FDSH_EVENTS = {
      :esi_mec => 'events.fdsh.evidences.esi_determination_requested',
      :non_esi_mec => 'events.fdsh.evidences.non_esi_determination_requested',
      :income => 'events.fti.evidences.ifsv_determination_requested',
      :local_mec => "events.iap.mec_check.mec_check_requested"
    }.freeze

    embedded_in :evidenceable, polymorphic: true

    field :key, type: Symbol
    field :title, type: String
    field :description, type: String

    field :received_at, type: DateTime, default: -> { Time.now }
    field :is_satisfied, type: Boolean, default: false
    field :verification_outstanding, type: Boolean, default: false

    field :aasm_state, type: String
    field :update_reason, type: String
    field :due_on, type: Date
    field :external_service, type: String
    field :updated_by, type: String

    embeds_many :verification_histories, class_name: "::Eligibilities::VerificationHistory", cascade_callbacks: true
    embeds_many :request_results, class_name: "::Eligibilities::RequestResult", cascade_callbacks: true
    embeds_many :workflow_state_transitions, class_name: "WorkflowStateTransition", as: :transitional, cascade_callbacks: true

    embeds_many :documents, class_name: "::Document", cascade_callbacks: true, as: :documentable do
      def uploaded
        @target.select(&:identifier)
      end
    end

    accepts_nested_attributes_for :documents, :request_results, :verification_histories, :workflow_state_transitions

    validates_presence_of :key, :is_satisfied, :aasm_state

    scope :by_name, ->(type_name) { where(:key => type_name) }

    def eligibility_event_name
      "events.individual.eligibilities.application.applicant.#{self.key}_evidence_updated"
    end

    def request_determination(action_name, update_reason, updated_by = nil)
      application = self.evidenceable.application
      payload_2 = construct_payload(application)
      payload = Operations::Fdsh::BuildAndValidateApplicationPayload.new.call(application, :income_evidence)

      # {:family_reference=>{:hbx_id=>"169289092467539"}, :assistance_year=>2023, :aptc_effective_date=>Sun, 01 Jan 2023 00:00:00 +0000, :years_to_renew=>nil, :renewal_consent_through_year=>nil, :is_ridp_verified=>true, :is_renewal_authorized=>true, :applicants=>[{:name=>{:first_name=>"John", :middle_name=>nil, :last_name=>"Smith1", :name_sfx=>nil, :name_pfx=>nil}, :identifying_information=>{:has_ssn=>true, :encrypted_ssn=>"Te5Utx5cnO5OhFMjvtYi+IYKvPwBLMBPlQ==\n"}, :demographic=>{:gender=>"Male", :dob=>Tue, 04 Apr 1972, :ethnicity=>[], :race=>nil, :is_veteran_or_active_military=>true, :is_vets_spouse_or_child=>false}, :attestation=>{:is_incarcerated=>false, :is_self_attested_disabled=>false, :is_self_attested_blind=>false, :is_self_attested_long_term_care=>false}, :is_primary_applicant=>true, :native_american_information=>{:indian_tribe_member=>nil, :tribal_name=>nil, :tribal_state=>nil}, :citizenship_immigration_status_information=>{:citizen_status=>"us_citizen", :is_lawful_presence_self_attested=>false, :is_resident_post_092296=>nil}, :is_consumer_role=>false, :is_resident_role=>false, :is_applying_coverage=>true, :five_year_bar_applies=>false, :five_year_bar_met=>false, :qualified_non_citizen=>false, :is_consent_applicant=>false, :vlp_document=>nil, :family_member_reference=>{:family_member_hbx_id=>"100095", :first_name=>"John", :last_name=>"Smith1", :person_hbx_id=>"100095", :is_primary_family_member=>true}, :person_hbx_id=>"100095", :is_required_to_file_taxes=>true, :is_filing_as_head_of_household=>true, :is_joint_tax_filing=>false, :is_claimed_as_tax_dependent=>false, :claimed_as_tax_dependent_by=>nil, :tax_filer_kind=>"tax_filer", :student=>{:is_student=>true, :student_kind=>:full_time, :student_school_kind=>:graduate_school, :student_status_end_on=>Thu, 31 Aug 2023}, :is_refugee=>false, :is_trafficking_victim=>false, :foster_care=>{:is_former_foster_care=>false, :age_left_foster_care=>0, :foster_care_us_state=>nil, :had_medicaid_during_foster_care=>false}, :pregnancy_information=>{:is_pregnant=>false, :is_enrolled_on_medicaid=>false, :is_post_partum_period=>false, :expected_children_count=>0, :pregnancy_due_on=>nil, :pregnancy_end_on=>nil}, :is_primary_caregiver=>true, :is_subject_to_five_year_bar=>false, :is_five_year_bar_met=>false, :is_forty_quarters=>false, :is_ssn_applied=>false, :non_ssn_apply_reason=>nil, :moved_on_or_after_welfare_reformed_law=>false, :is_currently_enrolled_in_health_plan=>false, :has_daily_living_help=>false, :need_help_paying_bills=>false, :has_job_income=>false, :has_self_employment_income=>false, :has_unemployment_income=>false, :has_other_income=>false, :has_deductions=>false, :has_enrolled_health_coverage=>false, :has_eligible_health_coverage=>false, :job_coverage_ended_in_past_3_months=>false, :job_coverage_end_date=>nil, :medicaid_and_chip=>{:not_eligible_in_last_90_days=>false, :denied_on=>nil, :ended_as_change_in_eligibility=>false, :hh_income_or_size_changed=>false, :medicaid_or_chip_coverage_end_date=>nil, :ineligible_due_to_immigration_in_last_5_years=>false, :immigration_status_changed_since_ineligibility=>false}, :other_health_service=>{:has_received=>false, :is_eligible=>false}, :addresses=>[], :emails=>[], :phones=>[], :incomes=>[], :benefits=>[], :deductions=>[], :is_medicare_eligible=>false, :is_self_attested_long_term_care=>false, :has_insurance=>false, :has_state_health_benefit=>false, :had_prior_insurance=>false, :prior_insurance_end_date=>nil, :age_of_applicant=>51, :hours_worked_per_week=>0, :is_temporarily_out_of_state=>false, :is_claimed_as_dependent_by_non_applicant=>false, :benchmark_premium=>{:health_only_lcsp_premiums=>[{:cost=>100.0, :member_identifier=>"100095", :monthly_premium=>100.0}], :health_only_slcsp_premiums=>[{:cost=>200.0, :member_identifier=>"100095", :monthly_premium=>200.0}]}, :is_homeless=>false, :mitc_income=>{:amount=>0, :taxable_interest=>0, :tax_exempt_interest=>0, :taxable_refunds=>0, :alimony=>0, :capital_gain_or_loss=>0, :pensions_and_annuities_taxable_amount=>0, :farm_income_or_loss=>0, :unemployment_compensation=>0, :other_income=>0, :magi_deductions=>0, :adjusted_gross_income=>10078.9, :deductible_part_of_self_employment_tax=>0, :ira_deduction=>0, :student_loan_interest_deduction=>0, :tution_and_fees=>0, :other_magi_eligible_income=>0}, :income_evidence=>{:key=>:income, :title=>"Income", :aasm_state=>"negative_response_received", :description=>nil, :received_at=>Thu, 24 Aug 2023 15:28:45 +0000, :is_satisfied=>false, :verification_outstanding=>true, :update_reason=>nil, :due_on=>Thu, 24 Aug 2023, :external_service=>nil, :updated_by=>nil, :verification_histories=>[], :request_results=>[]}, :esi_evidence=>nil, :non_esi_evidence=>nil, :local_mec_evidence=>nil, :mitc_relationships=>[], :mitc_is_required_to_file_taxes=>true, :mitc_state_resident=>false}], :relationships=>[], :tax_households=>[{:hbx_id=>"10000", :max_aptc=>#<Money fractional:72000 currency:USD>, :yearly_expected_contribution=>#<Money fractional:0 currency:USD>, :effective_on=>Sun, 01 Jan 2023, :determined_on=>Thu, 24 Aug 2023, :is_insurance_assistance_eligible=>"UnDetermined", :annual_tax_household_income=>0.0, :tax_household_members=>[]}], :us_state=>"ME", :hbx_id=>"830293", :oe_start_on=>Sun, 01 Jan 2023, :submitted_at=>Sat, 24 Jun 2023 15:28:44 +0000, :notice_options=>{:send_eligibility_notices=>true, :send_open_enrollment_notices=>false, :paper_notification=>true}, :mitc_households=>[{:household_id=>"1", :people=>[{:person_id=>"100095"}]}], :mitc_tax_returns=>[{:filers=>[], :dependents=>[]}]}

      # return hub_call_negative_response_received(application) if payload.failure? && admin_hub_call_payload_generation_failure_conditions_met?(application)
      headers = self.key == :local_mec ? { payload_type: 'application', key: 'local_mec_check' } : { correlation_id: application.id }

      request_event = event(FDSH_EVENTS[self.key], attributes: payload.to_h, headers: headers)
      binding.irb
      return false unless request_event.success?
      response = request_event.value!.publish

      if response
        add_verification_history(action_name, update_reason, updated_by)
        self.save
      end
      response
    end

    def add_verification_history(action, update_reason, updated_by)
      self.verification_histories.build(action: action, update_reason: update_reason, updated_by: updated_by)
    end

    def construct_payload(application)
      cv3_application = FinancialAssistance::Operations::Applications::Transformers::ApplicationTo::Cv3Application.new.call(application).value!
      # AcaEntities::MagiMedicaid::Operations::InitializeApplication.new.call(cv3_application).value!
    end

    def admin_hub_call_payload_generation_failure_conditions_met?(application)
      # Relation to income_evidences?

      # Add var to FinancialAssistanceRegistry
      outstanding_csr_codes = ['csr_02', 'csr_04', 'csr_05', 'csr_06']
      application.eligibility_determinations.any? { |ed| ed.max_aptc > 0 || valid_csr_codes.include?(ed.csr_eligibility_kind) }
    end

    def hub_call_negative_response_received(application)
      binding.irb
    end

    def extend_due_on(period = 30.days, updated_by = nil)
      self.due_on = verif_due_date + period
      add_verification_history('extend_due_date', "Extended due date to #{due_on.strftime('%m/%d/%Y')}", updated_by)
      self.save
    end

    def auto_extend_due_on(period = 30.days, updated_by = nil)
      current = verif_due_date
      self.due_on = current + period
      add_verification_history('auto_extend_due_date', "Auto extended due date from #{current.strftime('%m/%d/%Y')} to #{due_on.strftime('%m/%d/%Y')}", updated_by)
      self.save
    end

    def verif_due_date
      due_on || evidenceable.schedule_verification_due_on
    end

    # bypasses regular guards for changing the date
    def change_due_on!(new_date)
      self.due_on = new_date
    end

    def can_be_extended?
      return false unless type_unverified?
      extensions = verification_histories.where(action: "auto_extend_due_date")
      return true unless extensions.any?
      #  want this limitation on due date extensions to reset anytime an evidence no longer requires a due date
      # (is moved to 'verified' or 'attested' state) so that an individual can benefit from the extension again in the future.
      auto_extend_time = extensions.last&.created_at
      return true unless auto_extend_time
      workflow_state_transitions.where(:to_state.in => ['verified', 'attested'], :created_at.gt => auto_extend_time).any?
    end

    # rubocop:disable Metrics/CyclomaticComplexity
    def has_determination_response?
      return false if pending?
      return true  if outstanding? || verified?

      if review?
        transitions = workflow_state_transitions.where(:to_state => 'review').order("transition_at DESC")

        from_pending = transitions.detect{|transition| transition.from_state == 'pending'}
        if from_pending
          return true if request_results.where(:created_at.gte => from_pending.transition_at).present?
          return false
        end

        from_outstanding = transitions.detect{|transition| transition.from_state == 'outstanding'}
        return true if from_outstanding
      end

      if attested?
        request_history = verification_histories.where(:action.in => ['application_determined', 'call_hub']).last

        if request_history
          return true if request_results.where(:created_at.gte => request_history.created_at).present?
          return false
        end
      end

      request_results.present? ? true : false
    end
    # rubocop:enable Metrics/CyclomaticComplexity

    PENDING = [:pending, :attested].freeze
    OUTSTANDING = [:outstanding, :review, :errored].freeze
    CLOSED = [:denied, :closed, :expired].freeze
    aasm do
      state :attested, initial: true
      state :pending
      state :review
      state :outstanding
      state :verified
      state :unverified
      state :negative_response_received

      state :determined
      state :expired
      state :denied
      state :errored
      state :closed
      state :corrected
      state :rejected

      event :attest, :after => [:record_transition] do
        transitions from: :pending, to: :attested
        transitions from: :attested, to: :attested
        transitions from: :review, to: :attested
        transitions from: :outstanding, to: :attested
        transitions from: :rejected, to: :attested
        transitions from: :unverified, to: :attested
        transitions from: :negative_response_received, to: :attested
        transitions from: :attested, to: :attested
      end

      event :move_to_rejected, :after => [:record_transition] do
        transitions from: :pending, to: :rejected
        transitions from: :review, to: :rejected
        transitions from: :attested, to: :rejected
        transitions from: :verified, to: :rejected
        transitions from: :outstanding, to: :rejected
        transitions from: :unverified, to: :rejected
        transitions from: :negative_response_received, to: :rejected
        transitions from: :rejected, to: :rejected
      end

      event :negative_response_received, :after => [:record_transition] do
        transitions from: :pending, to: :negative_response_received
        transitions from: :attested, to: :negative_response_received
        transitions from: :verified, to: :negative_response_received
        transitions from: :review, to: :negative_response_received
        transitions from: :outstanding, to: :negative_response_received
        transitions from: :rejected, to: :negative_response_received
        transitions from: :unverified, to: :negative_response_received
        transitions from: :negative_response_received, to: :negative_response_received
      end

      event :move_to_unverified, :after => [:record_transition] do
        transitions from: :pending, to: :unverified
        transitions from: :attested, to: :unverified
        transitions from: :review, to: :unverified
        transitions from: :outstanding, to: :unverified
        transitions from: :verified, to: :unverified
        transitions from: :unverified, to: :unverified
        transitions from: :rejected, to: :unverified
        transitions from: :negative_response_received, to: :unverified
      end

      event :move_to_outstanding, :after => [:record_transition] do
        transitions from: :pending, to: :outstanding
        transitions from: :negative_response_received, to: :outstanding
        transitions from: :outstanding, to: :outstanding
        transitions from: :review, to: :outstanding
        transitions from: :attested, to: :outstanding
        transitions from: :verified, to: :outstanding
        transitions from: :unverified, to: :outstanding
        transitions from: :rejected, to: :outstanding
      end

      event :move_to_verified, :after => [:record_transition] do
        transitions from: :pending, to: :verified
        transitions from: :verified, to: :verified
        transitions from: :review, to: :verified
        transitions from: :attested, to: :verified
        transitions from: :outstanding, to: :verified
        transitions from: :unverified, to: :verified
        transitions from: :negative_response_received, to: :verified
        transitions from: :rejected, to: :verified
      end

      event :move_to_review, :after => [:record_transition] do
        transitions from: :pending, to: :review
        transitions from: :negative_response_received, to: :review
        transitions from: :review, to: :review
        transitions from: :outstanding, to: :review
        transitions from: :attested, to: :review
        transitions from: :verified, to: :review
        transitions from: :rejected, to: :review
        transitions from: :unverified, to: :review
      end

      event :move_to_pending, :after => [:record_transition] do
        transitions from: :attested, to: :pending
        transitions from: :pending, to: :pending
        transitions from: :review, to: :pending
        transitions from: :outstanding, to: :pending
        transitions from: :verified, to: :pending
        transitions from: :rejected, to: :pending
        transitions from: :unverified, to: :pending
        transitions from: :negative_response_received, to: :pending
      end

      event :determined, :after => [:record_transition] do
        transitions from: :requested, to: :determined
        transitions from: :review_required, to: :determined
        transitions from: :corrected, to: :determined
      end

      event :expired, :after => [:record_transition] do
        transitions from: :requested, to: :expired
      end

      event :denied, :after => [:record_transition] do
        transitions from: :requested, to: :denied
      end

      event :errored, :after => [:record_transition] do
        transitions from: :requested, to: :errored
        transitions from: :errored, to: :errored
        transitions from: :corrected, to: :errored
      end

      event :corrected, :after => [:record_transition] do
        transitions from: :errored, to: :corrected
      end

      event :closed, :after => [:record_transition] do
        transitions from: :pending, to: :closed
        transitions from: :requested, to: :closed
        transitions from: :review_required, to: :closed
        transitions from: :expired, to: :closed
        transitions from: :denied, to: :closed
        transitions from: :errored, to: :closed
        transitions from: :closed, to: :closed
      end
    end

    def record_transition
      self.workflow_state_transitions << WorkflowStateTransition.new(
        from_state: aasm.from_state,
        to_state: aasm.to_state
      )
    end

    def type_unverified?
      !type_verified?
    end

    def type_verified?
      ["verified", "attested"].include? aasm_state
    end

    def is_type_outstanding?
      aasm_state == "outstanding"
    end

    def clone_embedded_documents(new_evidence)
      clone_verification_histories(new_evidence)
      clone_request_results(new_evidence)
      clone_workflow_state_transitions(new_evidence)
      clone_documents(new_evidence)
    end

    private

    def clone_verification_histories(new_evidence)
      verification_histories.each do |verification|
        verification_attrs = verification.attributes.deep_symbolize_keys.slice(:action, :modifier, :update_reason, :updated_by, :is_satisfied, :verification_outstanding, :due_on, :aasm_state, :date_of_action)
        new_evidence.verification_histories.build(verification_attrs)
      end
    end

    def clone_request_results(new_evidence)
      request_results.each do |request_result|
        request_result_attrs = request_result.attributes.deep_symbolize_keys.slice(:result, :source, :source_transaction_id, :code, :code_description, :raw_payload, :date_of_action)
        new_evidence.request_results.build(request_result_attrs)
      end
    end

    def clone_workflow_state_transitions(new_evidence)
      workflow_state_transitions.each do |wfst|
        wfst_attrs = wfst.attributes.deep_symbolize_keys.slice(:event, :from_state, :to_state, :transition_at, :reason, :comment, :user_id)
        new_evidence.workflow_state_transitions.build(wfst_attrs)
      end
    end

    def clone_documents(new_evidence)
      documents.each do |document|
        document_attrs = document.attributes.deep_symbolize_keys.slice(:title, :creator, :subject, :description, :publisher, :contributor, :date, :type, :format,
                                                                       :identifier, :source, :language, :relation, :coverage, :rights, :tags, :size, :doc_identifier)
        new_evidence.documents.build(document_attrs)
      end
    end
  end
end
