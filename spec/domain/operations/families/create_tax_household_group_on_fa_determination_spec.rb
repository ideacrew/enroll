# frozen_string_literal: true

RSpec.describe Operations::Families::CreateTaxHouseholdGroupOnFaDetermination, type: :model, dbclean: :after_each do

  let!(:person) do
    FactoryBot.create(:person,
                      :with_consumer_role,
                      :with_active_consumer_role,
                      hbx_id: '1179388',
                      last_name: 'Eric',
                      first_name: 'Pierpont',
                      dob: '1984-05-22')
  end

  let!(:family) {FactoryBot.create(:family, :with_primary_family_member, person: person)}

  let(:response_payload) do
    {
      family_reference: { hbx_id: family.hbx_assigned_id.to_s },
      assistance_year: 2022,
      aptc_effective_date: '2022-08-01',
      years_to_renew: 2022,
      renewal_consent_through_year: 0,
      is_ridp_verified: true,
      is_renewal_authorized: false,
      applicants: [{
        name: { first_name: 'Eric', middle_name: nil, last_name: 'Pierpont', name_sfx: nil, name_pfx: nil },
        identifying_information: { encrypted_ssn: 'MKPkdpmEFA2Yv2GPVAFbcoEDv/EHL8JPlQ==\n',has_ssn: false },
        demographic: { gender: 'Male', dob: '1984-05-22', ethnicity: ['', 'White', '', '', '', '', '', ''],
                       race: nil, is_veteran_or_active_military: false, is_vets_spouse_or_child: false },
        attestation: {
          is_incarcerated: false, is_self_attested_disabled: false, is_self_attested_blind: false, is_self_attested_long_term_care: false
        },
        is_primary_applicant: true,
        native_american_information: { indian_tribe_member: false,tribal_name: nil,tribal_state: nil },
        citizenship_immigration_status_information: {
          citizen_status: 'us_citizen',is_resident_post_092296: false, is_lawful_presence_self_attested: false
        },
        is_consumer_role: true,
        is_resident_role: false,
        is_applying_coverage: true,
        is_consent_applicant: false,
        vlp_document: nil,
        family_member_reference: {
          family_member_hbx_id: '1179388', first_name: 'Eric', last_name: 'Pierpont', person_hbx_id: '1179388', is_primary_family_member: true
        },
        person_hbx_id: '1179388',
        is_required_to_file_taxes: true,
        is_filing_as_head_of_household: false,
        tax_filer_kind: 'tax_filer',
        is_joint_tax_filing: false,
        is_claimed_as_tax_dependent: false,
        claimed_as_tax_dependent_by: nil,
        student: { is_student: false,student_kind: nil,student_school_kind: nil,student_status_end_on: nil },
        is_refugee: false,
        is_trafficking_victim: false,
        foster_care: {
          is_former_foster_care: false,age_left_foster_care: nil,foster_care_us_state: nil,had_medicaid_during_foster_care: false
        },
        pregnancy_information: {
          is_pregnant: false, is_enrolled_on_medicaid: false, is_post_partum_period: false,
          expected_children_count: nil, pregnancy_due_on: nil, pregnancy_end_on: nil
        },
        is_primary_caregiver: false,
        is_subject_to_five_year_bar: false,
        is_five_year_bar_met: false,
        is_forty_quarters: false,
        is_ssn_applied: false,
        non_ssn_apply_reason: nil,
        moved_on_or_after_welfare_reformed_law: false,
        is_currently_enrolled_in_health_plan: false,
        has_daily_living_help: false,
        need_help_paying_bills: false,
        has_job_income: true,
        has_self_employment_income: false,
        has_unemployment_income: false,
        has_other_income: false,
        has_deductions: false,
        has_enrolled_health_coverage: false,
        has_eligible_health_coverage: false,
        job_coverage_ended_in_past_3_months: false,
        job_coverage_end_date: nil,
        medicaid_and_chip: {
          not_eligible_in_last_90_days: false,
          denied_on: nil,
          ended_as_change_in_eligibility: false,
          hh_income_or_size_changed: false,
          medicaid_or_chip_coverage_end_date: nil,
          ineligible_due_to_immigration_in_last_5_years: false,
          immigration_status_changed_since_ineligibility: false
        },
        other_health_service: { has_received: false, is_eligible: false },
        addresses: [{
          kind: 'home',
          address_1: '50 E Street',
          address_2: nil,
          address_3: nil,
          city: 'Test City',
          county: 'Test County',
          state: 'ME',
          zip: '04106',
          country_name: nil
        }],
        emails: [{
          kind: 'home',
          address: 'dummy@gmail.com'
        }],
        phones: [{
          kind: 'home',
          country_code: nil,
          area_code: '111',
          number: '1111111',
          extension: nil,
          primary: false,
          full_phone_number: '1111111111'
        }],
        incomes: [{
          title: nil,
          kind: 'wages_and_salaries',
          wage_type: nil,
          hours_per_week: nil,
          amount: '1096.0',
          amount_tax_exempt: '0.0',
          frequency_kind: 'Weekly',
          start_on: '2021-07-01',
          end_on: '2022-07-01',
          is_projected: false,
          employer: { employer_name: 'Test Employer', employer_id: nil },
          has_property_usage_rights: nil,
          ssi_type: nil,
          submitted_at: '2022-06-28T19:19:30.000+00:00'
        }],
        benefits: [],
        deductions: [],
        is_medicare_eligible: false,
        has_insurance: false,
        has_state_health_benefit: false,
        had_prior_insurance: false,
        prior_insurance_end_date: nil,
        age_of_applicant: 38,
        is_self_attested_long_term_care: false,
        hours_worked_per_week: 0,
        is_temporarily_out_of_state: false,
        is_claimed_as_dependent_by_non_applicant: false,
        benchmark_premium: {
          health_only_lcsp_premiums: [{
            member_identifier: '1179388',
            monthly_premium: '374.86'
          }],health_only_slcsp_premiums: [{
            member_identifier: '1179388',
            monthly_premium: '384.34'
          }]
        },
        is_homeless: false,
        mitc_income: {
          amount: 56_992,
          taxable_interest: 0,
          tax_exempt_interest: 0,
          taxable_refunds: 0,
          alimony: 0,
          capital_gain_or_loss: 0,
          pensions_and_annuities_taxable_amount: 0,
          farm_income_or_loss: 0,
          unemployment_compensation: 0,
          other_income: 0,
          magi_deductions: 0,
          adjusted_gross_income: 28_417,
          deductible_part_of_self_employment_tax: 0,
          ira_deduction: 0,
          student_loan_interest_deduction: 0,
          tution_and_fees: 0,
          other_magi_eligible_income: 0
        },
        mitc_relationships: [],
        mitc_state_resident: true,
        mitc_is_required_to_file_taxes: true,
        income_evidence: nil,
        esi_evidence: nil,
        non_esi_evidence: nil,
        local_mec_evidence: nil
      }],
      tax_households: tax_households,
      relationships: [],
      us_state: 'ME',
      hbx_id: '1260867',
      oe_start_on: '2021-11-01',
      notice_options: {
        send_eligibility_notices: true,send_open_enrollment_notices: false,paper_notification: false
      },
      mitc_households: [{
        household_id: '1',
        people: [{
          person_id: 1_179_388
        }]
      }],
      mitc_tax_returns: [{ filers: [{ person_id: 1_179_388 }], dependents: [] }],
      submitted_at: '2022-07-11T08:09:52.489+00:00'
    }
  end


  let!(:application) do
    FactoryBot.create(:financial_assistance_application,
                      family_id: family.id,
                      aasm_state: 'determined',
                      hbx_id: '1260867',
                      submitted_at: TimeKeeper.date_of_record)
  end

  let!(:applicant) do
    FactoryBot.create(:financial_assistance_applicant,
                      application: application,
                      family_member_id: family.primary_applicant.id,
                      is_primary_applicant: true,
                      person_hbx_id: person.hbx_id,
                      eligibility_determination_id: eligibility_determination.id,
                      dob: person.dob)
  end

  let!(:eligibility_determination) do
    FactoryBot.create(:financial_assistance_eligibility_determination, application: application, max_aptc: "317.0")
  end

  let(:tax_households) do
    [{
      max_aptc: "317.0",
      hbx_id: eligibility_determination.hbx_assigned_id.to_s,
      is_insurance_assistance_eligible: "Yes",
      tax_household_members: [{
        product_eligibility_determination: {
          is_ia_eligible: true,
          is_medicaid_chip_eligible: false,
          is_totally_ineligible: nil,
          is_magi_medicaid: false,
          is_uqhp_eligible: nil,
          is_csr_eligible: true,
          csr: "73",
          is_non_magi_medicaid_eligible: false,
          is_without_assistance: false,
          magi_medicaid_monthly_household_income: "56992.0",
          medicaid_household_size: 1,
          magi_medicaid_monthly_income_limit: "0.0",
          magi_as_percentage_of_fpl: "419.0",
          magi_medicaid_category: "adult_group",
          magi_medicaid_ineligibility_reasons: ["Applicant's MAGI above the threshold for category"],
          is_eligible_for_non_magi_reasons: false,
          chip_ineligibility_reasons: ["Applicant did not meet the requirements for any CHIP category"],
          magi_medicaid_category_threshold: "18754.0",
          medicaid_chip_category: "None",
          medicaid_chip_category_threshold: "0.0",
          category_determinations: [{
            category: "Residency",
            indicator_code: true,
            ineligibility_code: nil,
            ineligibility_reason: nil
          }, {
            category: "Adult Group Category",
            indicator_code: true,
            ineligibility_code: nil,
            ineligibility_reason: nil
          }, {
            category: "Parent Caretaker Category",
            indicator_code: false,
            ineligibility_code: 146,
            ineligibility_reason: "No child met all criteria for parent caretaker category"
          }, {
            category: "Pregnancy Category",
            indicator_code: false,
            ineligibility_code: 124,
            ineligibility_reason: "Applicant not pregnant or within postpartum period"
          }, {
            category: "Child Category",
            indicator_code: false,
            ineligibility_code: 394,
            ineligibility_reason: "Applicant is over the age limit for the young adult threshold in the state"
          }, {
            category: "Optional Targeted Low Income Child",
            indicator_code: nil,
            ineligibility_code: nil,
            ineligibility_reason: nil
          }, {
            category: "CHIP Targeted Low Income Child",
            indicator_code: false,
            ineligibility_code: 127,
            ineligibility_reason: "Applicant's age is not within the allowed age range"
          }, {
            category: "Unborn Child",
            indicator_code: nil,
            ineligibility_code: nil,
            ineligibility_reason: nil
          }, {
            category: "Income Medicaid Eligible",
            indicator_code: false,
            ineligibility_code: 402,
            ineligibility_reason: "Applicant's income is greater than the threshold for all eligible categories"
          }, {
            category: "Income CHIP Eligible",
            indicator_code: false,
            ineligibility_code: 401,
            ineligibility_reason: "Applicant did not meet the requirements for any eligibility category"
          }, {
            category: "Medicaid CHIPRA 214",
            indicator_code: nil,
            ineligibility_code: nil,
            ineligibility_reason: nil
          }, {
            category: "CHIP CHIPRA 214",
            indicator_code: nil,
            ineligibility_code: nil,
            ineligibility_reason: nil
          }, {
            category: "Trafficking Victim",
            indicator_code: nil,
            ineligibility_code: nil,
            ineligibility_reason: nil
          }, {
            category: "Seven Year Limit",
            indicator_code: nil,
            ineligibility_code: nil,
            ineligibility_reason: nil
          }, {
            category: "Five Year Bar",
            indicator_code: nil,
            ineligibility_code: nil,
            ineligibility_reason: nil
          }, {
            category: "Title II Work Quarters Met",
            indicator_code: nil,
            ineligibility_code: nil,
            ineligibility_reason: nil
          }, {
            category: "Medicaid Citizen Or Immigrant",
            indicator_code: true,
            ineligibility_code: nil,
            ineligibility_reason: nil
          }, {
            category: "CHIP Citizen Or Immigrant",
            indicator_code: true,
            ineligibility_code: nil,
            ineligibility_reason: nil
          }, {
            category: "Former Foster Care Category",
            indicator_code: false,
            ineligibility_code: 400,
            ineligibility_reason: "Applicant was not formerly in foster care"
          }, {
            category: "Work Quarters Override Income",
            indicator_code: false,
            ineligibility_code: 340,
            ineligibility_reason: "Income is greater than 100% FPL"
          }, {
            category: "State Health Benefits CHIP",
            indicator_code: nil,
            ineligibility_code: nil,
            ineligibility_reason: nil
          }, {
            category: "CHIP Waiting Period Satisfied",
            indicator_code: nil,
            ineligibility_code: nil,
            ineligibility_reason: nil
          }, {
            category: "Dependent Child Covered",
            indicator_code: nil,
            ineligibility_code: nil,
            ineligibility_reason: nil
          }, {
            category: "Medicaid Non-MAGI Referral",
            indicator_code: false,
            ineligibility_code: 108,
            ineligibility_reason: "Applicant does not meet requirements for a non-MAGI referral"
          }, {
            category: "Emergency Medicaid",
            indicator_code: false,
            ineligibility_code: 109,
            ineligibility_reason: "Applicant does not meet the eligibility criteria for emergency Medicaid"
          }, {
            category: "Refugee Medical Assistance",
            indicator_code: nil,
            ineligibility_code: nil,
            ineligibility_reason: nil
          }, {
            category: "APTC Referral",
            indicator_code: true,
            ineligibility_code: nil,
            ineligibility_reason: nil
          }]
        },
        applicant_reference: {
          first_name: "Eric", last_name: "Pierpont", dob: "1984-05-22", person_hbx_id: "1179388", encrypted_ssn: "MKPkdpmEFA2Yv2GPVAFbcoEDv/EHL8JPlQ==\n"
        }
      }],
      annual_tax_household_income: "28417.93",
      csr_annual_income_limit: "146188000.0",
      effective_on: "2022-08-01",
      determined_on: "2022-07-11"
    }]
  end

  let(:result) { subject.call(response_payload) }


  it 'should return tax_household_group' do
    expect(result.success?).to be_truthy
    expect(result.success).to be_a(TaxHouseholdGroup)
    expect(family.reload.tax_household_groups.count).to eq 1
  end
end