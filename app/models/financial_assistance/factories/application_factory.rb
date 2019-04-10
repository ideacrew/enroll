module FinancialAssistance
  module Factories
    # To modify data and store in db
    class ApplicationFactory
      attr_accessor :application, :family, :applicants

      EMBED_MODALS = [:incomes, :benefits, :deductions].freeze

      def initialize(application)
        @application = application
        @family = application.family
        set_applicants
      end

      def copy_application
        copied_application = build_application
        copied_application.assign_attributes(hash_app_data)
        copied_application.save!
        copied_application.sync_family_members_with_applicants
        copied_application
      end

      def build_application
        hashed_faa = application.attributes.reject{|attr| reject_application_params.include?(attr)}
        @new_application = faa_klass.new(hashed_faa)

        application.applicants.each do |applicant|
          build_applicant(applicant)
        end

        @new_application
      end

      def build_applicant(applicant)
        hashed_app = applicant.attributes.reject{|attr| reject_applicant_params.include?(attr)}
        @new_applicant = @new_application.applicants.new(hashed_app)

        EMBED_MODALS.each do |embed_model|
          applicant.send(embed_model).each do |modal|
            build_embed_models(modal)
          end
        end

        applicant.assisted_verifications.each do |assisted_verification|
          duplicate_av(assisted_verification)
        end
      end

      def build_embed_models(old_obj)
        hashed_obj = old_obj.attributes.reject{|attr| reject_embed_params.include?(attr)}
        new_obj = @new_applicant.send(old_obj_klass(old_obj)).new(hashed_obj)

        return new_obj if old_obj.class == deduction_klass

        assign_employer_contact(new_obj, employer_params(old_obj))
      end

      def employer_params(old_obj)
        {address: hashed_address(old_obj),
         phone: hashed_phone(old_obj)}
      end

      def hashed_address(old_obj)
        old_obj.employer_address.present? ? old_obj.employer_address.attributes.except('_id') : nil
      end

      def hashed_phone(old_obj)
        old_obj.employer_phone.present? ? old_obj.employer_phone.attributes.except('_id') : nil
      end

      def assign_employer_contact(model, params)
        if params[:phone].present?
          model.build_employer_phone
          model.employer_phone.assign_attributes(params[:phone])
        end

        return if params[:address].present?
        model.build_employer_address
        model.employer_address.assign_attributes(params[:address])
      end

      def duplicate_av(assisted_verification)
        hashed_av = assisted_verification.attributes.except('_id', 'assisted_verification_documents', 'verification_response')
        new_av = @new_applicant.assisted_verifications.new(hashed_av)
        assisted_verification.assisted_verification_documents.each do |avd|
          hashed_avd = avd.attributes.except('_id')
          new_av.assisted_verification_documents.new(hashed_avd)
        end
        return if assisted_verification.verification_response.present?
        hashed_vr = assisted_verification.verification_response.attributes.except('_id')
        new_av.verification_response.new(hashed_vr)
      end

      #TODO: applicants for new application
      def sync_family_members_with_applicants
        active_member_ids = family.active_family_members.map(&:id)
        applicants.each do |app|
          app.update_attributes(:is_active => false) unless active_member_ids.include?(app.family_member_id)
        end
        active_applicant_family_member_ids = application.active_applicants.map(&:family_member_id)
        family.active_family_members.each do |fm|
          next unless active_applicant_family_member_ids.include?(fm.id)
          applicant_in_context = applicant_by_fm_id(family_member_id: fm.id)
          if applicant_in_context.present?
            applicant_in_context.first.update_attributes(is_active: bool)
          else
            create_applicant({family_member_id: fm.id})
          end
        end
      end

      def applicant_by_fm_id(fm_id)
        applicants.where(family_member_id: fm_id)
      end

      def activate_applicant(bool)
        applicant_in_context.first.update_attributes(is_active: bool)
      end

      def create_applicant(opts = {})
        applicants.create(opts)
      end

      private

      def hash_app_data
        {
          aasm_state: 'draft',
          submitted_at: nil,
          created_at: nil,
          hbx_id: HbxIdGenerator.generate_application_id,
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
        %w[_id workflow_state_transitions applicants]
      end

      def reject_applicant_params
        %w[_id workflow_state_transitions incomes benefits deductions assisted_verifications]
      end

      def reject_embed_params
        %w[_id employer_address employer_phone]
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


      # def duplicate_income(income)
      #   hashed_income = income.attributes.except('_id', 'employer_address', 'employer_phone')
      #   new_income = @new_applicant.incomes.new(hashed_income)
      #
      #   hashed_address = income.employer_address.attributes.except('_id')
      #   new_income.employer_address.new(hashed_address)
      #
      #   hashed_phone = income.employer_phone.attributes.except('_id')
      #   new_income.employer_phone.new(hashed_phone)
      # end
      #
      # def duplicate_benefit(benefit)
      #   hashed_benefit = benefit.attributes.except('_id', 'employer_address', 'employer_phone')
      #   new_benefit = @new_applicant.benefits.new(hashed_benefit)
      #
      #   hashed_address = income.employer_address.attributes.except('_id')
      #   new_benefit.employer_address.new(hashed_address)
      #
      #   hashed_phone = income.employer_phone.attributes.except('_id')
      #   new_benefit.employer_phone.new(hashed_phone)
      # end
      #
      # def duplicate_deduction(deduction)
      #   hashed_deduction = deduction.attributes.except('_id')
      #   @new_applicant.deductions.new(hashed_deduction)
      # end
    end
  end
end