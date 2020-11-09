# frozen_string_literal: true

module FinancialAssistance
  module Factories
    # Modify application and sub models data
    class ApplicationFactory
      attr_accessor :application, :applicants

      EMBED_MODALS = [:incomes, :benefits, :deductions].freeze

      def initialize(application)
        @application = application
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

        application.applicants.each do |applicant|
          create_applicant(applicant, new_application)
        end

        update_claimed_as_tax_dependent_by(new_application)

        new_application
      end

      def update_claimed_as_tax_dependent_by(new_application)
        claimed_applicants = new_application.applicants.where(:claimed_as_tax_dependent_by.ne => nil)
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

        return new_obj if old_obj.class == deduction_klass

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
        applicants.each do |app|
          app.update_attributes(:is_active => false) unless active_member_ids.include?(app.family_member_id)
        end
        active_applicant_family_member_ids = application.active_applicants.map(&:family_member_id)

        active_member_ids.each do |fm_id|
          next if active_applicant_family_member_ids.include?(fm_id)
          applicant_in_context = applicants.where(family_member_id: fm_id)
          if applicant_in_context.present?
            applicant_in_context.first.update_attributes(is_active: true)
          else
            applicant_params = members_attributes.detect { |member_attributes| member_attributes[:family_member_id] == fm_id }
            applicant = application.applicants.where(person_hbx_id: applicant_params.to_h[:person_hbx_id])
            if applicant.present?
              applicant.update_attributes!(applicant_params)
            else
              applicants.create!(applicant_params)
            end
          end
        end
      end

      private

      def claiming_applicant(new_applicant)
        old_applicant = @application.applicants.find(new_applicant.claimed_as_tax_dependent_by)
        new_applicant.application.applicants.detect{ |applicant| applicant.person_hbx_id == old_applicant.person_hbx_id } if old_applicant&.person_hbx_id
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

      def old_obj_klass(old_obj)
        return :benefits if old_obj.class == benefit_klass
        return :incomes if old_obj.class == income_klass
        return :deductions if old_obj.class == deduction_klass
      end

      def reject_application_params
        %w[_id created_at updated_at submitted_at workflow_state_transitions applicants]
      end

      def reject_applicant_params
        %w[_id created_at updated_at workflow_state_transitions incomes benefits deductions verification_types]
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
