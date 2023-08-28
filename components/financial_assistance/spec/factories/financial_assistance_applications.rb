# frozen_string_literal: true

FactoryBot.define do
  factory :application, class: "::FinancialAssistance::Application" do

  end

  factory :financial_assistance_application, class: "::FinancialAssistance::Application" do
    assistance_year { TimeKeeper.date_of_record.year }
    submitted_at {2.months.ago}
    aasm_state { "determined" }
    parent_living_out_of_home_terms { false }

    trait :with_family_and_effective_date do
      family_id { 1 }
      effective_date { Date.today }
    end

    trait :with_applicants do
      applicants do
        [
          FactoryBot.build(:financial_assistance_applicant, :male, :with_home_address, application: self, first_name: 'john', last_name: 'adams', family_member_id: BSON::ObjectId.new, dob: 40.years.ago, ssn: '472743442', is_primary_applicant: true, citizen_status: 'us_citizen'),
          FactoryBot.build(:financial_assistance_applicant, :with_ssn, :female, :spouse, :with_home_address, application: self, first_name: 'sarah', last_name: 'adams', dob: 35.years.ago, citizen_status: 'us_citizen'),
          FactoryBot.build(:financial_assistance_applicant, :with_ssn, :female, :child, :with_home_address, application: self, first_name: 'emma', last_name: 'adams', dob: 10.years.ago, citizen_status: 'us_citizen'),
          FactoryBot.build(:financial_assistance_applicant, :with_ssn, :male, :child, :with_home_address, application: self, first_name: 'marvin', last_name: 'adams', dob: 7.years.ago, citizen_status: 'alien_lawfully_present')
        ]
      end
    end

    trait :cv3_compatible do

    end

      # before :create do
        # person = FactoryBot.create(:person)
        # @family = FactoryBot.create(:family, :with_primary_family_member, person: person)

        # premiums_hash = { [person.hbx_id] => { :health_only => {person.hbx_id => [{ :cost => 200.0, :member_identifier => person.hbx_id, :monthly_premium => 200.0}] } } }
        # slcsp_info = { person.hbx_id => { :health_only_slcsp_premiums => { :cost => 200.0, :member_identifier => person.hbx_id, :monthly_premium => 200.0 } } }
        # lcsp_info = { person.hbx_id => { :health_only_lcsp_premiums => { :cost => 100.0, :member_identifier => person.hbx_id, :monthly_premium => 100.0 } } }

        # include braces?
        # possibly inject prior to initialization of factory
        # premiums_double = double(:success => premiums_hash)
        # slcsp_double = double(:success => slcsp_info)
        # lcsp_double = double(:success => lcsp_info)

        # fetch_double = double(:new => double(call: premiums_double))
        # fetch_slcsp_double = double(:new => double(call: slcsp_double))
        # fetch_lcsp_double = double(:new => double(call: lcsp_double))
        # hbx_profile = FactoryBot.create(:hbx_profile)
        # benefit_sponsorship = FactoryBot.create(:benefit_sponsorship, :open_enrollment_coverage_period, hbx_profile: hbx_profile)
        # benefit_coverage_period = hbx_profile.benefit_sponsorship.benefit_coverage_periods.first

        # include braces?
        # premiums_double = double(:success => premiums_hash)
        # slcsp_double = double(:success => slcsp_info)
        # lcsp_double = double(:success => lcsp_info)

        # fetch_double = double(:new => double(call: premiums_double))
        # fetch_slcsp_double = double(:new => double(call: slcsp_double))
        # # fetch_lcsp_double = double(:new => double(call: lcsp_double))
        # hbx_profile = FactoryBot.create(:hbx_profile)
        # benefit_sponsorship = FactoryBot.create(:benefit_sponsorship, :open_enrollment_coverage_period, hbx_profile: hbx_profile)
        # benefit_coverage_period = hbx_profile.benefit_sponsorship.benefit_coverage_periods.first

        # before do
        #   allow(HbxProfile).to receive(:current_hbx).and_return hbx_profile
        #   allow(hbx_profile).to receive(:benefit_sponsorship).and_return benefit_sponsorship
        #   allow(benefit_sponsorship).to receive(:current_benefit_period).and_return(benefit_coverage_period)
        #   stub_const('::Operations::Products::Fetch', fetch_double)
        #   stub_const('::Operations::Products::FetchSlcsp', fetch_slcsp_double)
        #   stub_const('::Operations::Products::FetchLcsp', fetch_lcsp_double)
        #   allow(premiums_double).to receive(:failure?).and_return(false)
        #   allow(slcsp_double).to receive(:failure?).and_return(false)
        #   allow(lcsp_double).to receive(:failure?).and_return(false)
        # end

        # application
        # family
        # households
        # tax_households
        # tax_household_members
        #  -> csr
      # end

      # Associations needed in factory
      # application
      # -> eligibility_determinations
      # -> applicants
      #   -> income_evidence
      # -> family
      #   -> person (needs primary member to be valid)
      #   -> family_members
      #   -> tax_households
      #     -> tax_household_members 

      # Other reqs for valid cv3 application form -- can maybe be build_stubbed?
      # hbx_profile
      #   -> benefit_sponsorship 
      #     -> benefit_coverage_period

      # family_id { 1 }
      # aasm_state { 'submitted' }
      # hbx_id { '830293' }
      # effective_date { TimeKeeper.date_of_record.beginning_of_year }

      # applicants do
      #   [FactoryBot.create(:applicant,
      #                     :with_student_information,
      #                     first_name: person.first_name,
      #                     last_name: person.last_name,
      #                     dob: person.dob,
      #                     gender: person.gender,
      #                     ssn: '000356837',
      #                     # ssn: person.ssn,
      #                     application: application,
      #                     ethnicity: nil,
      #                     is_primary_applicant: true,
      #                     person_hbx_id: person.hbx_id,
      #                     is_self_attested_blind: false,
      #                     is_applying_coverage: applicant1_is_applying_coverage,
      #                     is_required_to_file_taxes: true,
      #                     is_filing_as_head_of_household: true,
      #                     is_pregnant: false,
      #                     is_primary_caregiver: true,
      #                     is_primary_caregiver_for: [],
      #                     has_job_income: applicant1_has_job_income,
      #                     has_self_employment_income: applicant1_has_self_employment_income,
      #                     has_unemployment_income: applicant1_has_unemployment_income,
      #                     has_other_income: applicant1_has_other_income,
      #                     has_deductions: applicant1_has_deductions,
      #                     is_self_attested_disabled: true,
      #                     is_physically_disabled: false,
      #                     citizen_status: 'us_citizen',
      #                     has_enrolled_health_coverage: applicant1_has_enrolled_health_coverage,
      #                     has_eligible_health_coverage: applicant1_has_eligible_health_coverage,
      #                     has_eligible_medicaid_cubcare: false,
      #                     is_claimed_as_tax_dependent: false,
      #                     is_incarcerated: false,
      #                     net_annual_income: 10_078.90,
      #                     is_post_partum_period: false,
      #                     is_veteran_or_active_military: true)]
      #   end

      # after :create do |financial_assistance_application|
      #   FactoryBot.create(:financial_assistance_eligibility_determination, application: financial_assistance_application)
      # end
    trait :with_attestations do
      medicaid_terms { true }
      medicaid_insurance_collection_terms { true }
      submission_terms { true }
      report_change_terms { true }
    end

    after(:create) do |application, _evaluator|
      application.non_primary_applicants.each{|applicant| application.ensure_relationship_with_primary(applicant, applicant.relationship) }
      application.save
    end
  end
end
