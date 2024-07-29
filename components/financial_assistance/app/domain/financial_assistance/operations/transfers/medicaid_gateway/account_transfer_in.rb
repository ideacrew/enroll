# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'
require 'aca_entities/operations/encryption/decrypt'

module FinancialAssistance
  module Operations
    module Transfers
      module MedicaidGateway
        # This Operation creates a new family and application draft
        # Operation receives ATP payload from medicaid gateway
        # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/ClassLength
        class AccountTransferIn
          include ::FinancialAssistance::MeCountyHelper
          include Dry::Monads[:result, :do, :try]

          PersonCandidate = Struct.new(:ssn, :dob, :first_name, :last_name)

          # @param [Hash] opts The options to transfer in a new Family & Application(persistence object)
          # @option opts [Hash] :params Atp payload params
          # @return [Dry::Monads::Result]
          def call(params)
            payload = yield load_data(params)
            payload = yield load_missing_county_names(payload) if FinancialAssistanceRegistry.feature_enabled?(:load_county_on_inbound_transfer)
            family = yield build_family(payload["family"])
            application_id = yield build_application(payload, family)
            application = yield find_application(application_id)
            _apps = yield build_applicants(payload, application, family)
            _applicants = yield fill_applicants_form(payload, application)
            _record = yield record(application)
            auto_submit(application) if FinancialAssistanceRegistry.feature_enabled?(:automatic_submission)
            Success(application_id)
          end

          private

          def auto_submit(application)
            Rails.logger.info "Calling automatic submission operation for application #{application.id}"
            FinancialAssistance::Operations::Transfers::MedicaidGateway::AutomaticSubmission.new.call(application)
          end

          def county_finder(zip)
            ::BenefitMarkets::Locations::CountyZip.where(zip: zip)
          end

          def find_specific_county(town_name)
            maine_counties_and_towns.detect { |key, _value| maine_counties_and_towns[key].include?(town_name) }&.first
          end

          def load_missing_county_names(payload)
            @zips_with_missing_counties = []
            @zips_with_multiple_counties = []

            payload.dig("family", "family_members").each do |person|
              person_addresses = person.dig("person", "addresses")
              populate_counties_for(person_addresses)
            end

            payload.dig("family", "magi_medicaid_applications")&.each do |application|
              application["applicants"]&.each do |applicant|
                applicant_addresses = applicant["addresses"]
                populate_counties_for(applicant_addresses)
              end
            end

            failure_message = "Unable to find county objects for zips #{@zips_with_missing_counties.uniq}" if @zips_with_missing_counties.present?
            failure_message = "Unable to match county for #{@zips_with_multiple_counties.uniq}, as multiple counties have this zip code." if @zips_with_multiple_counties.present?
            return Failure(failure_message) if failure_message.present?

            Success(payload)
          rescue StandardError => e
            Failure("load_missing_county_names #{e}")
          end

          def populate_counties_for(addresses)
            addresses.each do |address|
              next unless address["county"].blank?

              zip = address["zip"]
              county = county_finder(zip)
              address["county"] = county.first.county_name if county&.count == 1
              @zips_with_missing_counties << zip if county.blank?

              next unless county.count > 1
              town_name = address['city'].titleize
              county_name = find_specific_county(town_name)

              if county_name.present?
                address['county'] = county_name
              else
                @zips_with_multiple_counties << zip
              end
            end
          end

          def load_data(payload = {})
            stringified_payload = payload.to_h.deep_stringify_keys!
            decrypt_ssns(stringified_payload)
          rescue StandardError => e
            Failure("load_data #{e}")
          end

          def decrypt_ssn(ssn)
            return Success(nil) unless ssn
            AcaEntities::Operations::Encryption::Decrypt.new.call({ value: ssn })
          rescue StandardError => e
            Failure("decrypt ssn #{e}")
          end

          def decrypt_ssns(payload)
            payload["family"]["family_members"].each_with_index do |fm, i|
              ssn = fm["person"]["person_demographics"]["ssn"]
              decryption_result = decrypt_ssn(ssn)
              return decryption_result unless decryption_result.success?
              decrypted_ssn = decryption_result.value!
              payload["family"]["family_members"][i]["person"]["person_demographics"]["ssn"] = decrypted_ssn if decrypted_ssn.present?
              fm["person"]["person_relationships"].each_with_index do |relationship, ii|
                rssn = relationship["relative"]["ssn"]
                rdecryption_result = decrypt_ssn(rssn)
                return rdecryption_result unless rdecryption_result.success?
                rdecrypted_ssn = rdecryption_result.value!
                payload["family"]["family_members"][i]["person"]["person_relationships"][ii]["relative"]["ssn"] = rdecrypted_ssn if rdecrypted_ssn.present?
              end
            end
            Success(payload)
          rescue StandardError => e
            Failure("decrypt ssns #{e}")
          end

          def find_family(family_hash)
            person_params_result = sanitize_person_params(family_hash['family_members'].select { |a| a["is_primary_applicant"] == true}.first)
            return person_params_result if person_params_result.failure?
            person_params = person_params_result.value!
            match_criteria, records = ::Operations::People::Match.new.call({:dob => person_params[:dob],
                                                                            :last_name => person_params[:last_name],
                                                                            :first_name => person_params[:first_name],
                                                                            :ssn => person_params[:ssn]})
            return Success(nil) unless records.present?
            return Success(nil) unless [:ssn_present, :dob_present].include?(match_criteria)
            return Success(nil) if match_criteria == :dob_present && person_params[:ssn].present? && records.first.ssn != person_params[:ssn]

            person = records.first
            Success(person.primary_family)
          rescue StandardError => e
            Failure("find family error #{e}")
          end

          def build_family(family_hash)
            found_family_result = find_family(family_hash)
            return found_family_result unless found_family_result.success?
            found_family = found_family_result.value!
            @family = if found_family.present?
                        found_family
                      else
                        ::Family.new(family_hash.except('hbx_id', 'foreign_keys', 'broker_accounts', 'magi_medicaid_applications', 'family_members',
                                                        'households', 'ext_app_id'))
                      end
            family_hash['family_members'].sort_by { |a| a["is_primary_applicant"] ? 0 : 1 }.each do |family_member_hash|
              fm_result = create_member(family_member_hash)
              return fm_result unless fm_result.success?
            end
            @family.save!
            Success(@family)
          rescue Mongoid::Errors::Validations => e
            Failure("build_family validation: #{e.summary}")
          rescue StandardError => e
            Failure("build_family: #{e}")
          end

          def build_applicants(payload, application, family)
            sanitize_iap_hash = sanitize_applicant_params(payload["family"]['magi_medicaid_applications'].first, family.primary_person)
            return sanitize_iap_hash unless sanitize_iap_hash.success?
            sanitized = sanitize_iap_hash.value!
            payload["family"]['magi_medicaid_applications'].first.except!('applicants').merge!(applicants: sanitized)
            applicants_results = sanitized.map do |applicant|
              ::FinancialAssistance::Operations::Applicant::Build.new.call(params: applicant.merge(application: application))
            end
            applicants_results.map do |result|
              return result if result.failure?
              applicant = application.applicants.build
              applicant.assign_attributes(result.success.to_h)
            end
            Success(application.applicants)
          end

          def build_application(payload, family)
            app = payload["family"]['magi_medicaid_applications'].first
            # years_to_renew needs to be merged with a hash rocket to properly merge with the existing years_to_renew key
            app_params = app.merge!(family_id: family.id, benchmark_product_id: BSON::ObjectId.new, "years_to_renew" => 5)
            app_params["assistance_year"] = FinancialAssistanceRegistry[:enrollment_dates].setting(:application_year).item.constantize.new.call.value!.to_s
            ::FinancialAssistance::Operations::Application::Create.new.call(params: app_params.except('applicants').merge(applicants: []))
          rescue StandardError => e
            Failure("build_application: #{e}")
          end

          def create_member(family_member_hash)
            person_params_result = sanitize_person_params(family_member_hash)
            return person_params_result unless person_params_result.success?
            person_params = person_params_result.value!
            person_result = create_or_update_person(person_params)
            if person_result.success?
              @person = person_result.success
              fam_result = create_or_update_family_member(@person, @family, family_member_hash)
              return fam_result unless fam_result.success?
              @family_member = fam_result.value!
              consumer_role_params = family_member_hash['person']['consumer_role']
              create_or_update_consumer_role(consumer_role_params.merge(is_consumer_role: true), @family_member)
              create_or_update_vlp_documents(consumer_role_params['vlp_documents'], @person) if consumer_role_params['vlp_documents']
              Success(@person.consumer_role)
            else
              first_name = family_member_hash['person']['person_name']['first_name']
              last_name = family_member_hash['person']['person_name']['last_name']
              Failure("Failed to create or update person #{first_name} #{last_name} due to: #{person_result.failure}")
            end
          rescue StandardError => e
            Failure("create_member: #{e}")
          end

          def create_or_update_person(person_params)
            ::Operations::People::CreateOrUpdate.new.call(params: person_params)
          rescue StandardError => e
            Failure("create_or_update_person: #{e}")
          end

          def create_or_update_consumer_role(applicant_params, family_member)
            return unless applicant_params[:is_consumer_role]
            # assign_citizen_status
            params = applicant_params.except("lawful_presence_determination")
            merge_params = params.merge(citizen_status: applicant_params["lawful_presence_determination"]["citizen_status"])
            ::Operations::People::CreateOrUpdateConsumerRole.new.call(
              params: {
                applicant_params: merge_params,
                family_member: family_member,
                optimistic_upstream_coverage_attestation_interpretation: EnrollRegistry.feature_enabled?(:optimistic_upstream_coverage_attestation)
              }
            )
          rescue StandardError => e
            Failure("create_or_update_consumer_role: #{e}")
          end

          def create_or_update_family_member(person, family, family_member_hash)
            family_member = family.family_members.detect { |fm| fm.person_id.to_s == person.id.to_s }

            return Success(family_member) if family_member && (family_member_hash.key?(:is_active) ? family_member.is_active == family_member_hash[:is_active] : true)

            rel_result = create_or_update_relationship(person, family, family_member_hash['person']['person_relationships'][0]['kind'])
            return rel_result unless rel_result.success?

            fm_attr = { is_primary_applicant: family_member_hash['is_primary_applicant'],
                        is_consent_applicant: family_member_hash['is_consent_applicant'],
                        is_coverage_applicant: family_member_hash['is_coverage_applicant'],
                        is_active: family_member_hash['is_active'] }
            family_member = family.add_family_member(person, fm_attr)
            family_member.save!

            family.save!
            Success(family_member)
          rescue Mongoid::Errors::Validations => e
            first_name = family_member_hash['person']['person_name']['first_name']
            last_name = family_member_hash['person']['person_name']['last_name']
            Failure("Failed create_or_update_family_member validation for #{first_name} #{last_name} due to: #{e.summary}")
          rescue StandardError => e
            Failure("create_or_update_family_member: #{e}")
          end

          def create_or_update_vlp_documents(vlp_documents, person)
            failed_results = vlp_documents.each_with_object([]) do |vlp_document, failures|
              result = ::Operations::People::CreateOrUpdateVlpDocument.new.call(params: { applicant_params: vlp_document, person: person })
              failures << result.failure unless result.success?
            end
            Failure("Failed to create or update VLP document(s): #{failures}") if failed_results.present?
          rescue StandardError => e
            Failure("create_or_update_vlp_documents: #{e}")
          end

          def create_or_update_relationship(person, family, relationship_kind)
            if relationship_kind == "self"
              primary_self_relationship = PersonRelationship.new({
                                                                   :kind => relationship_kind,
                                                                   :relative_id => person.id
                                                                 })
              person.person_relationships << primary_self_relationship
              primary_self_relationship.save!
              return Success("created primary relationship to self")
            end

            existing_relationship = family.primary_person.person_relationships.detect { |rel| rel.relative_id.to_s == person.id.to_s }
            return Success("checked relationship") if existing_relationship && existing_relationship.kind == relationship_kind

            relationships = family.primary_person.ensure_relationship_with(person, relationship_kind)
            relationships&.map(&:save!)
            Success("created relationship")
          rescue StandardError => e
            Failure("create_or_update_relationship: #{e}")
          end

          def same_address_with_primary(family_member, primary)
            return Failure("No matching family member") unless family_member.present?
            member = family_member.person

            compare_keys = ["address_1", "address_2", "city", "state", "zip"]
            sas = member.is_homeless? == primary.is_homeless? &&
                  member.is_temporarily_out_of_state? == primary.is_temporarily_out_of_state? &&
                  member&.home_address&.attributes&.select {|k, _v| compare_keys.include? k} == primary&.home_address&.attributes&.select do |k, _v|
                                                                                                  compare_keys.include? k
                                                                                                end
            Success(sas)
          rescue StandardError => e
            Failure("same_address_with_primary: #{e}")
          end

          def sanitize_applicant_params(iap_hash, primary)
            sanitize_params = []
            applicants = iap_hash['applicants']
            applicants.each do |applicant_hash|
              family_member = @family.family_members.select do |fm|
                fm.person.dob == applicant_hash['demographic']['dob'].to_date &&
                  fm.person.first_name.downcase == applicant_hash['name']['first_name'].downcase &&
                  fm.person.last_name.downcase == applicant_hash['name']['last_name'].downcase
              end.first
              citizen_status_info = applicant_hash['citizenship_immigration_status_information']
              foster_info = applicant_hash['foster_care']
              address_result = same_address_with_primary(family_member, primary)
              phones = valid_applicant_phones(applicant_hash['phones'])
              return address_result unless address_result.success?
              sanitize_params << {
                family_member_id: family_member.id,
                relationship: family_member.relationship,
                first_name: applicant_hash['name']['first_name'],
                middle_name: applicant_hash['name']['middle_name'],
                last_name: applicant_hash['name']['last_name'],
                full_name: applicant_hash['name']['full_name'],
                name_sfx: applicant_hash['name']['name_sfx'],
                name_pfx: applicant_hash['name']['name_pfx'],
                alternate_name: applicant_hash['name']['alternate_name'],
                ssn: family_member.person.ssn,
                no_ssn: family_member.person.no_ssn,
                # "encrypted_ssn": applicant_hash['identifying_information']['encrypted_ssn'],
                gender: applicant_hash['demographic']['gender'],
                dob: applicant_hash['demographic']['dob'],
                ethnicity: applicant_hash['demographic']['ethnicity'] || [],
                race: applicant_hash['demographic']['race'],
                is_veteran_or_active_military: applicant_hash['demographic']['is_veteran_or_active_military'],
                is_vets_spouse_or_child: applicant_hash['demographic']['is_vets_spouse_or_child'],
                same_with_primary: address_result.value!,
                is_incarcerated: family_member.person.is_incarcerated,
                is_physically_disabled: applicant_hash['attestation']['is_self_attested_disabled'],
                is_self_attested_disabled: applicant_hash['attestation']['is_self_attested_disabled'],
                is_self_attested_blind: applicant_hash['attestation']['is_self_attested_blind'],
                is_self_attested_long_term_care: applicant_hash['attestation']['is_self_attested_long_term_care'],

                is_primary_applicant: applicant_hash['is_primary_applicant'],
                native_american_information: applicant_hash['native_american_information'],

                citizen_status: citizen_status_info ? citizen_status_info['citizen_status'] : nil,
                is_resident_post_092296: citizen_status_info ? citizen_status_info['is_resident_post_092296'] : nil,
                is_lawful_presence_self_attested: citizen_status_info ? citizen_status_info['is_lawful_presence_self_attested'] : nil,

                is_consumer_role: true, # applicant_hash['is_consumer_role'],
                is_resident_role: applicant_hash['is_resident_role'],
                is_applying_coverage: applicant_hash['is_applying_coverage'],
                is_consent_applicant: applicant_hash['is_consent_applicant'],

                vlp_subject: applicant_hash['vlp_subject'],
                alien_number: applicant_hash['alien_number'],
                i94_number: applicant_hash['i94_number'],
                visa_number: applicant_hash['visa_number'],
                passport_number: applicant_hash['passport_number'],
                sevis_id: applicant_hash['sevis_id'],
                naturalization_number: applicant_hash['naturalization_number'],
                receipt_number: applicant_hash['receipt_number'],
                citizenship_number: applicant_hash['citizenship_number'],
                card_number: applicant_hash['card_number'],
                country_of_citizenship: applicant_hash['country_of_citizenship'],
                vlp_description: applicant_hash['vlp_description'],
                expiration_date: applicant_hash['expiration_date'],
                issuing_country: applicant_hash['issuing_country'],

                person_hbx_id: family_member.person.hbx_id,
                ext_app_id: applicant_hash['person_hbx_id'],
                is_required_to_file_taxes: applicant_hash['is_required_to_file_taxes'],
                tax_filer_kind: applicant_hash['tax_filer_kind'],
                is_joint_tax_filing: applicant_hash['is_joint_tax_filing'],
                is_claimed_as_tax_dependent: applicant_hash['is_claimed_as_tax_dependent'],
                claimed_as_tax_dependent_by: applicant_hash['claimed_as_tax_dependent_by'],

                is_student: applicant_hash['student']['is_student'],
                student_kind: applicant_hash['student']['student_kind'],
                student_school_kind: applicant_hash['student']['student_school_kind'],
                student_status_end_on: applicant_hash['student']['student_status_end_on'],

                is_refugee: applicant_hash['is_refugee'],
                is_trafficking_victim: applicant_hash['is_trafficking_victim'],

                is_former_foster_care: foster_info ? foster_info['is_former_foster_care'] : nil,
                age_left_foster_care: foster_info ? foster_info['age_left_foster_care'] : nil,
                foster_care_us_state: foster_info ? foster_info['foster_care_us_state'] : nil,
                had_medicaid_during_foster_care: foster_info ? foster_info['had_medicaid_during_foster_care'] : nil,

                is_pregnant: applicant_hash.dig('pregnancy_information', 'is_pregnant'),
                is_enrolled_on_medicaid: applicant_hash.dig('pregnancy_information', 'is_enrolled_on_medicaid'),
                is_post_partum_period: applicant_hash.dig('pregnancy_information', 'is_post_partum_period'),
                children_expected_count: applicant_hash.dig('pregnancy_information', 'expected_children_count'),
                pregnancy_due_on: applicant_hash.dig('pregnancy_information', 'pregnancy_due_on'),
                pregnancy_end_on: applicant_hash.dig('pregnancy_information', 'pregnancy_end_on'),

                is_subject_to_five_year_bar: applicant_hash['is_refugee'],
                is_five_year_bar_met: applicant_hash['is_refugee'],
                is_forty_quarters: applicant_hash['is_forty_quarters'],
                is_ssn_applied: applicant_hash['is_ssn_applied'],
                non_ssn_apply_reason: applicant_hash['non_ssn_apply_reason'],
                moved_on_or_after_welfare_reformed_law: applicant_hash['moved_on_or_after_welfare_reformed_law'],
                is_currently_enrolled_in_health_plan: applicant_hash['is_currently_enrolled_in_health_plan'],
                has_daily_living_help: applicant_hash['has_daily_living_help'],
                need_help_paying_bills: applicant_hash['need_help_paying_bills'],
                has_job_income: applicant_hash['has_job_income'],
                has_self_employment_income: applicant_hash['has_self_employment_income'],
                has_unemployment_income: applicant_hash['has_unemployment_income'],
                has_other_income: applicant_hash['has_other_income'],
                has_deductions: applicant_hash['has_deductions'],
                has_enrolled_health_coverage: applicant_hash['has_enrolled_health_coverage'],
                has_eligible_health_coverage: applicant_hash['has_eligible_health_coverage'],

                addresses: applicant_hash['addresses'],
                emails: applicant_hash['emails'],
                phones: phones,
                incomes: applicant_hash['incomes'],
                benefits: applicant_hash['benefits'],
                deductions: applicant_hash['deductions'],

                is_medicare_eligible: applicant_hash['is_medicare_eligible'],
                has_insurance: applicant_hash['has_insurance'],
                has_state_health_benefit: applicant_hash['has_state_health_benefit'],
                had_prior_insurance: applicant_hash['had_prior_insurance'],
                age_of_applicant: applicant_hash['age_of_applicant'],
                hours_worked_per_week: applicant_hash['hours_worked_per_week'],
                indian_tribe_member: applicant_hash['indian_tribe_member'],
                tribal_id: applicant_hash['tribal_id'],
                tribal_name: applicant_hash['tribal_name'],
                tribal_state: applicant_hash['tribal_state'],
                transfer_referral_reason: applicant_hash['transfer_referral_reason']
              }
            end
            Success(sanitize_params)
          rescue StandardError => e
            Failure("sanitize_applicant_params: #{e}")
          end

          def valid_applicant_phones(phones)
            phones.map do |phone|
              valid_phone_params = phone.slice("kind", "country_code", "area_code", "number", "extension", "primary", "full_phone_number")
              invalid_phone = FinancialAssistance::Locations::Phone.new(valid_phone_params).invalid? || phone['full_phone_number']&.first == '0' || phone['area_code']&.first == '0'
              next if invalid_phone

              valid_phone_params
            end.compact
          end

          def sanitize_person_params(family_member_hash)
            person_hash = family_member_hash['person']
            consumer_role_hash = person_hash["consumer_role"]
            build_person_hash(person_hash, consumer_role_hash)
          rescue StandardError => e
            Failure("sanitize_person_params: #{e}")
          end

          def build_person_hash(person_hash, consumer_role_hash)
            phash = {
              first_name: person_hash['person_name']['first_name'],
              last_name: person_hash['person_name']['last_name'],
              middle_name: person_hash['person_name']['middle_name'],
              full_name: person_hash['person_name']['full_name'],
              ssn: person_hash['person_demographics']['ssn'],
              no_ssn: transform_no_ssn(person_hash['person_demographics']['ssn']), # update in aca entities contracts to receive as string
              gender: person_hash['person_demographics']['gender'],
              dob: person_hash['person_demographics']['dob'],
              date_of_death: person_hash['person_demographics']['date_of_death'],
              dob_check: person_hash['person_demographics']['dob_check'],
              race: consumer_role_hash['is_applying_coverage'] ? person_hash['race'] : nil,
              ethnicity: consumer_role_hash['is_applying_coverage'] ? person_hash['person_demographics']['ethnicity'] : [],
              is_incarcerated: consumer_role_hash['is_applying_coverage'] ? person_hash['person_demographics']['is_incarcerated'] : nil,
              tribal_id: person_hash['person_demographics']['tribal_id'],
              tribal_name: person_hash['person_demographics']['tribal_name'],
              tribal_state: person_hash['person_demographics']['tribal_state'],
              language_code: person_hash['person_demographics']['language_code'],
              is_tobacco_user: person_hash['person_health']['is_tobacco_user'],
              is_physically_disabled: person_hash['person_health']['is_physically_disabled'],
              is_homeless: person_hash['is_homeless'],
              is_temporarily_out_of_state: person_hash['is_temporarily_out_of_state'],
              age_off_excluded: person_hash['age_off_excluded'],
              is_active: person_hash['is_active'],
              is_disabled: person_hash['is_disabled'],
              individual_market_transitions: person_hash['individual_market_transitions'],
              verification_types: person_hash['verification_types'],
              addresses: person_hash['addresses'],
              emails: person_hash['emails'],
              phones: valid_person_phones(person_hash['phones'])
            }
            Success(phash)
          rescue StandardError => e
            Failure("build person hash #{e}")
          end

          def valid_person_phones(phones)
            phones.map do |phone|
              valid_phone_params = phone.slice("kind", "country_code", "area_code", "number", "extension", "primary", "full_phone_number")
              invalid_phone = Phone.new(valid_phone_params).invalid? || phone['full_phone_number']&.first == '0' || phone['area_code']&.first == '0'
              next if invalid_phone

              valid_phone_params
            end.compact
          end

          def transform_no_ssn(ssn)
            ssn.present? ? '0' : '1'
          end

          def find_application(id)
            applications = FinancialAssistance::Application.where(id: id)
            return Failure("Application with id #{id} not found") unless applications.any?
            Success(applications.first)
          end

          def fill_applicants_form(payload, application) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
            applications = payload["family"]['magi_medicaid_applications'].first
            applications[:applicants].each do |applicant|
              persisted_applicant = application.applicants.where(first_name: /^#{applicant[:first_name]}$/i, last_name: /^#{applicant[:last_name]}$/i, dob: applicant[:dob]).first
              return Failure("No matching applicant") unless persisted_applicant.present?
              claimed_by = application.applicants.where(ext_app_id: applicant[:claimed_as_tax_dependent_by]).first
              persisted_applicant.is_physically_disabled = applicant[:is_physically_disabled]
              persisted_applicant.is_self_attested_blind = applicant[:is_self_attested_blind]
              persisted_applicant.is_self_attested_disabled = applicant[:is_self_attested_disabled]
              persisted_applicant.is_required_to_file_taxes = applicant[:is_required_to_file_taxes]
              persisted_applicant.tax_filer_kind = applicant[:tax_filer_kind]
              persisted_applicant.is_joint_tax_filing = applicant[:is_joint_tax_filing]
              persisted_applicant.is_claimed_as_tax_dependent = applicant[:is_claimed_as_tax_dependent]
              persisted_applicant.claimed_as_tax_dependent_by = claimed_by ? claimed_by.id : nil

              persisted_applicant.is_student = applicant[:is_student]
              persisted_applicant.student_kind = applicant[:student_kind]
              persisted_applicant.student_school_kind = applicant[:student_school_kind]
              persisted_applicant.student_status_end_on = applicant[:student_status_end_on]

              persisted_applicant.is_refugee = applicant[:is_refugee]
              persisted_applicant.is_trafficking_victim = applicant[:is_trafficking_victim]

              persisted_applicant.is_former_foster_care = applicant[:is_former_foster_care]
              persisted_applicant.age_left_foster_care = applicant[:age_left_foster_care]
              persisted_applicant.foster_care_us_state = applicant[:foster_care_us_state]
              persisted_applicant.had_medicaid_during_foster_care = applicant[:had_medicaid_during_foster_care]

              persisted_applicant.is_pregnant = applicant[:is_pregnant]
              persisted_applicant.is_enrolled_on_medicaid = applicant[:is_enrolled_on_medicaid]
              persisted_applicant.is_post_partum_period = applicant[:is_post_partum_period]
              persisted_applicant.children_expected_count = applicant[:children_expected_count]
              persisted_applicant.pregnancy_due_on = applicant[:pregnancy_due_on]
              persisted_applicant.pregnancy_end_on = applicant[:pregnancy_end_on]

              persisted_applicant.is_subject_to_five_year_bar = applicant[:is_subject_to_five_year_bar]
              persisted_applicant.is_five_year_bar_met = applicant[:is_five_year_bar_met]
              persisted_applicant.is_forty_quarters = applicant[:is_forty_quarters]
              persisted_applicant.is_ssn_applied = applicant[:is_ssn_applied]
              persisted_applicant.non_ssn_apply_reason = applicant[:non_ssn_apply_reason]
              persisted_applicant.moved_on_or_after_welfare_reformed_law = applicant[:moved_on_or_after_welfare_reformed_law]
              persisted_applicant.is_currently_enrolled_in_health_plan = applicant[:is_currently_enrolled_in_health_plan]
              persisted_applicant.has_daily_living_help = applicant[:has_daily_living_help]
              persisted_applicant.need_help_paying_bills = applicant[:need_help_paying_bills]
              persisted_applicant.has_job_income = applicant[:has_job_income]
              persisted_applicant.has_self_employment_income = applicant[:has_self_employment_income]
              persisted_applicant.has_unemployment_income = applicant[:has_unemployment_income]
              persisted_applicant.has_other_income = applicant[:has_other_income]
              persisted_applicant.has_deductions = applicant[:has_deductions]
              persisted_applicant.has_enrolled_health_coverage = applicant[:has_enrolled_health_coverage]
              persisted_applicant.has_eligible_health_coverage = applicant[:has_eligible_health_coverage]
              persisted_applicant.incomes = applicant[:incomes]
              persisted_applicant.benefits = applicant[:benefits].first.nil? ? [] : applicant[:benefits].compact
              persisted_applicant.deductions = applicant[:deductions].collect {|d| d.except("amount_tax_exempt", "is_projected")}
              persisted_applicant.is_medicare_eligible = applicant[:is_medicare_eligible]
              persisted_applicant.transfer_referral_reason = applicant[:transfer_referral_reason]
              ::FinancialAssistance::Applicant.skip_callback(:update, :after, :propagate_applicant, raise: false) # TODO: remove raise: false after FFE migration
              ::FinancialAssistance::Relationship.skip_callback(:create, :after, :propagate_applicant)
              persisted_applicant.save(validate: false)
              persisted_applicant.relationships.each do |rel|
                rel.save(validate: false)
              end
              ::FinancialAssistance::Applicant.set_callback(:update, :after, :propagate_applicant, raise: false) # TODO: remove raise: false after FFE migration
              ::FinancialAssistance::Relationship.set_callback(:create, :after, :propagate_applicant)
            end
            Success("Successfully transferred in account")
          rescue Mongoid::Errors::Validations => e
            Failure("Fill applicant form validation: #{e.summary}")
          rescue StandardError => e
            Failure("Fill applicant form: #{e}")
          end

          def record(application)
            result = Try do
              application.set(transferred_at: DateTime.now.utc)
            end
            result.success? ? Success("recorded transferred_at") : Failure("could not set transferred_at")
          end
           # rubocop:enable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/ClassLength

        end
      end
    end
  end
end
