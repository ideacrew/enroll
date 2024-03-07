# frozen_string_literal: true

require File.join(Rails.root, 'app/data_migrations/golden_seed_financial_assistance_helper')
require File.join(Rails.root, 'app/data_migrations/golden_seed_helper')

# rubocop:disable Metrics/ModuleLength
# Cucumber steps to be used with the Financial Assistance Engine
# A few of the methods of Golden Seed Helper are included to facilitate quick generation of data
module FinancialAssistance
  module FinancialAssistanceWorld
    include GoldenSeedHelper
    include GoldenSeedFinancialAssistanceHelper
    def consumer(*traits)
      attributes = traits.extract_options!
      @consumer ||= (FactoryBot.create :user, :consumer, *traits, :with_consumer_role, attributes).tap do |usr|
        # Resetting the identity validation as cucumber tests are expected to pass through the identity validation.
        # Also, the identity validation is set to valid by default in the factory.
        usr.person.consumer_role.update_attributes!(identity_validation: 'na')
      end
    end

    def application(*traits)
      attributes = traits.extract_options!
      attributes.merge!(family_id: consumer.primary_family.id)
      @application ||= FactoryBot.create(:financial_assistance_application, *traits, attributes).tap do |application|
        application.update_attributes!(effective_date: TimeKeeper.date_of_record) if application.effective_date.blank?
        consumer.primary_family.family_members.each do |member|
          applicant = application.applicants.create(first_name: member.first_name,
                                                    last_name: member.last_name,
                                                    gender: member.gender,
                                                    dob: member.dob,
                                                    ssn: generate_and_return_unique_ssn,
                                                    is_primary_applicant: member.is_primary_applicant?,
                                                    is_applying_coverage: true)

          next if member.is_primary_applicant?
          application.ensure_relationship_with_primary(applicant, member.relationship)
        end
      end
    end

    def user_sign_up
      @user_sign_up ||= FactoryBot.attributes_for :user
    end

    def personal_information
      address = FactoryBot.attributes_for :address
      @personal_information ||= FactoryBot.attributes_for :person, :with_consumer_role, :with_ssn, address
    end

    def create_plan
      hbx_profile = FactoryBot.create(:hbx_profile, :no_open_enrollment_coverage_period)
      product = BenefitMarkets::Products::Product.all.first
      hbx_profile.benefit_sponsorship.benefit_coverage_periods.each do |bcp|
        bcp.update_attributes!(slcsp_id: product.id, slcsp: product.id)
      end
      hbx_profile.benefit_sponsorship.benefit_coverage_periods.first.benefit_packages.first
    end

    def assign_benchmark_plan_id(application)
      hbx_profile = HbxProfile.all.first
      product = BenefitMarkets::Products::Product.all.first
      coverage_period = hbx_profile.benefit_sponsorship.current_benefit_coverage_period
      coverage_period.update_attributes!(slcsp_id: product.id, slcsp: product.id)
      application.update_attributes!(benchmark_product_id: coverage_period.slcsp)
    end

    def create_dummy_ineligibility(application)
      coverage_year = TimeKeeper.date_of_record.year
      application.eligibility_determinations.each do |ed|
        ed.create!(max_aptc: 0.00,
                   csr_percent_as_integer: 0,
                   is_eligibility_determined: true,
                   effective_starting_on: Date.new(coverage_year, 0o1, 0o1),
                   determined_at: TimeKeeper.datetime_of_record - 30.days,
                   source: "Faa").save!
      end
      application.applicants.each { |applicant| applicant.update_attributes!(is_medicaid_chip_eligible: false, is_ia_eligible: false, is_without_assistance: true) }
      application.update_attributes!(aasm_state: 'determined')
    end

    def create_dummy_eligibility(application)
      coverage_year = TimeKeeper.date_of_record.year
      application.eligibility_determinations.each do |ed|
        ed.create!(max_aptc: 200.00,
                   csr_percent_as_integer: 73,
                   is_eligibility_determined: true,
                   effective_starting_on: Date.new(coverage_year, 0o1, 0o1),
                   determined_at: TimeKeeper.datetime_of_record - 30.days,
                   source: "Faa").save!
      end
      application.applicants.each { |applicant| applicant.update_attributes!(is_medicaid_chip_eligible: false, is_ia_eligible: true, is_without_assistance: false, csr_percent_as_integer: 73) }
      application.update_attributes!(aasm_state: 'determined')
    end

    # rubocop:disable Metrics/AbcSize
    def create_completed_fa_application_with_two_applicants
      case_family = golden_seed_rows.select { |row| row['case_name'] == "QA-CORE-2-IA-008" }
      primary_family_for_current_case = nil
      case_array_for_relationships = {
        fa_application: nil,
        fa_applicants: []
      }
      case_family.each do |case_info_hash|
        row_data = case_info_hash
        # TODO: Weird behavior. Prevents the original hash on the row attribute from being modified
        data_to_process = row_data.to_h.deep_dup.with_indifferent_access
        # Just using this structure since it was used in the original golden seed
        target_row_data = {
          person_attributes: data_to_process
        }
        # Dependent
        if primary_family_for_current_case.present?
          target_row_data.merge!(
            {
              primary_person_record: primary_family_for_current_case.primary_person,
              family_record: primary_family_for_current_case
            }
          ).with_indifferent_access
          puts("Beginning to create dependent record for #{target_row_data[:person_attributes]['case_name']}")
          current_target_person = generate_and_return_dependent_record(target_row_data)
          target_row_data[:person_attributes].merge!(current_target_person: current_target_person)
          target_row_data[:fa_application] = @target_fa_application
          puts("Beginning to create FA Applicant record for #{target_row_data[:person_attributes]['case_name']}")
          applicant_record = create_and_return_fa_applicant(target_row_data)
        # Primary person
        else
          puts("Beginning to create records for consumer role record for #{target_row_data[:person_attributes]['case_name']}")
          consumer_hash = create_and_return_matched_consumer_and_hash(target_row_data)
          @financial_assistance_applicant_user = consumer_hash[:user_record]
          primary_family_for_current_case = consumer_hash[:family_record]
          target_row_data[:person_attributes][:current_target_person] = consumer_hash[:primary_person_record]
          puts("Beginning to create HBX Enrollment record for #{target_row_data[:person_attributes]['case_name']}")
          # generate_and_return_hbx_enrollment(target_row_data)
          puts("Beginning to create Financial Assisstance application record for #{target_row_data[:person_attributes]['case_name']}")
          target_fa_application = create_and_return_fa_application(target_row_data)
          @target_fa_application = target_fa_application
          case_array_for_relationships[:fa_application] = target_fa_application
          target_row_data[:fa_application] = target_fa_application
          applicant_record = create_and_return_fa_applicant(target_row_data, true)
        end
        target_row_data[:target_fa_applicant] = applicant_record
        case_array_for_relationships[:fa_applicants] << target_row_data
        add_applicant_income(target_row_data)
        add_applicant_addresses(target_row_data)
        add_applicant_phones(target_row_data)
        add_applicant_emails(target_row_data)
        add_applicant_income_response(target_row_data)
      end
      create_fa_relationships(case_array_for_relationships)
    end
    # rubocop:enable Metrics/AbcSize

    def golden_seed_rows
      spreadsheet_location = "#{Rails.root}/ivl_testbed_scenarios_2021.csv"
      spreadsheet_rows = []
      CSV.foreach(spreadsheet_location, headers: true) do |row|
        spreadsheet_rows << row
      end
      spreadsheet_rows
    end

    def setup_applicant_eligible_for_max_aptc_and_csr(application)
      coverage_year = TimeKeeper.date_of_record.year
      application.eligibility_determinations.create!(
        max_aptc: 200.00,
        is_eligibility_determined: true,
        effective_starting_on: Date.new(coverage_year, 0o1, 0o1),
        determined_at: TimeKeeper.datetime_of_record - 30.days,
        source: 'Faa'
      ).save!
      application.applicants.each do |applicant|
        applicant.update_attributes!(
          is_medicaid_chip_eligible: false,
          is_ia_eligible: true,
          is_without_assistance: false,
          csr_percent_as_integer: 73,
          eligibility_determination_id: application.eligibility_determinations.first.id
        )
      end
      application.update_attributes!(aasm_state: 'determined')
    end

    def setup_applicant_eligible_for_medicaid_or_chip(application)
      coverage_year = TimeKeeper.date_of_record.year
      application.eligibility_determinations.create!(
        max_aptc: 0.00,
        is_eligibility_determined: true,
        effective_starting_on: Date.new(coverage_year, 0o1, 0o1),
        determined_at: TimeKeeper.datetime_of_record - 30.days,
        source: 'Faa'
      ).save!

      application.applicants.each do |applicant|
        applicant.update_attributes!(
          is_medicaid_chip_eligible: true,
          is_ia_eligible: false,
          is_without_assistance: false,
          eligibility_determination_id: application.eligibility_determinations.first.id
        )
      end
      application.update_attributes!(aasm_state: 'determined')
    end

    def setup_applicant_eligible_for_uqhp_and_non_magi_reasons(application)
      coverage_year = TimeKeeper.date_of_record.year
      application.eligibility_determinations.create!(
        max_aptc: 0.00,
        is_eligibility_determined: true,
        effective_starting_on: Date.new(coverage_year, 0o1, 0o1),
        determined_at: TimeKeeper.datetime_of_record - 30.days,
        source: 'Faa'
      ).save!

      application.applicants.each do |applicant|
        applicant.update_attributes!(
          is_medicaid_chip_eligible: false,
          is_ia_eligible: false,
          is_eligible_for_non_magi_reasons: true,
          is_without_assistance: true,
          eligibility_determination_id: application.eligibility_determinations.first.id
        )
      end
      application.update_attributes!(aasm_state: 'determined')
    end

    def setup_applicant_eligible_for_ineligible_determination(application)
      coverage_year = TimeKeeper.date_of_record.year
      application.eligibility_determinations.create!(
        max_aptc: 0.00,
        is_eligibility_determined: true,
        effective_starting_on: Date.new(coverage_year, 0o1, 0o1),
        determined_at: TimeKeeper.datetime_of_record - 30.days,
        source: 'Faa'
      ).save!

      application.applicants.each do |applicant|
        applicant.update_attributes!(
          is_medicaid_chip_eligible: false,
          is_ia_eligible: false,
          is_totally_ineligible: true,
          eligibility_determination_id: application.eligibility_determinations.first.id
        )
      end
      application.update_attributes!(aasm_state: 'determined')
    end

    def setup_non_applicants_with_no_determination(application)
      coverage_year = TimeKeeper.date_of_record.year
      application.eligibility_determinations.create!(
        max_aptc: 0.00,
        is_eligibility_determined: true,
        effective_starting_on: Date.new(coverage_year, 0o1, 0o1),
        determined_at: TimeKeeper.datetime_of_record - 30.days,
        source: 'Faa'
      ).save!

      application.applicants.each do |applicant|
        applicant.update_attributes!(
          is_applying_coverage: false,
          eligibility_determination_id: application.eligibility_determinations.first.id
        )
      end
      application.update_attributes!(aasm_state: 'determined')
    end

    def assistance_year_display(application)
      year_selection_enabled = FinancialAssistanceRegistry.feature_enabled?(:iap_year_selection) && (HbxProfile.current_hbx.under_open_enrollment? || FinancialAssistanceRegistry.feature_enabled?(:iap_year_selection_form))
      year_selection_enabled ? application.assistance_year.to_s : FinancialAssistanceRegistry[:enrollment_dates].setting(:application_year).item.constantize.new.call.value!.to_s
    end
  end
end
# rubocop:enable Metrics/ModuleLength

World(FinancialAssistance::FinancialAssistanceWorld)
