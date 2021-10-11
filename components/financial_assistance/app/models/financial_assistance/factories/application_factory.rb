# frozen_string_literal: true

module FinancialAssistance
  module Factories
    # Modify application and sub models data
    class ApplicationFactory
      attr_accessor :application, :applicants, :family_members_changed

      EMBED_MODALS = [:incomes, :benefits, :deductions].freeze

      def initialize(application)
        @application = application
        @family_members_changed = false
        set_applicants
      end

      #duplicate, modify and match applicants with family members
      def copy_application
        return if application.is_draft?
        copied_application = duplicate
        copied_application.assign_attributes(hash_app_data)
        copied_application.save!
        initialize(copied_application)
        sync_family_members_with_applicants
        copied_application
      end

      #duplicate existing application with new object id
      def duplicate
        new_application = faa_klass.create(application_params)

        application.active_applicants.each do |applicant|
          create_applicant(applicant, new_application)
        end

        create_relationships(new_application, application)
        update_claimed_as_tax_dependent_by(new_application)

        new_application
      end

      def update_claimed_as_tax_dependent_by(new_application)
        claimed_applicants = new_application.applicants.where(is_claimed_as_tax_dependent: true)
        claimed_applicants.each do |new_appl|
          new_matching_applicant = claiming_applicant(new_appl)
          new_appl.update_attributes(claimed_as_tax_dependent_by: new_matching_applicant.id) if new_matching_applicant
        end
      end

      def create_applicant(applicant, new_application)
        new_applicant = new_application.applicants.create(applicant_params(applicant))

        EMBED_MODALS.each do |embed_models|
          applicant.send(embed_models).each do |embed_model|
            create_embed_models(embed_model, new_applicant)
          end
        end
        new_applicant.save!
      end

      #for incomes, benefits and deductions model
      def create_embed_models(old_obj, new_applicant)
        params = old_obj.attributes.reject {|attr| reject_embed_params.include?(attr)}
        new_obj = new_applicant.send(old_obj_klass(old_obj)).create(params)

        return new_obj if old_obj.instance_of?(deduction_klass)

        assign_employer_contact(new_obj, employer_params(old_obj))
        new_obj
      end

      def assign_employer_contact(model, params)
        if params[:phone].present?
          model.build_employer_phone
          model.employer_phone.update_attributes!(params[:phone])
        end

        return unless params[:address].present?
        model.build_employer_address
        model.employer_address.update_attributes!(params[:address])
      end

      #match number of  active family members with active applicants
      # should only sync draft application
      def sync_family_members_with_applicants
        return unless application.is_draft?
        result = ::Operations::Families::ApplyForFinancialAssistance.new.call(family_id: @application.family_id)
        return if result.failure?
        members_attributes = result.success
        active_member_ids = members_attributes.inject([]) do |fm_ids, member_param_hash|
          fm_ids << member_param_hash[:family_member_id]
        end

        if active_member_ids.present?
          inactive_applicants = application.applicants.where(:family_member_id.nin => active_member_ids)
          if inactive_applicants.present?
            inactive_applicants.destroy_all
            @family_members_changed = true
          end
        end

        set_applicants
        active_applicant_family_member_ids = application.active_applicants.map(&:family_member_id)

        active_member_ids.each do |fm_id|
          next if active_applicant_family_member_ids.include?(fm_id)
          applicant_in_context = applicants.where(family_member_id: fm_id)
          if applicant_in_context.present?
            applicant_in_context.first.update_attributes(is_active: true)
          else
            member_params = members_attributes.detect { |member_attributes| member_attributes[:family_member_id] == fm_id }
            applicant_params = member_params.except(:relationship)
            applicant = application.applicants.where(person_hbx_id: applicant_params.to_h[:person_hbx_id]).first
            if applicant.present?
              applicant.update_attributes!(applicant_params)
            else
              applicant = applicants.create!(applicant_params)
              @family_members_changed = true
            end
            # Have to update relationship separately because the applicant should already be persisted before doing this.
            if member_params[:relationship].present? && member_params[:relationship] != 'self'
              applicant.relationship = member_params[:relationship]
              applicant.save!
            end
          end
        end
      end

      private

      def claiming_applicant(new_applicant)
        old_dependent_applicant = @application.applicants.where(person_hbx_id: new_applicant.person_hbx_id).first
        return unless old_dependent_applicant&.claimed_as_tax_dependent_by.present?
        # Applicant that claimed the above applicant
        old_tax_applicant = @application.applicants.find(old_dependent_applicant.claimed_as_tax_dependent_by)
        return unless old_tax_applicant&.person_hbx_id.present?
        new_applicant.application.applicants.detect{ |applicant| applicant.person_hbx_id == old_tax_applicant.person_hbx_id }
      end

      def application_params
        application.attributes.reject {|attr| reject_application_params.include?(attr)}
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

      def create_relationships(new_application, application)
        application.relationships.each do |relationship|
          next relationship if relationship.applicant.nil? || relationship.relative.nil?
          new_applicant = fetch_matching_applicant(new_application, relationship.applicant)
          new_relative = fetch_matching_applicant(new_application, relationship.relative)
          new_application.update_or_build_relationship(new_applicant, new_relative, relationship.kind)
          new_application.save!
        end
        new_application.save!
      end

      # First check is to verify if we can find applicant using person_hbx_id,
      # and if we are not able to find using this then we want to check using
      # a combination of dob, last_name and first_name.
      def fetch_matching_applicant(new_application, old_applicant)
        if old_applicant.person_hbx_id.present?
          applicant = new_application.applicants.where(person_hbx_id: old_applicant.person_hbx_id).first
          return applicant if applicant.present?
        end

        search_params = {dob: old_applicant.dob, last_name: old_applicant.last_name, first_name: old_applicant.first_name}
        search_params[:encrypted_ssn] = old_applicant.encrypted_ssn if old_applicant.ssn.present?
        new_application.applicants.where(search_params).first
      end

      def old_obj_klass(old_obj)
        return :benefits if old_obj.instance_of?(benefit_klass)
        return :incomes if old_obj.instance_of?(income_klass)
        return :deductions if old_obj.instance_of?(deduction_klass)
      end

      def reject_application_params
        %w[_id created_at updated_at submitted_at workflow_state_transitions applicants relationships
           determination_http_status_code has_eligibility_response eligibility_response_payload eligibility_request_payload
           predecessor_id renewal_base_year effective_date has_mec_check_response transfer_requested account_transferred]
      end

      # Do not exclude is_claimed_as_tax_dependent. If you want to exclude is_claimed_as_tax_dependent,
      # also refactor code for method update_claimed_as_tax_dependent_by.
      def reject_applicant_params
        %w[_id created_at updated_at workflow_state_transitions incomes benefits deductions verification_types
           medicaid_household_size magi_medicaid_category magi_as_percentage_of_fpl magi_medicaid_monthly_income_limit
           magi_medicaid_monthly_household_income is_without_assistance is_ia_eligible is_medicaid_chip_eligible
           is_totally_ineligible is_eligible_for_non_magi_reasons is_non_magi_medicaid_eligible
           csr_percent_as_integer csr_eligibility_kind net_annual_income claimed_as_tax_dependent_by]
      end

      def reject_embed_params
        %w[_id created_at updated_at submitted_at employer_address employer_phone]
      end

      def faa_klass
        FinancialAssistance::Application
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
        @applicants = application.applicants
      end
    end
  end
end
