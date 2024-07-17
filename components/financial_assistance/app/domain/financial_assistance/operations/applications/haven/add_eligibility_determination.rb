# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module FinancialAssistance
  module Operations
    module Applications
      module Haven
        # This Operation adds the eligibility determination to the Application(persistence object)
        # Operation receives the xml payload from HAVEN
        class AddEligibilityDetermination
          include Dry::Monads[:do, :result]

          # @param [Hash] opts The options to add eligibility determination to Application(persistence object)
          # @return [Dry::Monads::Result]
          def call(params)
            valid_params = yield validate(params)
            parsed_family = yield parse_and_validate_response(valid_params)
            result = yield update_application_and_applicant(parsed_family)

            Success(result)
          end

          private

          def validate(params)
            return Failure('Missing application') unless params.key?(:application)

            Success(params)
          end

          def parse_and_validate_response(valid_params)
            @application = valid_params[:application]
            @response_payload = @application.eligibility_response_payload

            return Failure('No response payload') if @response_payload.blank?

            verified_family = Parsers::Xml::Cv::HavenVerifiedFamilyParser.new
            verified_family.parse(@response_payload)
            result, message = check_parsed_payload_for_validation(verified_family)
            if result
              Success(verified_family)
            else
              @application.update_application(message, 422)
              Failure(message)
            end
          end

          def check_parsed_payload_for_validation(verified_family)
            if !max_aptc_with_eligible_members?(verified_family)
              [false, "Max APTC exists but no member is eligible for insurance assistance"]
            elsif !ia_eligible_members_with_aptc(verified_family)
              [false, "Members are eligible for insurance assistance but no eligibility section exists in the payload"]
            else
              [true, '']
            end
          end

          def ia_eligible_members_with_aptc(verified_family)
            return true if verified_family.family_members.all?{|mem| !mem.is_insurance_assistance_eligible }

            parsed_eds = verified_family.households.flat_map(&:tax_households).flat_map(&:eligibility_determinations)
            parsed_eds.empty? ? false : true
          end

          def max_aptc_with_eligible_members?(verified_family)
            parsed_eds = verified_family.households.flat_map(&:tax_households).flat_map(&:eligibility_determinations)
            return true unless parsed_eds.any?{|ed| ed.maximum_aptc.to_f > 0.00 }

            verified_family.family_members.any?(&:is_insurance_assistance_eligible)
          end

          def update_application_and_applicant(verified_family)
            @application.update_response_attributes(integrated_case_id: verified_family.integrated_case_id)
            verified_primary_family_member = verified_family.family_members.detect{ |fm| fm.person.hbx_id == verified_family.primary_family_member_id }
            verified_dependents = verified_family.family_members.reject{ |fm| fm.person.hbx_id == verified_family.primary_family_member_id }
            primary_applicant = @application.search_applicant(verified_primary_family_member)

            if primary_applicant.blank?
              @application.update_application("Failed to find Primary Applicant on an Application", 422)
              return Failure('Failed to find Primary Applicant on an Application')
            end

            active_verified_household = verified_family.households.max_by(&:start_date)

            verified_dependents.each do |verified_family_member|
              if @application.search_applicant(verified_family_member).blank?
                @application.update_application("Failed to find Dependent Applicant on an Application", 422)
                return Failure("Failed to find Dependent Applicant on an Application")
              end
            end
            Success(build_or_update_applicants_eligibility_determinations(verified_family, primary_applicant, active_verified_household))
          end

          # rubocop:disable Metrics/CyclomaticComplexity
          def build_or_update_applicants_eligibility_determinations(verified_family, _primary_applicant, active_verified_household)
            verified_tax_households = active_verified_household.tax_households.select{|th| th.primary_applicant_id == verified_family.primary_family_member_id}
            return unless verified_tax_households.present?

            ed_hbx_assigned_ids = []
            @application.eligibility_determinations.each { |ed| ed_hbx_assigned_ids << ed.hbx_assigned_id.to_s}
            verified_tax_households.each do |vthh|
              if ed_hbx_assigned_ids.include?(vthh.hbx_assigned_id)
                eligibility_determination = @application.eligibility_determinations.select{|ed| ed.hbx_assigned_id == vthh.hbx_assigned_id.to_i}.first
                eligibility_determination.update_attributes(effective_starting_on: vthh.start_date, is_eligibility_determined: true)
                applicants_persons_hbx_ids = []
                @application.applicants.each { |appl| applicants_persons_hbx_ids << appl.person_hbx_id.to_s}
                vthh.tax_household_members.each do |thhm|
                  next unless applicants_persons_hbx_ids.include?(thhm.person_id)
                  update_verified_applicants(@application, verified_family, thhm, vthh)
                end
                update_eligibility_determinations(vthh, eligibility_determination)
              else
                @application.update_application("Failed to find eligibility determinations in our DB with the ids in xml", 422)
                return Failure("Failed to find eligibility determinations in our DB with the ids in xml")
              end
            end
            @application.save!
          end
          # rubocop:enable Metrics/CyclomaticComplexity

          def update_eligibility_determinations(vthh, eligibility_determination)
            ed_update_params = { source: 'Faa', determined_at: DateTime.now }

            if vthh.eligibility_determinations.present?
              verified_eligibility_determination = vthh.eligibility_determinations.max_by(&:determination_date)
              verified_aptc = verified_eligibility_determination.maximum_aptc.to_f > 0.00 ? verified_eligibility_determination.maximum_aptc : 0.00
              ed_update_params.merge!({ max_aptc: verified_aptc,
                                        determined_at: verified_eligibility_determination.determination_date,
                                        aptc_csr_annual_household_income: verified_eligibility_determination.aptc_csr_annual_household_income,
                                        aptc_annual_income_limit: verified_eligibility_determination.aptc_annual_income_limit,
                                        csr_annual_income_limit: verified_eligibility_determination.csr_annual_income_limit })
            end

            eligibility_determination.update_attributes!(ed_update_params)
          end

          def update_verified_applicants(application_in_context, verified_family, thhm, verified_thh)
            verified_eligibility_determination = verified_thh.eligibility_determinations.max_by(&:determination_date)
            applicant = application_in_context.applicants.select { |app| app.person_hbx_id == thhm.person_id }.first
            verified_family.family_members.each do |verified_family_member|
              next unless verified_family_member.person.hbx_id == thhm.person_id

              attributes = {medicaid_household_size: verified_family_member.medicaid_household_size,
                            magi_medicaid_category: verified_family_member.magi_medicaid_category,
                            magi_as_percentage_of_fpl: verified_family_member.magi_as_percentage_of_fpl,
                            magi_medicaid_monthly_income_limit: verified_family_member.magi_medicaid_monthly_income_limit,
                            magi_medicaid_monthly_household_income: verified_family_member.magi_medicaid_monthly_household_income,
                            is_without_assistance: verified_family_member.is_without_assistance,
                            is_ia_eligible: verified_family_member.is_insurance_assistance_eligible,
                            is_medicaid_chip_eligible: verified_family_member.is_medicaid_chip_eligible,
                            is_non_magi_medicaid_eligible: verified_family_member.is_non_magi_medicaid_eligible,
                            is_totally_ineligible: verified_family_member.is_totally_ineligible}

              attributes.merge!(csr_percent_as_integer: verified_eligibility_determination.csr_percent) if verified_family_member.is_insurance_assistance_eligible
              applicant.update_attributes(attributes)
            end
          end
        end
      end
    end
  end
end
