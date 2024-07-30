# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module FinancialAssistance
  module Operations
    module Applications
      # This Operation creates a new application for a given application identifier(BSON ID),
      class Copy
        include Dry::Monads[:do, :result]
        include AddressValidator
        include I18n

        VALID_APPLICATION_STATES = ['submitted', 'determination_response_error', 'determined', 'imported', 'income_verification_extension_required', 'applicants_update_required'].freeze

        # FamilyMembers, Relationships, claimed_as_tax_dependent_by are the things that might need user interaction to update.
        attr_reader :family_members_changed, :relationships_changed, :claiming_applicants_missing

        # @param [Hash] opts The options to generate draft application
        # @option opts [BSON::ObjectId] :application_id (required)
        # @return [Dry::Monads::Result]
        def call(params)
          application                 = yield validate_input_params(params)
          active_fms_applicant_params = yield fetch_active_fms_applicant_params(application)
          _reader                     = yield set_attribute_reader(application, active_fms_applicant_params)
          draft_app                   = yield copy_application(application, active_fms_applicant_params)

          Success(draft_app)
        end

        private

        def validate_input_params(params)
          return Failure({simple_error_message: I18n.t('faa.errors.key_application_id_missing_error')}) unless params.key?(:application_id)
          application = ::FinancialAssistance::Application.where(id: params[:application_id]).first
          return Failure({simple_error_message: I18n.t('faa.errors.unable_to_find_application_error')}) if application.blank?
          return Failure({simple_error_message: I18n.t('faa.errors.given_application_is_not_submitted_error', valid_states: VALID_APPLICATION_STATES)}) unless VALID_APPLICATION_STATES.include?(application.aasm_state)

          Success(application)
        end

        def fetch_active_fms_applicant_params(application)
          ::Operations::Families::ApplyForFinancialAssistance.new.call(family_id: application.family_id)
        end

        def set_attribute_reader(application, active_fms_applicant_params)
          applicant_fm_ids = application.applicants.pluck(:family_member_id)
          active_fm_ids = active_fms_applicant_params.collect { |fm_hash| fm_hash[:family_member_id] }
          @family_members_changed = (applicant_fm_ids - active_fm_ids).present? || (active_fm_ids - applicant_fm_ids).present?
          Success('Attribute reader set.')
        end

        def copy_application(application, active_fms_applicant_params)
          draft_app = build_application(application, active_fms_applicant_params)

          if draft_app.valid?
            draft_app.save!
            Success(draft_app)
          else
            # Log additional information
            simple_error_message = I18n.t('faa.errors.invalid_application')
            detailed_error_message = simple_error_message + " Errors: #{draft_app.errors.full_messages}"
            Failure(simple_error_message: simple_error_message, detailed_error_message: detailed_error_message)
          end
        rescue StandardError => e
          # Log additional information
          simple_error_message = I18n.t('faa.errors.copy_application_error')
          detailed_error_message = simple_error_message + " Error message: #{e.message}"
          Failure(simple_error_message: simple_error_message, detailed_error_message: detailed_error_message)
        end

        def build_application(source_application, active_fms_applicant_params)
          new_app_params = fetch_app_params(source_application)
          new_app = ::FinancialAssistance::Application.new(new_app_params)
          build_application_embeded_documents(source_application, new_app, active_fms_applicant_params)
          update_claimed_as_tax_dependent_by(source_application, new_app)
          new_app
        end

        def update_claimed_as_tax_dependent_by(source_application, new_app)
          claimed_applicants = new_app.applicants.where(is_claimed_as_tax_dependent: true)
          claimed_applicants.each do |new_appl|
            new_appl.callback_update = true # avoiding callback to enroll in copy feature
            new_matching_applicant = claiming_applicant(source_application, new_appl)

            if new_matching_applicant.present?
              new_appl.claimed_as_tax_dependent_by = new_matching_applicant.id
              new_appl.save!
            else
              @claiming_applicants_missing = true
            end
          end
        end

        def claiming_applicant(source_application, new_appl)
          old_dependent_applicant = source_application.applicants.where(person_hbx_id: new_appl.person_hbx_id).first
          return unless old_dependent_applicant&.claimed_as_tax_dependent_by.present?
          # Applicant that claimed the above applicant
          old_tax_applicant = source_application.applicants.find(old_dependent_applicant.claimed_as_tax_dependent_by)
          return unless old_tax_applicant&.person_hbx_id.present?
          new_appl.application.applicants.detect{ |applicant| applicant.person_hbx_id == old_tax_applicant.person_hbx_id }
        end

        def build_application_embeded_documents(source_application, new_app, active_fms_applicant_params)
          build_applicants(source_application, new_app, active_fms_applicant_params)
          build_relationships(source_application, new_app, active_fms_applicant_params)
        end

        def build_relationships(source_application, new_app, active_fms_applicant_params)
          primary = new_app.primary_applicant
          dependent_applicant_params = active_fms_applicant_params.reject { |fm_applicant_params| fm_applicant_params[:is_primary_applicant] }

          @relationships_changed = dependent_applicant_params.any? do |fm_applicant_params|
            dependent_applicant = source_application.applicants.where(family_member_id: fm_applicant_params[:family_member_id]).first
            relation_kind = source_application.relationships.where(applicant_id: dependent_applicant&.id, relative_id: source_application&.primary_applicant&.id).first&.kind
            fm_applicant_params[:relationship] != relation_kind
          end

          if @relationships_changed
            create_relationships_bw_primary_and_dependents(new_app, active_fms_applicant_params, primary)
          else
            copy_relationships_from_source_app(source_application, new_app)
          end
        end

        def copy_relationships_from_source_app(source_application, new_app)
          source_application.relationships.each do |source_relationship|
            next source_relationship if source_relationship.applicant.nil? || source_relationship.relative.nil?
            new_applicant = fetch_matching_applicant(new_app, source_relationship.applicant)
            new_relative = fetch_matching_applicant(new_app, source_relationship.relative)
            new_app.build_new_relationship(new_applicant, source_relationship.kind, new_relative)
          end
        end

        def create_relationships_bw_primary_and_dependents(new_app, active_fms_applicant_params, primary)
          active_fms_applicant_params.each do |fm_applicant_params|
            next fm_applicant_params if fm_applicant_params[:is_primary_applicant]
            new_appl = new_app.applicants.where(family_member_id: fm_applicant_params[:family_member_id]).first
            new_app.build_new_relationship(new_appl, fm_applicant_params[:relationship], primary)
            inverse_rel_kind = ::FinancialAssistance::Relationship::INVERSE_MAP[fm_applicant_params[:relationship]]
            next fm_applicant_params if inverse_rel_kind.blank?
            new_app.build_new_relationship(primary, inverse_rel_kind, new_appl)
          end
        end

        # First check is to verify if we can find applicant using family_member_id,
        # and then checks using person_hbx_id,
        # and if we are not able to find using these then we want to check using
        # a combination of dob, last_name and first_name.
        def fetch_matching_applicant(new_application, source_applicant)
          if source_applicant.family_member_id.present?
            applicant = new_application.applicants.where(family_member_id: source_applicant.family_member_id).first
            return applicant if applicant.present?
          end

          if source_applicant.person_hbx_id.present?
            applicant = new_application.applicants.where(person_hbx_id: source_applicant.person_hbx_id).first
            return applicant if applicant.present?
          end

          search_params = { dob: source_applicant.dob, last_name: source_applicant.last_name, first_name: source_applicant.first_name }
          search_params[:encrypted_ssn] = source_applicant.encrypted_ssn if source_applicant.ssn.present?
          new_application.applicants.where(search_params).first
        end

        def build_applicants(source_application, new_app, active_fms_applicant_params)
          active_fms_applicant_params.each do |fm_params|
            source_applicant = source_application.applicants.where(family_member_id: fm_params[:family_member_id]).first
            new_appli_params = fetch_applicant_params(source_applicant, fm_params)
            new_applicant = new_app.build_new_applicant(new_appli_params)

            new_applicant.callback_update = true # avoiding callback to enroll in copy feature
            build_applicant_embeded_documents(source_applicant, new_applicant, active_fms_applicant_params)
          end
        end

        def build_applicant_embeded_documents(source_applicant, new_applicant, active_fms_applicant_params)
          active_fm_applicant_params = active_fms_applicant_params.detect{ |fm_params| fm_params[:family_member_id] == new_applicant.family_member_id }
          build_new_addresses(new_applicant, active_fm_applicant_params)
          build_new_phones(new_applicant, active_fm_applicant_params)
          build_new_emails(new_applicant, active_fm_applicant_params)
          return if source_applicant.blank?

          source_applicant.clone_evidences(new_applicant)
          build_new_incomes(source_applicant, new_applicant)
          build_new_deductions(source_applicant, new_applicant)
          build_new_benefits(source_applicant, new_applicant)
        end

        def build_new_emails(new_applicant, active_fm_applicant_params)
          active_fm_applicant_params[:emails].each do |email_params|
            new_applicant.build_new_email(email_params.slice(:kind, :address))
          end
        end

        def build_new_phones(new_applicant, active_fm_applicant_params)
          active_fm_applicant_params[:phones].each do |phone_params|
            new_applicant.build_new_phone(phone_params.slice(:kind, :country_code, :area_code, :number, :extension, :primary, :full_phone_number))
          end
        end

        def build_new_addresses(new_applicant, active_fm_applicant_params)
          active_fm_applicant_params[:addresses].each do |address_params|
            new_applicant.build_new_address(address_params.slice(:kind, :address_1, :address_2, :address_3, :city, :county, :state, :zip, :country_name, :quadrant))
          end
        end

        def build_new_benefits(source_applicant, new_applicant)
          source_applicant.benefits.each do |benefit|
            benefit.duplicate_instance(new_applicant)
          end
        end

        def build_new_deductions(source_applicant, new_applicant)
          source_applicant.deductions.each do |deduction|
            deduction.duplicate_instance(new_applicant)
          end
        end

        def build_new_incomes(source_applicant, new_applicant)
          source_applicant.incomes.each do |income|
            income.duplicate_instance(new_applicant)
          end
        end

        def fetch_app_params(source_application)
          source_app_params = source_application.attributes.deep_symbolize_keys.slice(:family_id, :is_renewal_authorized, :years_to_renew, :is_requesting_voter_registration_application_in_mail,
                                                                                      :benchmark_product_id, :medicaid_terms, :medicaid_insurance_collection_terms, :report_change_terms,
                                                                                      :parent_living_out_of_home_terms, :attestation_terms, :submission_terms, :request_full_determination)

          source_app_params.merge({ aasm_state: 'draft',
                                    hbx_id: FinancialAssistance::HbxIdGenerator.generate_application_id })
        end

        def fetch_applicant_params(source_applicant, fm_applicant_params)
          applicant_mergable_params = fm_applicant_params.except(:addresses, :phones, :emails, :relationship)
          return applicant_mergable_params if source_applicant.nil?
          is_living_in_state = has_in_state_home_addresses?(source_applicant.addresses.map(&:attributes).each_with_index.to_h.invert)
          applicant_mergable_params.merge!(is_living_in_state: is_living_in_state)

          source_appli_params = source_applicant.attributes.slice(:name_pfx, :first_name, :middle_name, :last_name, :name_sfx, :encrypted_ssn, :gender, :dob, :is_primary_applicant,
                                                                  :is_incarcerated, :is_disabled, :ethnicity, :race, :indian_tribe_member, :tribal_id, :language_code, :no_dc_address,
                                                                  :is_homeless, :is_temporarily_out_of_state, :immigration_doc_statuses, :no_ssn, :citizen_status, :is_consumer_role,
                                                                  :is_resident_role, :same_with_primary, :is_applying_coverage, :is_tobacco_user, :vlp_document_id, :vlp_subject,
                                                                  :alien_number, :i94_number, :visa_number, :passport_number, :sevis_id, :naturalization_number, :receipt_number,
                                                                  :citizenship_number, :card_number, :country_of_citizenship, :vlp_description, :expiration_date, :issuing_country,
                                                                  :is_consent_applicant, :is_tobacco_user, :assisted_income_validation, :assisted_mec_validation, :assisted_income_reason,
                                                                  :assisted_mec_reason, :aasm_state, :person_hbx_id, :ext_app_id, :family_member_id, :has_fixed_address, :is_living_in_state,
                                                                  :is_required_to_file_taxes, :is_filing_as_head_of_household, :tax_filer_kind, :is_joint_tax_filing, :is_claimed_as_tax_dependent,
                                                                  :is_physically_disabled, :has_income_verification_response, :has_mec_verification_response, :is_medicare_eligible, :is_student,
                                                                  :student_kind, :student_school_kind, :student_status_end_on, :is_self_attested_blind, :is_self_attested_disabled,
                                                                  :is_self_attested_long_term_care, :is_veteran, :is_refugee, :is_trafficking_victim, :is_former_foster_care, :age_left_foster_care,
                                                                  :foster_care_us_state, :had_medicaid_during_foster_care, :is_pregnant, :is_enrolled_on_medicaid, :is_post_partum_period,
                                                                  :children_expected_count, :pregnancy_due_on, :pregnancy_end_on, :is_primary_caregiver, :is_subject_to_five_year_bar,
                                                                  :is_five_year_bar_met, :is_forty_quarters, :is_ssn_applied, :non_ssn_apply_reason, :moved_on_or_after_welfare_reformed_law,
                                                                  :is_veteran_or_active_military, :is_spouse_or_dep_child_of_veteran_or_active_military, :is_currently_enrolled_in_health_plan,
                                                                  :has_daily_living_help, :need_help_paying_bills, :is_resident_post_092296, :is_vets_spouse_or_child, :has_job_income,
                                                                  :has_self_employment_income, :has_other_income, :has_unemployment_income, :has_deductions, :has_enrolled_health_coverage,
                                                                  :has_eligible_health_coverage, :has_american_indian_alaskan_native_income, :medicaid_chip_ineligible, :immigration_status_changed,
                                                                  :health_service_through_referral, :health_service_eligible, :tribal_state, :tribal_name, :tribe_codes, :is_medicaid_cubcare_eligible,
                                                                  :has_eligible_medicaid_cubcare, :medicaid_cubcare_due_on, :has_eligibility_changed, :has_household_income_changed,
                                                                  :person_coverage_end_on, :has_dependent_with_coverage, :dependent_job_end_on, :transfer_referral_reason,
                                                                  :five_year_bar_applies, :five_year_bar_met, :qualified_non_citizen)

          source_appli_params.merge(applicant_mergable_params).deep_symbolize_keys
        end
      end
    end
  end
end
