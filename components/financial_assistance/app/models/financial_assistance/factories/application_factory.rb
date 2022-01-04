# frozen_string_literal: true

module FinancialAssistance
  module Factories
    # Modify application and sub models data
    class ApplicationFactory
      attr_accessor :source_application, :applicants, :family_members_changed, :family_members_attributes

      APPLICANT_EVIDENCES = [:incomes, :benefits, :deductions].freeze

      def initialize(source_application)
        @source_application = source_application
        @family_members_changed = false
        @new_application = nil
        set_applicants
      end

      def create_application
        return if source_application.is_draft?
        result = ::Operations::Families::ApplyForFinancialAssistance.new.call(family_id: source_application.family_id)
        return if result.failure?
        @family_members_attributes = result.success

        @new_application = build_application
        source_application.active_applicants.each do |applicant|
          new_applicant = build_applicant(applicant)
          member_attributes = @family_members_attributes.select{|member| member[:family_member_id].to_s == new_applicant.family_member_id.to_s}.first
          new_applicant.assign_attributes(member_attributes.except(:family_member_id)) if member_attributes.present?
        end
        @new_application.save!

        update_claimed_as_tax_dependent_by
        sync_family_members_with_applicants
        @new_application
      end

      #duplicate existing application with new object id
      def build_application
        new_app_params = application_params.merge(hash_app_data)
        ::FinancialAssistance::Application.new(new_app_params)
      end

      def update_claimed_as_tax_dependent_by
        claimed_applicants = @new_application.applicants.where(is_claimed_as_tax_dependent: true)
        claimed_applicants.each do |new_appl|
          new_appl.callback_update = true # avoiding callback to enroll in copy feature
          new_matching_applicant = claiming_applicant(new_appl)
          new_appl.update_attributes(claimed_as_tax_dependent_by: new_matching_applicant.id) if new_matching_applicant
        end
      end

      def build_applicant(source_applicant)
        new_applicant = @new_application.applicants.build(applicant_params(source_applicant))
        source_applicant.incomes.each do |source_income|
          new_applicant.incomes << ::FinancialAssistance::Income.dup_instance(source_income)
        end

        source_applicant.benefits.each do |source_benefit|
          new_applicant.benefits << ::FinancialAssistance::Benefit.dup_instance(source_benefit)
        end

        source_applicant.deductions.each do |source_deduction|
          new_applicant.deductions << ::FinancialAssistance::Deduction.dup_instance(source_deduction)
        end
        new_applicant
      end

      #match number of  active family members with active applicants
      # should only sync draft application
      def sync_family_members_with_applicants
        changed_members = detect_applicant_changes(family_members_attributes)
        drop_inactive_applicants(changed_members[:drop_members]) if changed_members[:drop_members].present?
        add_new_applicants(changed_members[:add_members], family_members_attributes) if changed_members[:add_members].present?
      end

      private

      def drop_inactive_applicants(drop_member_ids)
        inactive_applicants = @new_application.applicants.where(:family_member_id.in => drop_member_ids)
        return unless inactive_applicants.present?
        inactive_applicants.each{|inactive_applicant| inactive_applicant.callback_update = true} # avoiding callback to enroll in copy feature
        inactive_applicants.destroy_all
        @family_members_changed = true
      end

      def detect_applicant_changes(family_members)
        # ADDS: family members that are not applicants
        add_members = family_members.reduce([]) do |ids, family_member|
          ids << family_member[:family_member_id] unless @new_application.applicants.where(family_member_id: family_member[:family_member_id]).present?
          ids
        end
        # DROPS: applicants that are not family members
        drop_members = applicants.reduce([]) do |ids, applicant|
          ids << applicant.family_member_id unless family_members.any? { |family_member| family_member[:family_member_id] == applicant.family_member_id }
          ids
        end
        { add_members: add_members, drop_members: drop_members }
      end

      def add_new_applicants(add_members, members_attributes)
        add_members.each do |fm_id|
          member_params = members_attributes.detect { |member_attributes| member_attributes[:family_member_id] == fm_id }
          applicant_params = member_params.except(:relationship)
          applicant = @new_application.applicants.where(person_hbx_id: applicant_params.to_h[:person_hbx_id]).first
          if applicant.present?
            applicant.callback_update = true # avoiding callback to enroll in copy feature
            applicant.update_attributes!(applicant_params)
          else
            applicant = @new_application.applicants.create!(applicant_params)
            @family_members_changed = true
          end
          # Have to update relationship separately because the applicant should already be persisted before doing this.
          if member_params[:relationship].present? && member_params[:relationship] != 'self'
            applicant.callback_update = true # avoiding callback to enroll in copy feature
            applicant.relationship = member_params[:relationship]
            applicant.save!
          end
        end
      end

      def claiming_applicant(new_applicant)
        old_dependent_applicant = @source_application.applicants.where(person_hbx_id: new_applicant.person_hbx_id).first
        return unless old_dependent_applicant&.claimed_as_tax_dependent_by.present?
        # Applicant that claimed the above applicant
        old_tax_applicant = @source_application.applicants.find(old_dependent_applicant.claimed_as_tax_dependent_by)
        return unless old_tax_applicant&.person_hbx_id.present?
        new_applicant.application.applicants.detect{ |applicant| applicant.person_hbx_id == old_tax_applicant.person_hbx_id }
      end

      def application_params
        source_application.attributes.reject {|attr| reject_application_params.include?(attr)}
      end

      def applicant_params(applicant)
        applicant.attributes.reject {|attr| reject_applicant_params.include?(attr)}
      end

      def employer_params(obj)
        {address: address_params(obj),
         phone: phone_params(obj)}
      end

      def address_params(obj)
        obj.employer_address.present? ? obj.employer_address.attributes.except('_id') : nil
      end

      def phone_params(obj)
        obj.employer_phone.present? ? obj.employer_phone.attributes.except('_id') : nil
      end

      def hash_app_data
        {
          aasm_state: 'draft',
          hbx_id: FinancialAssistance::HbxIdGenerator.generate_application_id,
          determination_http_status_code: nil,
          determination_error_message: nil
        }
      end

      def create_relationships
        source_application.relationships.each do |source_relationship|
          next source_relationship if source_relationship.applicant.nil? || source_relationship.relative.nil?
          new_applicant = fetch_matching_applicant(@new_application, source_relationship.applicant)
          new_relative = fetch_matching_applicant(@new_application, source_relationship.relative)
          @new_application.update_or_build_relationship(new_applicant, new_relative, source_relationship.kind)
          @new_application.save!
        end
      end

      # First check is to verify if we can find applicant using person_hbx_id,
      # and if we are not able to find using this then we want to check using
      # a combination of dob, last_name and first_name.
      def fetch_matching_applicant(new_application, source_applicant)
        if source_applicant.person_hbx_id.present?
          applicant = new_application.applicants.where(person_hbx_id: source_applicant.person_hbx_id).first
          return applicant if applicant.present?
        end

        search_params = {dob: source_applicant.dob, last_name: source_applicant.last_name, first_name: source_applicant.first_name}
        search_params[:encrypted_ssn] = source_applicant.encrypted_ssn if source_applicant.ssn.present?
        new_application.applicants.where(search_params).first
      end

      def source_evidence_klass(source_evidence)
        return :benefits if source_evidence.instance_of?(benefit_klass)
        return :incomes if source_evidence.instance_of?(income_klass)
        return :deductions if source_evidence.instance_of?(deduction_klass)
      end

      def reject_application_params
        %w[_id created_at updated_at submitted_at workflow_state_transitions applicants relationships
           determination_http_status_code has_eligibility_response eligibility_response_payload eligibility_request_payload
           predecessor_id renewal_base_year effective_date has_mec_check_response transfer_requested account_transferred
           hbx_id aasm_state assistance_year determination_error_message eligibility_determinations]
      end

      # Do not exclude is_claimed_as_tax_dependent. If you want to exclude is_claimed_as_tax_dependent,
      # also refactor code for method update_claimed_as_tax_dependent_by.
      def reject_applicant_params
        %w[_id created_at updated_at workflow_state_transitions incomes benefits deductions verification_types
           evidences verification_status verification_history eligibility_results
           medicaid_household_size magi_medicaid_category magi_as_percentage_of_fpl magi_medicaid_monthly_income_limit
           magi_medicaid_monthly_household_income is_without_assistance is_ia_eligible is_medicaid_chip_eligible
           is_totally_ineligible is_eligible_for_non_magi_reasons is_non_magi_medicaid_eligible
           csr_percent_as_integer csr_eligibility_kind net_annual_income claimed_as_tax_dependent_by
           eligibility_determination_id]
      end

      def income_klass
        FinancialAssistance::Income
      end

      def benefit_klass
        FinancialAssistance::Benefit
      end

      def deduction_klass
        FinancialAssistance::Deduction
      end

      def set_applicants
        @applicants = source_application.applicants
      end
    end
  end
end
