# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'
require 'rails_helper'

RSpec.describe ::FinancialAssistance::Operations::Transformers::FamilyTo::Cv3Family, dbclean: :after_each do
  let(:primary_applicant) { FactoryBot.create(:person, hbx_id: "732020", gender: 'male') }
  let(:dependent1) { FactoryBot.create(:person, hbx_id: "732021", gender: 'male') }
  let(:dependent2) { FactoryBot.create(:person, hbx_id: "732022", gender: 'female') }
  let(:primary_addresses) { primary_applicant.addresses }
  let(:dependent1_addresses) { dependent1.addresses }
  let(:dependent2_addresses) { dependent2.addresses }
  let(:primary_emails) { primary_applicant.emails }
  let(:dependent1_emails) { dependent1.emails }
  let(:dependent2_emails) { dependent2.emails }
  let(:primary_phones) { primary_applicant.phones }
  let(:dependent1_phones) { dependent1.phones }
  let(:dependent2_phones) { dependent2.phones }
  let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: primary_applicant) }
  let(:family_member1) { family.primary_family_member }
  let(:family_member2) { FactoryBot.create(:family_member, family: family, person: dependent1) }
  let(:family_member3) { FactoryBot.create(:family_member, family: family, person: dependent2) }
  let!(:application) { FactoryBot.create(:financial_assistance_application, family_id: family.id, aasm_state: 'submitted', hbx_id: "830293", effective_date: DateTime.new(2021,1,1,4,5,6), submitted_at: TimeKeeper.date_of_record) }
  let!(:applicant1) do
    FactoryBot.create(:financial_assistance_applicant, application: application, family_member_id: family_member1.id, is_primary_applicant: true, person_hbx_id: primary_applicant.hbx_id, gender: primary_applicant.gender, dob: primary_applicant.dob)
  end
  let!(:applicant2) { FactoryBot.create(:financial_assistance_applicant, application: application, family_member_id: family_member2.id, person_hbx_id: dependent1.hbx_id, gender: dependent1.gender, dob: dependent1.dob) }
  let!(:applicant3) { FactoryBot.create(:financial_assistance_applicant, application: application, family_member_id: family_member3.id, person_hbx_id: dependent2.hbx_id, gender: dependent2.gender, dob: dependent2.dob) }
  let(:create_instate_addresses) do
    application.applicants.each do |appl|
      appl.addresses = [FactoryBot.build(:financial_assistance_address,
                                         :address_1 => '1111 Awesome Street NE',
                                         :address_2 => '#111',
                                         :address_3 => '',
                                         :city => 'Washington',
                                         :country_name => '',
                                         :kind => 'home',
                                         :state => FinancialAssistanceRegistry[:enroll_app].setting(:state_abbreviation).item,
                                         :zip => '20001',
                                         county: '')]
      appl.save!
    end
    application.save!
  end
  let(:create_relationships) do
    application.applicants.first.update_attributes!(is_primary_applicant: true) unless application.primary_applicant.present?
    application.ensure_relationship_with_primary(applicant2, 'child')
    application.ensure_relationship_with_primary(applicant3, 'child')
    application.build_relationship_matrix
    application.save!
  end

  let(:products) { FactoryBot.create_list(:benefit_markets_products_health_products_health_product, 1, :silver) }
  let(:product) { products.first }
  let(:oe_start_on) { HbxProfile.bcp_by_effective_period(application.effective_date.to_date).open_enrollment_start_on }

  let!(:hbx_profile) { FactoryBot.create :hbx_profile }

  describe '#construct_payload' do
    subject { FinancialAssistance::Operations::Transformers::FamilyTo::Cv3Family.new.call(family) }

    before :each do
      BenefitMarkets::Locations::CountyZip.delete_all
      BenefitMarkets::Locations::RatingArea.delete_all
      products
    end

    it 'should return payload' do
      expect(subject.value!).to include(
        {
          :hbx_id => family.hbx_assigned_id.to_s,
          :family_members => [
            {
              :hbx_id => '732020',
              :is_primary_applicant => true,
              :is_consent_applicant => false,
              :is_coverage_applicant => true,
              :is_active => true,
              :person => {
                :hbx_id => '732020',
                :person_name => {
                  :first_name => primary_applicant.first_name,
                  :middle_name => nil,
                  :last_name => primary_applicant.last_name,
                  :name_sfx => nil,
                  :name_pfx => nil,
                  :full_name => primary_applicant.full_name,
                  :alternate_name => nil
                },
                :person_demographics => {
                  :encrypted_ssn => nil,
                  :no_ssn => true,
                  :gender => primary_applicant.gender,
                  :dob => primary_applicant.dob,
                  :date_of_death => nil,
                  :dob_check => nil,
                  :is_incarcerated => false,
                  :ethnicity => nil,
                  :race => nil,
                  :tribal_id => nil,
                  :language_code => "en"
                },
                :person_health => {
                  :is_tobacco_user => "unknown",
                  :is_physically_disabled => nil
                },
                :no_dc_address => false,
                :no_dc_address_reason => "",
                :is_homeless => false,
                :is_temporarily_out_of_state => false,
                :age_off_excluded => false,
                :is_applying_for_assistance => nil,
                :is_active => true,
                :is_disabled => nil,
                :person_relationships => [],
                :consumer_role => nil,
                :resident_role => nil,
                :individual_market_transitions => [],
                :verification_types => [],
                :user => {},
                :addresses => [
                  {
                    :kind => primary_addresses[0].kind,
                    :address_1 => primary_addresses[0].address_1,
                    :address_2 => primary_addresses[0].address_2,
                    :address_3 => primary_addresses[0].address_3,
                    :city => primary_addresses[0].city,
                    :county => primary_addresses[0].county,
                    :state => primary_addresses[0].state,
                    :zip => primary_addresses[0].zip,
                    :country_name => "United States of America",
                    :has_fixed_address => true
                  },
                  {
                    :kind => primary_addresses[1].kind,
                    :address_1 => primary_addresses[1].address_1,
                    :address_2 => primary_addresses[1].address_2,
                    :address_3 => primary_addresses[1].address_3,
                    :city => primary_addresses[1].city,
                    :county => primary_addresses[1].county,
                    :state => primary_addresses[1].state,
                    :zip => primary_addresses[1].zip,
                    :country_name => "United States of America",
                    :has_fixed_address => true
                  }
                ],
                :emails => [
                  {:kind => primary_emails[0].kind, :address => primary_emails[0].address},
                  {:kind => primary_emails[1].kind, :address => primary_emails[1].address}
                ],
                :phones => [
                  {
                    :kind => primary_phones[0].kind,
                    :country_code => "",
                    :area_code => primary_phones[0].area_code,
                    :number => primary_phones[0].number,
                    :extension => primary_phones[0].extension,
                    :primary => nil,
                    :full_phone_number => primary_phones[0].full_phone_number
                  },
                  {
                    :kind => primary_phones[1].kind,
                    :country_code => "",
                    :area_code => primary_phones[1].area_code,
                    :number => primary_phones[1].number,
                    :extension => primary_phones[1].extension,
                    :primary => nil,
                    :full_phone_number => primary_phones[1].full_phone_number
                  }
                ],
                :documents => [],
                :timestamp => {
                  :created_at => primary_applicant.created_at.to_datetime,
                  :modified_at => primary_applicant.updated_at.to_datetime
                }
              },
              :timestamp => {
                :created_at => family_member1.created_at.to_datetime,
                :modified_at => family_member1.updated_at.to_datetime
              }
            },
            {
              :hbx_id => "732021",
              :is_primary_applicant => false,
              :is_consent_applicant => false,
              :is_coverage_applicant => true,
              :is_active => true,
              :person => {
                :hbx_id => "732021",
                :person_name => {
                  :first_name => dependent1.first_name,
                  :middle_name => nil,
                  :last_name => dependent1.last_name,
                  :name_sfx => nil,
                  :name_pfx => nil,
                  :full_name => dependent1.full_name,
                  :alternate_name => nil
                },
                :person_demographics => {
                  :encrypted_ssn => nil,
                  :no_ssn => true,
                  :gender => dependent1.gender,
                  :dob => dependent1.dob,
                  :date_of_death => nil,
                  :dob_check => nil,
                  :is_incarcerated => false,
                  :ethnicity => nil,
                  :race => nil,
                  :tribal_id => nil,
                  :language_code => "en"
                },
                :person_health => {
                  :is_tobacco_user => "unknown",
                  :is_physically_disabled => nil
                },
                :no_dc_address => false,
                :no_dc_address_reason => "",
                :is_homeless => false,
                :is_temporarily_out_of_state => false,
                :age_off_excluded => false,
                :is_applying_for_assistance => nil,
                :is_active => true,
                :is_disabled => nil,
                :person_relationships => [],
                :consumer_role => nil,
                :resident_role => nil,
                :individual_market_transitions => [],
                :verification_types => [],
                :user => {},
                :addresses => [
                  {
                    :kind => dependent1_addresses[0].kind,
                    :address_1 => dependent1_addresses[0].address_1,
                    :address_2 => dependent1_addresses[0].address_2,
                    :address_3 => dependent1_addresses[0].address_3,
                    :city => dependent1_addresses[0].city,
                    :county => dependent1_addresses[0].county,
                    :state => dependent1_addresses[0].state,
                    :zip => dependent1_addresses[0].zip,
                    :country_name => "United States of America",
                    :has_fixed_address => true
                  },
                  {
                    :kind => dependent1_addresses[1].kind,
                    :address_1 => dependent1_addresses[1].address_1,
                    :address_2 => dependent1_addresses[1].address_2,
                    :address_3 => dependent1_addresses[1].address_3,
                    :city => dependent1_addresses[1].city,
                    :county => dependent1_addresses[1].county,
                    :state => dependent1_addresses[1].state,
                    :zip => dependent1_addresses[1].zip,
                    :country_name => "United States of America",
                    :has_fixed_address => true
                  }
                ],
                :emails => [
                  {
                    :kind => dependent1_emails[0].kind,
                    :address => dependent1_emails[0].address
                  },
                  {
                    :kind => dependent1_emails[1].kind,
                    :address => dependent1_emails[1].address
                  }
                ],
                :phones => [
                  {
                    :kind => dependent1_phones[0].kind,
                    :country_code => "",
                    :area_code => dependent1_phones[0].area_code,
                    :number => dependent1_phones[0].number,
                    :extension => dependent1_phones[0].extension,
                    :primary => nil,
                    :full_phone_number => dependent1_phones[0].full_phone_number
                  },
                  {
                    :kind => dependent1_phones[1].kind,
                    :country_code => "",
                    :area_code => dependent1_phones[1].area_code,
                    :number => dependent1_phones[1].number,
                    :extension => dependent1_phones[1].extension,
                    :primary => nil,
                    :full_phone_number => dependent1_phones[1].full_phone_number
                  }
                ],
                :documents => [],
                :timestamp => {
                  :created_at => dependent1.created_at.to_datetime,
                  :modified_at => dependent1.updated_at.to_datetime
                }
              },
              :timestamp => {
                :created_at => family_member2.created_at.to_datetime,
                :modified_at => family_member2.updated_at.to_datetime
              }
            },
            {
              :hbx_id => "732022",
              :is_primary_applicant => false,
              :is_consent_applicant => false,
              :is_coverage_applicant => true,
              :is_active => true,
              :person => {
                :hbx_id => "732022",
                :person_name => {
                  :first_name => dependent2.first_name,
                  :middle_name => nil,
                  :last_name => dependent2.last_name,
                  :name_sfx => nil,
                  :name_pfx => nil,
                  :full_name => dependent2.full_name,
                  :alternate_name => nil
                },
                :person_demographics => {
                  :encrypted_ssn => nil,
                  :no_ssn => true,
                  :gender => dependent2.gender,
                  :dob => dependent2.dob,
                  :date_of_death => nil,
                  :dob_check => nil,
                  :is_incarcerated => false,
                  :ethnicity => nil,
                  :race => nil,
                  :tribal_id => nil,
                  :language_code => "en"
                },
                :person_health => {
                  :is_tobacco_user => "unknown",
                  :is_physically_disabled => nil
                },
                :no_dc_address => false,
                :no_dc_address_reason => "",
                :is_homeless => false,
                :is_temporarily_out_of_state => false,
                :age_off_excluded => false,
                :is_applying_for_assistance => nil,
                :is_active => true,
                :is_disabled => nil,
                :person_relationships => [],
                :consumer_role => nil,
                :resident_role => nil,
                :individual_market_transitions => [],
                :verification_types => [],
                :user => {},
                :addresses => [
                  {
                    :kind => dependent2_addresses[0].kind,
                    :address_1 => dependent2_addresses[0].address_1,
                    :address_2 => dependent2_addresses[0].address_2,
                    :address_3 => dependent2_addresses[0].address_3,
                    :city => dependent2_addresses[0].city,
                    :county => dependent2_addresses[0].county,
                    :state => dependent2_addresses[0].state,
                    :zip => dependent2_addresses[0].zip,
                    :country_name => "United States of America",
                    :has_fixed_address => true
                  },
                  {
                    :kind => dependent2_addresses[1].kind,
                    :address_1 => dependent2_addresses[1].address_1,
                    :address_2 => dependent2_addresses[1].address_2,
                    :address_3 => dependent2_addresses[1].address_3,
                    :city => dependent2_addresses[1].city,
                    :county => dependent2_addresses[1].county,
                    :state => dependent2_addresses[1].state,
                    :zip => dependent2_addresses[1].zip,
                    :country_name => "United States of America",
                    :has_fixed_address => true
                  }
                ],
                :emails => [
                  {
                    :kind => dependent2_emails[0].kind,
                    :address => dependent2_emails[0].address
                  },
                  {
                    :kind => dependent2_emails[1].kind,
                    :address => dependent2_emails[1].address
                  }
                ],

                :phones => [
                  {
                    :kind => dependent2_phones[0].kind,
                    :country_code => "",
                    :area_code => dependent2_phones[0].area_code,
                    :number => dependent2_phones[0].number,
                    :extension => dependent2_phones[0].extension,
                    :primary => nil,
                    :full_phone_number => dependent2_phones[0].full_phone_number
                  },
                  {
                    :kind => dependent2_phones[1].kind,
                    :country_code => "",
                    :area_code => dependent2_phones[1].area_code,
                    :number => dependent2_phones[1].number,
                    :extension => dependent2_phones[1].extension,
                    :primary => nil,
                    :full_phone_number => dependent2_phones[1].full_phone_number
                  }
                ],
                :documents => [],
                :timestamp => {
                  :created_at => dependent2.created_at.to_datetime,
                  :modified_at => dependent2.updated_at.to_datetime
                }
              },
              :timestamp => {
                :created_at => family_member3.created_at.to_datetime,
                :modified_at => family_member3.updated_at.to_datetime
              }
            }
          ],
          :households => [{
            :start_date => TimeKeeper.date_of_record,
            :end_date => nil,
            :is_active => true,
            :irs_groups => [{
              :hbx_id => nil,
              :start_on => TimeKeeper.date_of_record,
              :end_on => nil, :is_active => true
            }],
            :tax_households => [],
            :coverage_households => [
              {
                :is_immediate_family => true,
                :is_determination_split_household => false,
                :submitted_at => nil,
                :aasm_state => "applicant"
              },
              {
                :is_immediate_family => false,
                :is_determination_split_household => false,
                :submitted_at => nil,
                :aasm_state => "applicant"
              }
            ]
          }],
          :renewal_consent_through_year => 2017,
          :special_enrollment_periods => [],
          :payment_transactions => [],
          :magi_medicaid_applications => [
            {
              :applicants => [
                {
                  :addresses => [],
                  :age_of_applicant => 49,
                  :attestation => {
                    :is_incarcerated => false,
                    :is_self_attested_blind => false,
                    :is_self_attested_disabled => false,
                    :is_self_attested_long_term_care => false
                  },
                  :benchmark_premium => {
                    :health_only_lcsp_premiums => [
                      {:cost => 198.86, :member_identifier => "732020", :monthly_premium => 198.86, :product_id => product.id},
                      {:cost => 198.86, :member_identifier => "732021", :monthly_premium => 198.86, :product_id => product.id},
                      {:cost => 198.86, :member_identifier => "732022", :monthly_premium => 198.86, :product_id => product.id}
                    ],
                    :health_only_slcsp_premiums => [
                      {:cost => 198.86, :member_identifier => "732020", :monthly_premium => 198.86, :product_id => product.id},
                      {:cost => 198.86, :member_identifier => "732021", :monthly_premium => 198.86, :product_id => product.id},
                      {:cost => 198.86, :member_identifier => "732022", :monthly_premium => 198.86, :product_id => product.id}
                    ]
                  },
                  :benefits => [],
                  :citizenship_immigration_status_information => {
                    :citizen_status => nil,
                    :is_lawful_presence_self_attested => false,
                    :is_resident_post_092296 => false
                  },
                  :claimed_as_tax_dependent_by => nil,
                  :deductions => [],
                  :demographic => {
                    :dob => primary_applicant.dob,
                    :ethnicity => nil,
                    :gender => "Male",
                    :is_veteran_or_active_military => false,
                    :is_vets_spouse_or_child => false,
                    :race => nil
                  },
                  :emails => [],
                  :evidences => [],
                  :family_member_reference => {
                    :family_member_hbx_id => "732020",
                    :first_name => nil,
                    :is_primary_family_member => true,
                    :last_name => nil,
                    :person_hbx_id => "732020"
                  },
                  :foster_care => {
                    :age_left_foster_care => 0,
                    :foster_care_us_state => nil,
                    :had_medicaid_during_foster_care => false,
                    :is_former_foster_care => false
                  },
                  :had_prior_insurance => false,
                  :has_daily_living_help => false,
                  :has_deductions => false,
                  :has_eligible_health_coverage => false,
                  :has_enrolled_health_coverage => false,
                  :has_insurance => false,
                  :has_job_income => false,
                  :has_other_income => false,
                  :has_self_employment_income => false,
                  :has_state_health_benefit => false,
                  :has_unemployment_income => false,
                  :hours_worked_per_week => 0,
                  :identifying_information => {
                    :encrypted_ssn => nil,
                    :has_ssn => "0"
                  },
                  :incomes => [],
                  :is_applying_coverage => true,
                  :is_claimed_as_dependent_by_non_applicant => false,
                  :is_claimed_as_tax_dependent => false,
                  :is_consent_applicant => false,
                  :is_consumer_role => true,
                  :is_currently_enrolled_in_health_plan => false,
                  :is_filing_as_head_of_household => false,
                  :is_five_year_bar_met => false,
                  :is_forty_quarters => false,
                  :is_homeless => false,
                  :is_joint_tax_filing => false,
                  :is_medicare_eligible => false,
                  :is_primary_applicant => true,
                  :is_primary_caregiver => false,
                  :is_refugee => false,
                  :is_required_to_file_taxes => false,
                  :is_resident_role => false,
                  :is_self_attested_long_term_care => false,
                  :is_ssn_applied => false,
                  :is_subject_to_five_year_bar => false,
                  :is_temporarily_out_of_state => false,
                  :is_trafficking_victim => false,
                  :job_coverage_end_date => nil,
                  :job_coverage_ended_in_past_3_months => false,
                  :medicaid_and_chip => {
                    :denied_on => nil,
                    :ended_as_change_in_eligibility => false,
                    :hh_income_or_size_changed => false,
                    :immigration_status_changed_since_ineligibility => false,
                    :ineligible_due_to_immigration_in_last_5_years => false,
                    :medicaid_or_chip_coverage_end_date => nil,
                    :not_eligible_in_last_90_days => false
                  },
                  :mitc_income => {
                    :adjusted_gross_income => 0.0,
                    :alimony => 0,
                    :amount => 0,
                    :capital_gain_or_loss => 0,
                    :deductible_part_of_self_employment_tax => 0,
                    :farm_income_or_loss => 0,
                    :ira_deduction => 0,
                    :magi_deductions => 0,
                    :other_income => 0,
                    :other_magi_eligible_income => 0,
                    :pensions_and_annuities_taxable_amount => 0,
                    :student_loan_interest_deduction => 0,
                    :tax_exempt_interest => 0,
                    :taxable_interest => 0,
                    :taxable_refunds => 0,
                    :tution_and_fees => 0,
                    :unemployment_compensation => 0
                  },
                  :mitc_is_required_to_file_taxes => false,
                  :mitc_relationships => [],
                  :moved_on_or_after_welfare_reformed_law => false,
                  :name => {:first_name => nil, :last_name => nil, :middle_name => nil, :name_pfx => nil, :name_sfx => nil},
                  :native_american_information => {:indian_tribe_member => nil, :tribal_id => nil},
                  :need_help_paying_bills => false,
                  :non_ssn_apply_reason => nil,
                  :other_health_service => {:has_received => false, :is_eligible => false},
                  :person_hbx_id => "732020",
                  :phones => [],
                  :pregnancy_information => {
                    :expected_children_count => 0,
                    :is_enrolled_on_medicaid => false,
                    :is_post_partum_period => false,
                    :is_pregnant => false,
                    :pregnancy_due_on => nil,
                    :pregnancy_end_on => nil
                  },
                  :prior_insurance_end_date => nil,
                  :student => {
                    :is_student => false,
                    :student_kind => nil,
                    :student_school_kind => nil,
                    :student_status_end_on => nil
                  },
                  :tax_filer_kind => "tax_filer",
                  :vlp_document => nil
                },
                {
                  :addresses => [],
                  :age_of_applicant => 49,
                  :attestation => {
                    :is_incarcerated => false,
                    :is_self_attested_blind => false,
                    :is_self_attested_disabled => false,
                    :is_self_attested_long_term_care => false
                  },
                  :benchmark_premium => {
                    :health_only_lcsp_premiums => [
                      {:cost => 198.86, :member_identifier => "732020", :monthly_premium => 198.86, :product_id => product.id},
                      {:cost => 198.86, :member_identifier => "732021", :monthly_premium => 198.86, :product_id => product.id},
                      {:cost => 198.86, :member_identifier => "732022", :monthly_premium => 198.86, :product_id => product.id}
                    ],
                    :health_only_slcsp_premiums => [
                      {:cost => 198.86, :member_identifier => "732020", :monthly_premium => 198.86, :product_id => product.id},
                      {:cost => 198.86, :member_identifier => "732021", :monthly_premium => 198.86, :product_id => product.id},
                      {:cost => 198.86, :member_identifier => "732022", :monthly_premium => 198.86, :product_id => product.id}
                    ]
                  },
                  :benefits => [],
                  :citizenship_immigration_status_information => {
                    :citizen_status => nil,
                    :is_lawful_presence_self_attested => false,
                    :is_resident_post_092296 => false
                  },
                  :claimed_as_tax_dependent_by => nil,
                  :deductions => [],
                  :demographic => {
                    :dob => primary_applicant.dob,
                    :ethnicity => nil,
                    :gender => "Male",
                    :is_veteran_or_active_military => false,
                    :is_vets_spouse_or_child => false,
                    :race => nil
                  },
                  :emails => [],
                  :evidences => [],
                  :family_member_reference => {
                    :family_member_hbx_id => "732021",
                    :first_name => nil,
                    :is_primary_family_member => false,
                    :last_name => nil,
                    :person_hbx_id => "732021"
                  },
                  :foster_care => {
                    :age_left_foster_care => 0,
                    :foster_care_us_state => nil,
                    :had_medicaid_during_foster_care => false,
                    :is_former_foster_care => false
                  },
                  :had_prior_insurance => false,
                  :has_daily_living_help => false,
                  :has_deductions => false,
                  :has_eligible_health_coverage => false,
                  :has_enrolled_health_coverage => false,
                  :has_insurance => false,
                  :has_job_income => false,
                  :has_other_income => false,
                  :has_self_employment_income => false,
                  :has_state_health_benefit => false,
                  :has_unemployment_income => false,
                  :hours_worked_per_week => 0,
                  :identifying_information => {:encrypted_ssn => nil, :has_ssn => "0"},
                  :incomes => [],
                  :is_applying_coverage => true,
                  :is_claimed_as_dependent_by_non_applicant => false,
                  :is_claimed_as_tax_dependent => false,
                  :is_consent_applicant => false,
                  :is_consumer_role => true,
                  :is_currently_enrolled_in_health_plan => false,
                  :is_filing_as_head_of_household => false,
                  :is_five_year_bar_met => false,
                  :is_forty_quarters => false,
                  :is_homeless => false,
                  :is_joint_tax_filing => false,
                  :is_medicare_eligible => false,
                  :is_primary_applicant => false,
                  :is_primary_caregiver => false,
                  :is_refugee => false,
                  :is_required_to_file_taxes => false,
                  :is_resident_role => false,
                  :is_self_attested_long_term_care => false,
                  :is_ssn_applied => false,
                  :is_subject_to_five_year_bar => false,
                  :is_temporarily_out_of_state => false,
                  :is_trafficking_victim => false,
                  :job_coverage_end_date => nil,
                  :job_coverage_ended_in_past_3_months => false,
                  :medicaid_and_chip => {
                    :denied_on => nil,
                    :ended_as_change_in_eligibility => false,
                    :hh_income_or_size_changed => false,
                    :immigration_status_changed_since_ineligibility => false,
                    :ineligible_due_to_immigration_in_last_5_years => false,
                    :medicaid_or_chip_coverage_end_date => nil,
                    :not_eligible_in_last_90_days => false
                  },
                  :mitc_income => {
                    :adjusted_gross_income => 0.0,
                    :alimony => 0,
                    :amount => 0,
                    :capital_gain_or_loss => 0,
                    :deductible_part_of_self_employment_tax => 0,
                    :farm_income_or_loss => 0,
                    :ira_deduction => 0,
                    :magi_deductions => 0,
                    :other_income => 0,
                    :other_magi_eligible_income => 0,
                    :pensions_and_annuities_taxable_amount => 0,
                    :student_loan_interest_deduction => 0,
                    :tax_exempt_interest => 0,
                    :taxable_interest => 0,
                    :taxable_refunds => 0,
                    :tution_and_fees => 0,
                    :unemployment_compensation => 0
                  },
                  :mitc_is_required_to_file_taxes => false,
                  :mitc_relationships => [],
                  :moved_on_or_after_welfare_reformed_law => false,
                  :name => {:first_name => nil, :last_name => nil, :middle_name => nil, :name_pfx => nil, :name_sfx => nil},
                  :native_american_information => {:indian_tribe_member => nil, :tribal_id => nil},
                  :need_help_paying_bills => false,
                  :non_ssn_apply_reason => nil,
                  :other_health_service => {:has_received => false, :is_eligible => false},
                  :person_hbx_id => "732021",
                  :phones => [],
                  :pregnancy_information => {

                    :expected_children_count => 0,
                    :is_enrolled_on_medicaid => false,
                    :is_post_partum_period => false,
                    :is_pregnant => false,
                    :pregnancy_due_on => nil,
                    :pregnancy_end_on => nil
                  },
                  :prior_insurance_end_date => nil,
                  :student => {:is_student => false, :student_kind => nil, :student_school_kind => nil, :student_status_end_on => nil},
                  :tax_filer_kind => "tax_filer",
                  :vlp_document => nil
                },
                {
                  :addresses => [],
                  :age_of_applicant => 49,
                  :attestation => {
                    :is_incarcerated => false,
                    :is_self_attested_blind => false,
                    :is_self_attested_disabled => false,
                    :is_self_attested_long_term_care => false
                  },
                  :benchmark_premium => {
                    :health_only_lcsp_premiums => [
                      {:cost => 198.86, :member_identifier => "732020", :monthly_premium => 198.86, :product_id => product.id},
                      {:cost => 198.86, :member_identifier => "732021", :monthly_premium => 198.86, :product_id => product.id},
                      {:cost => 198.86, :member_identifier => "732022", :monthly_premium => 198.86, :product_id => product.id}
                    ],
                    :health_only_slcsp_premiums => [
                      {:cost => 198.86, :member_identifier => "732020", :monthly_premium => 198.86, :product_id => product.id},
                      {:cost => 198.86, :member_identifier => "732021", :monthly_premium => 198.86, :product_id => product.id},
                      {:cost => 198.86, :member_identifier => "732022", :monthly_premium => 198.86, :product_id => product.id}
                    ]
                  },
                  :benefits => [],
                  :citizenship_immigration_status_information => {
                    :citizen_status => nil,
                    :is_lawful_presence_self_attested => false,
                    :is_resident_post_092296 => false
                  },
                  :claimed_as_tax_dependent_by => nil,
                  :deductions => [],
                  :demographic => {
                    :dob => primary_applicant.dob,
                    :ethnicity => nil,
                    :gender => "Female",
                    :is_veteran_or_active_military => false,
                    :is_vets_spouse_or_child => false,
                    :race => nil
                  },
                  :emails => [],
                  :evidences => [],
                  :family_member_reference => {
                    :family_member_hbx_id => "732022",
                    :first_name => nil,
                    :is_primary_family_member => false,
                    :last_name => nil,
                    :person_hbx_id => "732022"
                  },
                  :foster_care => {
                    :age_left_foster_care => 0,
                    :foster_care_us_state => nil,
                    :had_medicaid_during_foster_care => false,
                    :is_former_foster_care => false
                  },
                  :had_prior_insurance => false,
                  :has_daily_living_help => false,
                  :has_deductions => false,
                  :has_eligible_health_coverage => false,
                  :has_enrolled_health_coverage => false,
                  :has_insurance => false,
                  :has_job_income => false,
                  :has_other_income => false,
                  :has_self_employment_income => false,
                  :has_state_health_benefit => false,
                  :has_unemployment_income => false,
                  :hours_worked_per_week => 0,
                  :identifying_information => {:encrypted_ssn => nil, :has_ssn => "0"},
                  :incomes => [],
                  :is_applying_coverage => true,
                  :is_claimed_as_dependent_by_non_applicant => false,
                  :is_claimed_as_tax_dependent => false,
                  :is_consent_applicant => false,
                  :is_consumer_role => true,
                  :is_currently_enrolled_in_health_plan => false,
                  :is_filing_as_head_of_household => false,
                  :is_five_year_bar_met => false,
                  :is_forty_quarters => false,
                  :is_homeless => false,
                  :is_joint_tax_filing => false,
                  :is_medicare_eligible => false,
                  :is_primary_applicant => false,
                  :is_primary_caregiver => false,
                  :is_refugee => false,
                  :is_required_to_file_taxes => false,
                  :is_resident_role => false,
                  :is_self_attested_long_term_care => false,
                  :is_ssn_applied => false,
                  :is_subject_to_five_year_bar => false,
                  :is_temporarily_out_of_state => false,
                  :is_trafficking_victim => false,
                  :job_coverage_end_date => nil,
                  :job_coverage_ended_in_past_3_months => false,
                  :medicaid_and_chip => {
                    :denied_on => nil,
                    :ended_as_change_in_eligibility => false,
                    :hh_income_or_size_changed => false,
                    :immigration_status_changed_since_ineligibility => false,
                    :ineligible_due_to_immigration_in_last_5_years => false,
                    :medicaid_or_chip_coverage_end_date => nil,
                    :not_eligible_in_last_90_days => false
                  },
                  :mitc_income => {
                    :adjusted_gross_income => 0.0,
                    :alimony => 0,
                    :amount => 0,
                    :capital_gain_or_loss => 0,
                    :deductible_part_of_self_employment_tax => 0,
                    :farm_income_or_loss => 0,
                    :ira_deduction => 0,
                    :magi_deductions => 0,
                    :other_income => 0,
                    :other_magi_eligible_income => 0,
                    :pensions_and_annuities_taxable_amount => 0,
                    :student_loan_interest_deduction => 0,
                    :tax_exempt_interest => 0,
                    :taxable_interest => 0,
                    :taxable_refunds => 0,
                    :tution_and_fees => 0,
                    :unemployment_compensation => 0
                  },
                  :mitc_is_required_to_file_taxes => false,
                  :mitc_relationships => [],
                  :moved_on_or_after_welfare_reformed_law => false,
                  :name => {
                    :first_name => nil,
                    :last_name => nil,
                    :middle_name => nil,
                    :name_pfx => nil,
                    :name_sfx => nil
                  },
                  :native_american_information => {
                    :indian_tribe_member => nil,
                    :tribal_id => nil
                  },
                  :need_help_paying_bills => false,
                  :non_ssn_apply_reason => nil,
                  :other_health_service => {
                    :has_received => false,
                    :is_eligible => false
                  },
                  :person_hbx_id => "732022",
                  :phones => [],
                  :pregnancy_information => {
                    :expected_children_count => 0,
                    :is_enrolled_on_medicaid => false,
                    :is_post_partum_period => false,
                    :is_pregnant => false,
                    :pregnancy_due_on => nil,
                    :pregnancy_end_on => nil
                  },
                  :prior_insurance_end_date => nil,
                  :student => {
                    :is_student => false,
                    :student_kind => nil,
                    :student_school_kind => nil,
                    :student_status_end_on => nil
                  },
                  :tax_filer_kind => "tax_filer",
                  :vlp_document => nil
                }
              ],
              :aptc_effective_date => application.effective_date,
              :assistance_year => 2021,
              :family_reference => {
                :hbx_id => family.hbx_assigned_id.to_s
              },
              :hbx_id => "830293",
              :is_renewal_authorized => true,
              :is_ridp_verified => true,
              :mitc_households => [{
                :household_id => "1",
                :people => [{:person_id => "732020"}]
              }],
              :mitc_tax_returns => [],
              :notice_options => {
                :send_eligibility_notices => true,
                :send_open_enrollment_notices => false
              },
              :oe_start_on => oe_start_on,
              :relationships => [],
              :renewal_consent_through_year => nil,
              :submitted_at => application.submitted_at,
              :tax_households => [],
              :us_state => "DC",
              :years_to_renew => nil
            }
          ],
          :documents => [],
          :timestamp => {:created_at => family.created_at.to_datetime, :modified_at => family.updated_at.to_datetime},
          :broker_accounts => [],
          :irs_groups => [{
            :hbx_id => nil, :start_on => TimeKeeper.date_of_record, :end_on => nil, :is_active => true
          }]
        }
      )
    end
  end

  describe '#transform_applications' do

    subject { FinancialAssistance::Operations::Transformers::FamilyTo::Cv3Family.new.transform_applications(family) }
    before do
      create_instate_addresses
      create_relationships
      application.save!
      allow(::FinancialAssistance::Operations::Applications::Transformers::ApplicationTo::Cv3Application).to receive_message_chain('new.call').with(application).and_return(::Dry::Monads::Result::Success.new(application))
    end

    context "when all applicants are valid" do

      it "should successfully submit a cv3 application and get a response back" do
        expect(subject).to include(application)
      end
    end

    context "when a family member is deleted" do
      before do
        family.family_members.last.delete
        family.reload
      end

      it "should ignore the application and return an empty array" do
        expect(subject).to be_empty
      end
    end
  end
end
