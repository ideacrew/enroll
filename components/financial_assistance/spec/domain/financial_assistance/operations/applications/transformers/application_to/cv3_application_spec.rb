# frozen_string_literal: true

require 'rails_helper'
require "#{FinancialAssistance::Engine.root}/spec/dummy/app/domain/operations/individual/open_enrollment_start_on"

RSpec.describe ::FinancialAssistance::Operations::Applications::Transformers::ApplicationTo::Cv3Application, dbclean: :after_each do
  let!(:person) { FactoryBot.create(:person, hbx_id: "732020")}
  let!(:person2) { FactoryBot.create(:person, hbx_id: "732021") }
  let!(:person3) { FactoryBot.create(:person, hbx_id: "732022") }
  let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person)}
  let!(:application) { FactoryBot.create(:financial_assistance_application, family_id: family.id, aasm_state: 'submitted', hbx_id: "830293", effective_date: DateTime.new(2021,1,1,4,5,6)) }
  let!(:applicant) do
    applicant = FactoryBot.create(:applicant,
                                  :with_student_information,
                                  first_name: person.first_name,
                                  last_name: person.last_name,
                                  dob: person.dob,
                                  gender: person.gender,
                                  ssn: person.ssn,
                                  application: application,
                                  ethnicity: [],
                                  is_primary_applicant: true,
                                  person_hbx_id: person.hbx_id,
                                  is_self_attested_blind: false,
                                  is_applying_coverage: true,
                                  is_required_to_file_taxes: true,
                                  is_filing_as_head_of_household: true,
                                  is_pregnant: false,
                                  has_job_income: false,
                                  has_self_employment_income: false,
                                  has_unemployment_income: false,
                                  has_other_income: false,
                                  has_deductions: false,
                                  is_self_attested_disabled: true,
                                  is_physically_disabled: false,
                                  citizen_status: 'us_citizen',
                                  has_enrolled_health_coverage: false,
                                  has_eligible_health_coverage: false,
                                  has_eligible_medicaid_cubcare: false,
                                  is_claimed_as_tax_dependent: false,
                                  is_incarcerated: false,
                                  net_annual_income: 10_078.90,
                                  is_post_partum_period: false)
    applicant
  end

  let!(:eligibility_determination) { FactoryBot.create(:financial_assistance_eligibility_determination, application: application) }

  # let!(:products) { FactoryBot.create_list(:benefit_markets_products_health_products_health_product, 5, :silver) }

  let(:premiums_hash) do
    {
      [person.hbx_id] => {:health_only => {person.hbx_id => [{:cost => 200.0, :member_identifier => person.hbx_id, :monthly_premium => 200.0}]}},
      [person2.hbx_id] => {:health_only => {person2.hbx_id => [{:cost => 200.0, :member_identifier => person2.hbx_id, :monthly_premium => 200.0}]}},
      [person3.hbx_id] => {:health_only => {person3.hbx_id => [{:cost => 200.0, :member_identifier => person3.hbx_id, :monthly_premium => 200.0}]}}
    }
  end

  let(:slcsp_info) do
    {
      person.hbx_id => {:health_only_slcsp_premiums => {:cost => 200.0, :member_identifier => person.hbx_id, :monthly_premium => 200.0}},
      person2.hbx_id => {:health_only_slcsp_premiums => {:cost => 200.0, :member_identifier => person2.hbx_id, :monthly_premium => 200.0}},
      person3.hbx_id => {:health_only_slcsp_premiums => {:cost => 200.0, :member_identifier => person3.hbx_id, :monthly_premium => 200.0}}
    }
  end

  let(:lcsp_info) do
    {
      person.hbx_id => {:health_only_lcsp_premiums => {:cost => 100.0, :member_identifier => person.hbx_id, :monthly_premium => 100.0}},
      person2.hbx_id => {:health_only_lcsp_premiums => {:cost => 100.0, :member_identifier => person2.hbx_id, :monthly_premium => 100.0}},
      person3.hbx_id => {:health_only_lcsp_premiums => {:cost => 100.0, :member_identifier => person3.hbx_id, :monthly_premium => 100.0}}
    }
  end

  let(:premiums_double) { double(:success => premiums_hash) }
  let(:slcsp_double) { double(:success => slcsp_info) }
  let(:lcsp_double) { double(:success => lcsp_info) }

  let(:fetch_double) { double(:new => double(call: premiums_double))}
  let(:fetch_slcsp_double) { double(:new => double(call: slcsp_double))}
  let(:fetch_lcsp_double) { double(:new => double(call: lcsp_double))}
  let(:hbx_profile) {FactoryBot.create(:hbx_profile)}
  let(:benefit_sponsorship) { FactoryBot.create(:benefit_sponsorship, :open_enrollment_coverage_period, hbx_profile: hbx_profile) }
  let(:benefit_coverage_period) { hbx_profile.benefit_sponsorship.benefit_coverage_periods.first }

  before do
    allow(HbxProfile).to receive(:current_hbx).and_return hbx_profile
    allow(hbx_profile).to receive(:benefit_sponsorship).and_return benefit_sponsorship
    allow(benefit_sponsorship).to receive(:current_benefit_period).and_return(benefit_coverage_period)
    stub_const('::Operations::Products::Fetch', fetch_double)
    stub_const('::Operations::Products::FetchSlcsp', fetch_slcsp_double)
    stub_const('::Operations::Products::FetchLcsp', fetch_lcsp_double)
    allow(premiums_double).to receive(:failure?).and_return(false)
    allow(slcsp_double).to receive(:failure?).and_return(false)
    allow(lcsp_double).to receive(:failure?).and_return(false)
  end

  describe 'When Application in draft state is passed' do
    let(:result) { subject.call(application) }

    before :each do
      application.update_attributes(aasm_state: "draft")
    end

    it 'should not pass' do
      expect(result.failure?).to be_truthy
    end
  end

  describe 'When Application is in submitted state' do
    let(:result) { subject.call(application) }

    before :each do
      applicant.update_attributes(person_hbx_id: person.hbx_id, citizen_status: 'alien_lawfully_present', eligibility_determination_id: eligibility_determination.id)
    end

    it 'should pass' do
      expect(result.success?).to be_truthy
      expect(result).to be_a(Dry::Monads::Result::Success)
      expect(result.value!).to be_a(Hash)
    end

    it 'should have oe date for year before effective date' do
      expect(result.value![:oe_start_on]).to eq benefit_coverage_period.open_enrollment_start_on
    end

    it 'should have notice_options with send_eligibility_notices set to true' do
      expect(result.value![:notice_options][:send_eligibility_notices]).to be_truthy
    end

    it 'should have notice_options with send_open_enrollment_notices set to false' do
      expect(result.value![:notice_options][:send_open_enrollment_notices]).to be_falsey
    end

    it 'should have applicant with person hbx_id' do
      expect(result.value![:applicants].first[:person_hbx_id]).to eq person.hbx_id
    end

    context 'application' do
      before do
        @application = result.success
      end

      it 'should not return nil for is_ridp_verified' do
        expect(@application[:is_ridp_verified]).not_to be_nil
      end

      it 'should not return nil for is_renewal_authorized' do
        expect(@application[:is_renewal_authorized]).not_to be_nil
      end

      it 'should return state abbreviation for us_state & cannot be nil' do
        expect(@application[:us_state]).not_to be_nil
      end

      it 'should not return nil for submitted_at' do
        expect(@application[:submitted_at]).not_to be_nil
      end
    end

    context 'applicant' do
      before do
        request_payload = result.success
        @applicant = request_payload[:applicants].first
      end

      it 'should not return nil for is_primary_applicant' do
        expect(@applicant[:is_primary_applicant]).not_to be_nil
      end

      it 'should not return nil for is_consumer_role' do
        expect(@applicant[:is_consumer_role]).not_to be_nil
      end

      it 'should not return nil for is_resident_role' do
        expect(@applicant[:is_resident_role]).not_to be_nil
      end

      it 'should not return nil for is_applying_coverage' do
        expect(@applicant[:is_applying_coverage]).not_to be_nil
      end

      it 'should not return nil for is_consent_applicant' do
        expect(@applicant[:is_consent_applicant]).not_to be_nil
      end

      it 'should not return nil for is_required_to_file_taxes' do
        expect(@applicant[:is_required_to_file_taxes]).not_to be_nil
      end

      it 'should not return nil for is_joint_tax_filing' do
        expect(@applicant[:is_joint_tax_filing]).not_to be_nil
      end

      it 'should not return nil for is_claimed_as_tax_dependent' do
        expect(@applicant[:is_claimed_as_tax_dependent]).not_to be_nil
      end

      it 'should not return nil for is_refugee' do
        expect(@applicant[:is_refugee]).not_to be_nil
      end

      it 'should not return nil for is_trafficking_victim' do
        expect(@applicant[:is_trafficking_victim]).not_to be_nil
      end

      it 'should not return nil for is_subject_to_five_year_bar' do
        expect(@applicant[:is_subject_to_five_year_bar]).not_to be_nil
      end

      it 'should not return nil for is_five_year_bar_met' do
        expect(@applicant[:is_five_year_bar_met]).not_to be_nil
      end

      it 'should not return nil for is_forty_quarters' do
        expect(@applicant[:is_forty_quarters]).not_to be_nil
      end

      it 'should not return nil for is_ssn_applied' do
        expect(@applicant[:is_ssn_applied]).not_to be_nil
      end

      it 'should not return nil for moved_on_or_after_welfare_reformed_law' do
        expect(@applicant[:moved_on_or_after_welfare_reformed_law]).not_to be_nil
      end

      it 'should not return nil for is_currently_enrolled_in_health_plan' do
        expect(@applicant[:is_currently_enrolled_in_health_plan]).not_to be_nil
      end

      it 'should not return nil for has_daily_living_help' do
        expect(@applicant[:has_daily_living_help]).not_to be_nil
      end

      it 'should not return nil for need_help_paying_bills' do
        expect(@applicant[:need_help_paying_bills]).not_to be_nil
      end

      it 'should not return nil for has_job_income' do
        expect(@applicant[:has_job_income]).not_to be_nil
      end

      it 'should not return nil for has_self_employment_income' do
        expect(@applicant[:has_self_employment_income]).not_to be_nil
      end

      it 'should not return nil for has_unemployment_income' do
        expect(@applicant[:has_unemployment_income]).not_to be_nil
      end

      it 'should not return nil for has_other_income' do
        expect(@applicant[:has_other_income]).not_to be_nil
      end

      it 'should not return nil for has_deductions' do
        expect(@applicant[:has_deductions]).not_to be_nil
      end

      it 'should not return nil for has_enrolled_health_coverage' do
        expect(@applicant[:has_enrolled_health_coverage]).not_to be_nil
      end

      it 'should not return nil for has_eligible_health_coverage' do
        expect(@applicant[:has_eligible_health_coverage]).not_to be_nil
      end

      it 'should not return nil for job_coverage_ended_in_past_3_months' do
        expect(@applicant[:job_coverage_ended_in_past_3_months]).not_to be_nil
      end

      it 'should not return nil for is_temporarily_out_of_state' do
        expect(@applicant[:is_temporarily_out_of_state]).not_to be_nil
      end

      it 'should not return nil for is_homeless' do
        expect(@applicant[:is_homeless]).not_to be_nil
      end

      it 'should not return nil for has_received' do
        expect(@applicant[:other_health_service][:has_received]).not_to be_nil
      end

      it 'should not return nil for is_eligible' do
        expect(@applicant[:other_health_service][:is_eligible]).not_to be_nil
      end

      it 'should not return nil for is_primary_family_member' do
        expect(@applicant[:family_member_reference][:is_primary_family_member]).not_to be_nil
      end

      it 'should not return nil for is_resident_post_092296' do
        expect(@applicant[:citizenship_immigration_status_information][:is_resident_post_092296]).not_to be_nil
      end

      it 'should not return nil for is_lawful_presence_self_attested' do
        expect(@applicant[:citizenship_immigration_status_information][:is_lawful_presence_self_attested]).not_to be_nil
      end

      it 'should add is_self_attested_disabled' do
        expect(@applicant[:attestation][:is_self_attested_disabled]).to eq(applicant.is_physically_disabled)
        expect(@applicant[:attestation][:is_self_attested_disabled]).not_to eq(applicant.is_self_attested_disabled)
      end

      it 'should not return nil for not_eligible_in_last_90_days' do
        expect(@applicant[:medicaid_and_chip][:not_eligible_in_last_90_days]).not_to be_nil
      end

      it 'should not return nil for ended_as_change_in_eligibility' do
        expect(@applicant[:medicaid_and_chip][:ended_as_change_in_eligibility]).not_to be_nil
      end

      it 'should not return nil for hh_income_or_size_changed' do
        expect(@applicant[:medicaid_and_chip][:hh_income_or_size_changed]).not_to be_nil
      end

      it 'should not return nil for ineligible_due_to_immigration_in_last_5_years' do
        expect(@applicant[:medicaid_and_chip][:ineligible_due_to_immigration_in_last_5_years]).not_to be_nil
      end

      it 'should not return nil for immigration_status_changed_since_ineligibility' do
        expect(@applicant[:medicaid_and_chip][:immigration_status_changed_since_ineligibility]).not_to be_nil
      end

      it 'should not return nil for is_student' do
        expect(@applicant[:student][:is_student]).not_to be_nil
      end

      it 'should not return nil for is_pregnant' do
        expect(@applicant[:pregnancy_information][:is_pregnant]).not_to be_nil
      end

      it 'should not return nil for is_enrolled_on_medicaid' do
        expect(@applicant[:pregnancy_information][:is_enrolled_on_medicaid]).not_to be_nil
      end

      it 'should not return nil for is_post_partum_period' do
        expect(@applicant[:pregnancy_information][:is_post_partum_period]).not_to be_nil
      end

      it 'should not return nil for is_former_foster_care' do
        expect(@applicant[:foster_care][:is_former_foster_care]).not_to be_nil
      end

      it 'should not return nil for had_medicaid_during_foster_care' do
        expect(@applicant[:foster_care][:had_medicaid_during_foster_care]).not_to be_nil
      end

      it 'should not return nil for is_incarcerated' do
        expect(@applicant[:attestation][:is_incarcerated]).not_to be_nil
      end

      it 'should not return nil for is_self_attested_disabled' do
        expect(@applicant[:attestation][:is_self_attested_disabled]).not_to be_nil
      end

      it 'should not return nil for is_self_attested_blind' do
        expect(@applicant[:attestation][:is_self_attested_blind]).not_to be_nil
      end

      it 'should not return nil for is_self_attested_long_term_care' do
        expect(@applicant[:attestation][:is_self_attested_long_term_care]).not_to be_nil
      end

      it 'should not return nil for is_veteran_or_active_military' do
        expect(@applicant[:demographic][:is_veteran_or_active_military]).not_to be_nil
      end

      it 'should not return nil for is_vets_spouse_or_child' do
        expect(@applicant[:demographic][:is_vets_spouse_or_child]).not_to be_nil
      end
    end

    context 'mitc_income' do
      before do
        request_payload = result.success
        @mitc_income_hash = request_payload[:applicants].first[:mitc_income]
      end

      it 'should add adjusted_gross_income' do
        expect(@mitc_income_hash[:adjusted_gross_income]).to eq(applicant.net_annual_income.to_f)
      end
    end
  end

  context 'for renewal application' do
    let(:result) { subject.call(application) }

    before :each do
      family.family_members.first.update_attributes(person_id: person.id)
      applicant.update_attributes(person_hbx_id: person.hbx_id, citizen_status: 'alien_lawfully_present', eligibility_determination_id: eligibility_determination.id)
      application.workflow_state_transitions << WorkflowStateTransition.new(
        from_state: 'renewal_draft',
        to_state: 'submitted'
      )
      application.save!
    end

    it 'should have notice_options with send_eligibility_notices set to false' do
      expect(result.value![:notice_options][:send_eligibility_notices]).to be_falsey
    end

    it 'should have notice_options with send_open_enrollment_notices set to true' do
      expect(result.value![:notice_options][:send_open_enrollment_notices]).to be_truthy
    end
  end

  context 'for relationships' do
    let!(:family_member2) { FactoryBot.create(:family_member, person: person2, family: family) }
    let!(:applicant2) do
      FactoryBot.create(:applicant,
                        first_name: person2.first_name,
                        last_name: person2.last_name,
                        dob: person2.dob,
                        gender: person2.gender,
                        ssn: person2.ssn,
                        application: application,
                        eligibility_determination_id: eligibility_determination.id,
                        ethnicity: [],
                        person_hbx_id: person2.hbx_id,
                        is_self_attested_blind: false,
                        is_applying_coverage: true,
                        is_required_to_file_taxes: true,
                        is_pregnant: false,
                        has_job_income: false,
                        has_self_employment_income: false,
                        has_unemployment_income: false,
                        has_other_income: false,
                        has_deductions: false,
                        is_self_attested_disabled: true,
                        is_physically_disabled: false,
                        has_enrolled_health_coverage: false,
                        has_eligible_health_coverage: false,
                        has_eligible_medicaid_cubcare: false,
                        is_claimed_as_tax_dependent: false,
                        is_incarcerated: false,
                        citizen_status: 'us_citizen',
                        net_annual_income: 5_078.90,
                        is_post_partum_period: false)
    end
    let!(:relationships) do
      application.add_relationship(applicant, applicant2, 'spouse')
    end

    before do
      @result = subject.call(application.reload)
      @entity_init = AcaEntities::MagiMedicaid::Operations::InitializeApplication.new.call(@result.success)
    end

    it 'should return success for result' do
      expect(@result).to be_success
    end

    it 'should be able to successfully init Application Entity' do
      expect(@entity_init).to be_success
    end

    context 'with father_or_mother_in_law' do
      before do
        application.relationships.destroy_all
        application.add_relationship(applicant, applicant2, 'father_or_mother_in_law')
        result = subject.call(application.reload)
        @entity_init = AcaEntities::MagiMedicaid::Operations::InitializeApplication.new.call(result.success)
        @mitc_relationships = result.success[:applicants].first[:mitc_relationships]
      end

      it 'should populate mitc_relationships' do
        expect(@mitc_relationships).not_to be_empty
      end

      it 'should populate correct relationship_code' do
        expect(@mitc_relationships.first[:relationship_code]).to eq('30')
      end

      it 'should be able to successfully init Application Entity' do
        expect(@entity_init).to be_success
      end
    end

    context 'with daughter_or_son_in_law' do
      before do
        application.relationships.destroy_all
        application.add_relationship(applicant, applicant2, 'daughter_or_son_in_law')
        result = subject.call(application.reload)
        @entity_init = AcaEntities::MagiMedicaid::Operations::InitializeApplication.new.call(result.success)
        @mitc_relationships = result.success[:applicants].first[:mitc_relationships]
      end

      it 'should populate mitc_relationships' do
        expect(@mitc_relationships).not_to be_empty
      end

      it 'should populate correct relationship_code' do
        expect(@mitc_relationships.first[:relationship_code]).to eq('26')
      end

      it 'should be able to successfully init Application Entity' do
        expect(@entity_init).to be_success
      end
    end

    context 'with brother_or_sister_in_law' do
      before do
        application.relationships.destroy_all
        application.add_relationship(applicant, applicant2, 'brother_or_sister_in_law')
        result = subject.call(application.reload)
        @entity_init = AcaEntities::MagiMedicaid::Operations::InitializeApplication.new.call(result.success)
        @mitc_relationships = result.success[:applicants].first[:mitc_relationships]
      end

      it 'should populate mitc_relationships' do
        expect(@mitc_relationships).not_to be_empty
      end

      it 'should populate correct relationship_code' do
        expect(@mitc_relationships.first[:relationship_code]).to eq('23')
      end

      it 'should be able to successfully init Application Entity' do
        expect(@entity_init).to be_success
      end
    end

    context 'with cousin' do
      before do
        application.relationships.destroy_all
        application.add_relationship(applicant, applicant2, 'cousin')
        result = subject.call(application.reload)
        @entity_init = AcaEntities::MagiMedicaid::Operations::InitializeApplication.new.call(result.success)
        @mitc_relationships = result.success[:applicants].first[:mitc_relationships]
      end

      it 'should populate mitc_relationships' do
        expect(@mitc_relationships).not_to be_empty
      end

      it 'should populate correct relationship_code' do
        expect(@mitc_relationships.first[:relationship_code]).to eq('16')
      end

      it 'should be able to successfully init Application Entity' do
        expect(@entity_init).to be_success
      end
    end

    if EnrollRegistry.feature_enabled?(:mitc_relationships)
      context 'with parents_domestic_partner' do
        before do
          application.relationships.destroy_all
          application.add_relationship(applicant, applicant2, 'parents_domestic_partner')
          result = subject.call(application.reload)
          @entity_init = AcaEntities::MagiMedicaid::Operations::InitializeApplication.new.call(result.success)
          @mitc_relationships = result.success[:applicants].first[:mitc_relationships]
        end

        it 'should populate mitc_relationships' do
          expect(@mitc_relationships).not_to be_empty
        end

        it 'should populate correct relationship_code' do
          expect(@mitc_relationships.first[:relationship_code]).to eq('17')
        end

        it 'should be able to successfully init Application Entity' do
          expect(@entity_init).to be_success
        end
      end

      context 'with domestic_partners_child' do
        before do
          application.relationships.destroy_all
          application.add_relationship(applicant, applicant2, 'domestic_partners_child')
          result = subject.call(application.reload)
          @entity_init = AcaEntities::MagiMedicaid::Operations::InitializeApplication.new.call(result.success)
          @mitc_relationships = result.success[:applicants].first[:mitc_relationships]
        end

        it 'should populate mitc_relationships' do
          expect(@mitc_relationships).not_to be_empty
        end

        it 'should populate correct relationship_code' do
          expect(@mitc_relationships.first[:relationship_code]).to eq('70')
        end

        it 'should be able to successfully init Application Entity' do
          expect(@entity_init).to be_success
        end
      end
    end

    context 'mitc_relationships' do
      before do
        result = subject.call(application.reload)
        @entity_init = AcaEntities::MagiMedicaid::Operations::InitializeApplication.new.call(result.success)
        @mitc_relationships = result.success[:applicants].first[:mitc_relationships]
      end

      it 'should populate mitc_relationships' do
        expect(@mitc_relationships).not_to be_empty
      end

      it 'should populate correct relationship_code' do
        expect(@mitc_relationships.first[:relationship_code].to_s).to eq('02')
      end

      it 'should be able to successfully init Application Entity' do
        expect(@entity_init).to be_success
      end
    end
  end

  context 'for claimed_as_tax_dependent_by' do
    let!(:family_member2) { FactoryBot.create(:family_member, person: person2, family: family) }
    let!(:applicant2) do
      FactoryBot.create(:applicant,
                        first_name: person2.first_name,
                        last_name: person2.last_name,
                        dob: person2.dob,
                        gender: person2.gender,
                        ssn: person2.ssn,
                        application: application,
                        eligibility_determination_id: eligibility_determination.id,
                        ethnicity: [],
                        person_hbx_id: person2.hbx_id,
                        is_self_attested_blind: false,
                        is_applying_coverage: true,
                        is_required_to_file_taxes: false,
                        is_claimed_as_tax_dependent: true,
                        claimed_as_tax_dependent_by: applicant.id,
                        is_pregnant: false,
                        has_job_income: false,
                        has_self_employment_income: false,
                        has_unemployment_income: false,
                        has_other_income: false,
                        has_deductions: false,
                        is_self_attested_disabled: true,
                        is_physically_disabled: false,
                        has_enrolled_health_coverage: false,
                        has_eligible_health_coverage: false,
                        has_eligible_medicaid_cubcare: false,
                        is_incarcerated: false,
                        citizen_status: 'us_citizen',
                        net_annual_income: 5_078.90,
                        is_post_partum_period: false)
    end
    let!(:relationships) do
      application.add_relationship(applicant, applicant2, 'parent')
    end

    before do
      @result = subject.call(application.reload)
      @entity_init = AcaEntities::MagiMedicaid::Operations::InitializeApplication.new.call(@result.success)
    end

    it 'should return success for result' do
      expect(@result).to be_success
    end

    it 'should be able to successfully init Application Entity' do
      expect(@entity_init).to be_success
    end

    context 'for claimed_as_tax_dependent_by' do
      before do
        result = subject.call(application.reload)
        @entity_init = AcaEntities::MagiMedicaid::Operations::InitializeApplication.new.call(result.success)
        @child_applicant = result.success[:applicants][1]
      end

      it 'should populate correct relationship_code' do
        expect(@child_applicant[:claimed_as_tax_dependent_by][:person_hbx_id]).to eq(applicant.person_hbx_id)
      end

      it 'should be able to successfully init Application Entity' do
        expect(@entity_init).to be_success
      end
    end
  end

  context 'with job_income' do
    let!(:create_job_income) do
      inc = ::FinancialAssistance::Income.new({
                                                kind: 'wages_and_salaries',
                                                frequency_kind: 'yearly',
                                                amount: 30_000.00,
                                                start_on: TimeKeeper.date_of_record.beginning_of_month,
                                                employer_name: 'Testing employer'
                                              })
      applicant.incomes << inc
      applicant.save!
    end

    before do
      result = subject.call(application.reload)
      @entity_init = AcaEntities::MagiMedicaid::Operations::InitializeApplication.new.call(result.success)
      @mitc_income = result.success[:applicants].first[:mitc_income]
      @income = result.success[:applicants].first[:incomes].first
    end

    it 'should be able to successfully init Application Entity' do
      expect(@entity_init).to be_success
    end

    it 'should return job_income income for applicant' do
      expect(@income[:kind]).to eq('wages_and_salaries')
      expect(@income[:frequency_kind]).to eq('Annually')
      expect(@income[:amount]).to eq(30_000.00)
      expect(@income[:employer]).to eq({ employer_name: 'Testing employer', employer_id: '' })
    end

    it 'should return mitc_income with amount populated' do
      expect(@mitc_income[:amount]).not_to be_zero
      expect(@mitc_income[:amount]).to eq(30_000.00)
    end

    it 'should return mitc_income with adjusted_gross_income populated' do
      expect(@mitc_income[:adjusted_gross_income].to_f).not_to be_zero
    end
  end

  context 'with an esi benefit' do
    let!(:create_esi_benefit) do
      emp_add = FinancialAssistance::Locations::Address.new({
                                                              :address_1 => "123",
                                                              :kind => "work",
                                                              :city => "was",
                                                              :state => "DC",
                                                              :zip => "21312"
                                                            })
      emp_phone = FinancialAssistance::Locations::Phone.new({
                                                              :kind => "work",
                                                              :area_code => "131",
                                                              :number => "2323212",
                                                              :full_phone_number => "1312323212"
                                                            })
      benefit = ::FinancialAssistance::Benefit.new({
                                                     :employee_cost => 500.00,
                                                     :employer_id => '12-2132133',
                                                     :kind => "is_enrolled",
                                                     :insurance_kind => "employer_sponsored_insurance",
                                                     :employer_name => "er1",
                                                     :is_esi_waiting_period => false,
                                                     :is_esi_mec_met => true,
                                                     :esi_covered => "self",
                                                     :start_on => Date.today.prev_year.beginning_of_month,
                                                     :end_on => nil,
                                                     :employee_cost_frequency => "monthly"
                                                   })
      benefit.employer_address = emp_add
      benefit.employer_phone = emp_phone
      applicant.benefits << benefit
      applicant.save!
    end

    before do
      result = subject.call(application.reload)
      @entity_init = AcaEntities::MagiMedicaid::Operations::InitializeApplication.new.call(result.success)
      @benefit = result.success[:applicants].first[:benefits].first
    end

    it 'should be able to successfully init Application Entity' do
      expect(@entity_init).to be_success
    end

    it 'should be able to successfully transform employee_cost_frequency' do
      expect(@benefit[:employee_cost_frequency]).to eq('Monthly')
    end
  end

  context 'with a health_reimbursement_arrangement benefit' do
    let!(:create_hra_benefit) do
      benefit = ::FinancialAssistance::Benefit.new({ kind: "is_enrolled",
                                                     insurance_kind: "health_reimbursement_arrangement",
                                                     hra_type: 'Individual coverage HRA',
                                                     employee_cost: 100.00,
                                                     employee_cost_frequency: 'monthly',
                                                     start_on: Date.today.prev_year.beginning_of_month,
                                                     employer_name: "er1",
                                                     employer_id: '23-2675213' })
      applicant.benefits << benefit
      applicant.save!
    end

    before do
      result = subject.call(application.reload)
      @entity_init = AcaEntities::MagiMedicaid::Operations::InitializeApplication.new.call(result.success)
      @benefit = result.success[:applicants].first[:benefits].first
    end

    it 'should be able to successfully init Application Entity' do
      expect(@entity_init).to be_success
    end

    it 'should be able to successfully transform hra_kind' do
      expect(@benefit[:hra_kind]).to eq(:ichra)
    end
  end

  context 'with peace_corps_health_benefits benefit' do
    let!(:create_esi_benefit) do
      benefit = ::FinancialAssistance::Benefit.new({
                                                     kind: 'is_enrolled',
                                                     insurance_kind: 'peace_corps_health_benefits',
                                                     start_on: Date.today.prev_year
                                                   })
      applicant.benefits << benefit
      applicant.save!
    end

    before do
      result = subject.call(application.reload)
      @entity_init = AcaEntities::MagiMedicaid::Operations::InitializeApplication.new.call(result.success)
      @benefit = @entity_init.success.applicants.first.benefits.first
    end

    it 'should be able to successfully init Application Entity' do
      expect(@entity_init).to be_success
    end

    it 'should not raise error' do
      expect(@benefit.annual_employee_cost).to eq(0)
    end
  end

  context 'applicant with vlp_document' do
    let!(:vlp_applicant) do
      vlp_params = {
        vlp_subject: 'I-551 (Permanent Resident Card)',
        alien_number: '123456789',
        card_number: 'abg1234567890',
        expiration_date: TimeKeeper.date_of_record.to_datetime
      }
      applicant.update_attributes!(vlp_params)
    end

    before do
      result = subject.call(application.reload)
      @entity_init = AcaEntities::MagiMedicaid::Operations::InitializeApplication.new.call(result.success)
    end

    it 'should be able to successfully init Application Entity' do
      expect(@entity_init).to be_success
    end
  end

  context 'for mitc_households' do
    let!(:family_member2) { FactoryBot.create(:family_member, person: person2, family: family) }
    let!(:applicant2) do
      FactoryBot.create(:applicant,
                        first_name: person2.first_name,
                        last_name: person2.last_name,
                        dob: person2.dob,
                        gender: person2.gender,
                        ssn: person2.ssn,
                        application: application,
                        eligibility_determination_id: eligibility_determination.id,
                        ethnicity: [],
                        person_hbx_id: person2.hbx_id,
                        is_self_attested_blind: false,
                        is_applying_coverage: true,
                        is_required_to_file_taxes: false,
                        is_claimed_as_tax_dependent: true,
                        claimed_as_tax_dependent_by: applicant.id,
                        is_pregnant: false,
                        has_job_income: false,
                        has_self_employment_income: false,
                        has_unemployment_income: false,
                        has_other_income: false,
                        has_deductions: false,
                        is_self_attested_disabled: true,
                        is_physically_disabled: false,
                        has_enrolled_health_coverage: false,
                        has_eligible_health_coverage: false,
                        has_eligible_medicaid_cubcare: false,
                        is_incarcerated: false,
                        citizen_status: 'us_citizen',
                        net_annual_income: 5_078.90,
                        is_post_partum_period: false)
    end
    let!(:relationships) do
      application.add_relationship(applicant, applicant2, 'parent')
    end
    let(:address_1_params) { { kind: 'home', address_1: '1 Awesome Street', address_2: '#100', city: 'Washington', state: 'DC', zip: '20001' } }
    let(:address_2_params) { { kind: 'home', address_1: '2 Awesome Street', address_2: '#200', city: 'Washington', state: 'DC', zip: '20001' } }
    let(:address_3_params) { { kind: 'home', address_1: '3 Awesome Street', address_2: '#300', city: 'Washington', state: 'DC', zip: '20001' } }
    let!(:home_address1) do
      application.primary_applicant.addresses.destroy_all
      application.primary_applicant.addresses.create!(address_1_params)
      application.primary_applicant.save!
    end

    context 'same address for both applicants' do
      let!(:home_address2) do
        applicant2.addresses.destroy_all
        applicant2.addresses.create!(address_1_params)
        applicant2.save!
      end

      before do
        @result = subject.call(application.reload)
        @entity_init = AcaEntities::MagiMedicaid::Operations::InitializeApplication.new.call(@result.success)
        @mitc_household = @result.success[:mitc_households].first
      end

      it 'should return success for result' do
        expect(@result).to be_success
      end

      it 'should be able to successfully init Application Entity' do
        expect(@entity_init).to be_success
      end

      it 'should populate correct mitc_household' do
        expect(@mitc_household).to eq({ household_id: '1', people: [{ person_id: '732020'}, { person_id: '732021' }] })
      end
    end

    context 'different address for both applicants' do
      let!(:home_address2) do
        applicant2.addresses.destroy_all
        applicant2.addresses.create!(address_2_params)
        applicant2.save!
      end

      before do
        @result = subject.call(application.reload)
        @entity_init = AcaEntities::MagiMedicaid::Operations::InitializeApplication.new.call(@result.success)
      end

      it 'should return success for result' do
        expect(@result).to be_success
      end

      it 'should be able to successfully init Application Entity' do
        expect(@entity_init).to be_success
      end

      context 'for mitc_households' do
        before do
          mitc_households = @result.success[:mitc_households]
          @first_mitc_hh = mitc_households[0]
          @second_mitc_hh = mitc_households[1]
        end

        it 'should populate first mitc_household correctly' do
          expect(@first_mitc_hh).to eq({ household_id: '1', people: [{ person_id: '732020'}] })
        end

        it 'should populate second mitc_household correctly' do
          expect(@second_mitc_hh).to eq({ household_id: '2', people: [{ person_id: '732021' }] })
        end
      end
    end

    context 'child has same address as primary but spouse has a different address ' do
      let!(:home_address2) do
        applicant2.addresses.destroy_all
        applicant2.addresses.create!(address_1_params)
        applicant2.save!
      end

      let!(:family_member3) { FactoryBot.create(:family_member, person: person3, family: family) }
      let!(:applicant3) do
        FactoryBot.create(:applicant,
                          first_name: person3.first_name,
                          last_name: person3.last_name,
                          dob: person3.dob,
                          gender: person3.gender,
                          ssn: person3.ssn,
                          application: application,
                          eligibility_determination_id: eligibility_determination.id,
                          ethnicity: [],
                          person_hbx_id: person3.hbx_id,
                          is_self_attested_blind: false,
                          is_applying_coverage: true,
                          is_required_to_file_taxes: false,
                          is_claimed_as_tax_dependent: false,
                          is_pregnant: false,
                          has_job_income: false,
                          has_self_employment_income: false,
                          has_unemployment_income: false,
                          has_other_income: false,
                          has_deductions: false,
                          is_self_attested_disabled: true,
                          is_physically_disabled: false,
                          has_enrolled_health_coverage: false,
                          has_eligible_health_coverage: false,
                          has_eligible_medicaid_cubcare: false,
                          is_incarcerated: false,
                          citizen_status: 'us_citizen',
                          net_annual_income: 0.0,
                          is_post_partum_period: false)
      end
      let!(:third_set_relationships) do
        application.add_relationship(applicant2, applicant3, 'child')
        application.add_relationship(applicant, applicant3, 'spouse')
      end
      let!(:home_address3) do
        applicant3.addresses.destroy_all
        applicant3.addresses.create!(address_3_params)
        applicant3.save!
      end

      before do
        @result = subject.call(application.reload)
        @entity_init = AcaEntities::MagiMedicaid::Operations::InitializeApplication.new.call(@result.success)
      end

      it 'should return success for result' do
        expect(@result).to be_success
      end

      it 'should be able to successfully init Application Entity' do
        expect(@entity_init).to be_success
      end

      context 'for mitc_households' do
        before do
          mitc_households = @result.success[:mitc_households]
          @first_mitc_hh = mitc_households[0]
          @second_mitc_hh = mitc_households[1]
        end

        it 'should populate first mitc_household correctly' do
          expect(@first_mitc_hh).to eq({ household_id: '1', people: [{ person_id: '732020'}, { person_id: '732021' }] })
        end

        it 'should populate second mitc_household correctly' do
          expect(@second_mitc_hh).to eq({ household_id: '2', people: [{ person_id: '732022' }] })
        end
      end
    end
  end

  context 'for mitc_income' do
    let!(:create_job_income1) do
      inc = ::FinancialAssistance::Income.new({ kind: 'wages_and_salaries',
                                                frequency_kind: 'yearly',
                                                amount: 30_000.00,
                                                start_on: TimeKeeper.date_of_record.beginning_of_month,
                                                employer_name: 'Testing employer' })
      applicant.incomes << inc
      applicant.save!
    end

    let!(:income2) do
      inc = ::FinancialAssistance::Income.new({ kind: 'net_self_employment',
                                                frequency_kind: 'monthly',
                                                amount: 100.00,
                                                start_on: TimeKeeper.date_of_record.next_month.beginning_of_month })
      applicant.incomes << inc
      applicant.save!
    end

    let!(:income3) do
      inc = ::FinancialAssistance::Income.new({ kind: 'net_self_employment',
                                                frequency_kind: 'monthly',
                                                amount: 2_500.00,
                                                start_on: TimeKeeper.date_of_record.prev_year })
      applicant.incomes << inc
      applicant.save!
    end

    before do
      result = subject.call(application.reload)
      @entity_init = AcaEntities::MagiMedicaid::Operations::InitializeApplication.new.call(result.success)
      @mitc_income = result.success[:applicants].first[:mitc_income]
    end

    it 'should be able to successfully init Application Entity' do
      expect(@entity_init).to be_success
    end

    it 'should be able to successfully return mitc_income with amount' do
      expect(@mitc_income[:amount]).to eq(60_000.00)
    end

    it 'should return taxable_interest for mitc_income as zero' do
      expect(@mitc_income[:taxable_interest]).to be_zero
    end

    it 'should return alimony for mitc_income as zero' do
      expect(@mitc_income[:alimony]).to be_zero
    end

    it 'should return capital_gain_or_loss for mitc_income as zero' do
      expect(@mitc_income[:capital_gain_or_loss]).to be_zero
    end

    it 'should return pensions_and_annuities_taxable_amount for mitc_income as zero' do
      expect(@mitc_income[:pensions_and_annuities_taxable_amount]).to be_zero
    end

    it 'should return farm_income_or_loss for mitc_income as zero' do
      expect(@mitc_income[:farm_income_or_loss]).to be_zero
    end

    it 'should return unemployment_compensation for mitc_income as zero' do
      expect(@mitc_income[:unemployment_compensation]).to be_zero
    end

    it 'should return other_income for mitc_income as zero' do
      expect(@mitc_income[:other_income]).to be_zero
    end
  end

  context 'for has_daily_living_help' do
    let!(:has_daily_living_help) do
      applicant.update_attributes!({ has_daily_living_help: true,
                                     is_self_attested_long_term_care: false })
    end

    before do
      result = subject.call(application.reload)
      @entity_init = AcaEntities::MagiMedicaid::Operations::InitializeApplication.new.call(result.success)
      @applicant = result.success[:applicants].first
    end

    it 'should be able to successfully init Application Entity' do
      expect(@entity_init).to be_success
    end

    it "should add value of has_daily_living_help to applicant entity's is_self_attested_long_term_care" do
      expect(@applicant[:is_self_attested_long_term_care]).to eq(applicant.reload.has_daily_living_help)
    end

    it "should not add value of is_self_attested_long_term_care to applicant entity's is_self_attested_long_term_care" do
      expect(@applicant[:is_self_attested_long_term_care]).not_to eq(applicant.reload.is_self_attested_long_term_care)
    end
  end

  context 'for mitc_is_required_to_file_taxes' do
    before do
      applicant.update_attributes!(is_required_to_file_taxes: false)
      create_income
      result = subject.call(application.reload)
      @entity_init = AcaEntities::MagiMedicaid::Operations::InitializeApplication.new.call(result.success)
      @applicant = result.success[:applicants].first
    end

    context 'for earned_income' do
      context 'greater than Earned Income Filing Threshold for assistance year' do
        let(:create_income) do
          inc = ::FinancialAssistance::Income.new({
                                                    kind: ['wages_and_salaries', 'net_self_employment', 'scholarship_payments'].sample,
                                                    frequency_kind: 'yearly',
                                                    amount: 30_000.00,
                                                    start_on: TimeKeeper.date_of_record.beginning_of_month,
                                                    employer_name: 'Testing employer'
                                                  })
          applicant.incomes = [inc]
          applicant.save!
        end

        it 'should be able to successfully init Application Entity' do
          expect(@entity_init).to be_success
        end

        it 'should return true for mitc_is_required_to_file_taxes' do
          expect(@applicant[:mitc_is_required_to_file_taxes]).to eq(true)
        end
      end

      context 'less than Earned Income Filing Threshold for assistance year' do
        let(:create_income) do
          inc = ::FinancialAssistance::Income.new({
                                                    kind: ['wages_and_salaries', 'net_self_employment', 'scholarship_payments'].sample,
                                                    frequency_kind: 'yearly',
                                                    amount: 100.00,
                                                    start_on: TimeKeeper.date_of_record.beginning_of_month,
                                                    employer_name: 'Testing employer'
                                                  })
          applicant.incomes = [inc]
          applicant.save!
        end

        it 'should be able to successfully init Application Entity' do
          expect(@entity_init).to be_success
        end

        it 'should return false for mitc_is_required_to_file_taxes' do
          expect(@applicant[:mitc_is_required_to_file_taxes]).to eq(false)
        end
      end
    end

    context 'for unearned_income' do
      context 'greater than Unearned Income Filing Threshold for assistance year' do
        let(:create_income) do
          inc = ::FinancialAssistance::Income.new({
                                                    kind: ::FinancialAssistance::Income::UNEARNED_INCOME_KINDS.sample,
                                                    frequency_kind: 'yearly',
                                                    amount: 3_000.00,
                                                    start_on: TimeKeeper.date_of_record.beginning_of_month,
                                                    employer_name: 'Testing employer'
                                                  })
          applicant.incomes = [inc]
          applicant.save!
        end

        it 'should be able to successfully init Application Entity' do
          expect(@entity_init).to be_success
        end

        it 'should return true for mitc_is_required_to_file_taxes' do
          expect(@applicant[:mitc_is_required_to_file_taxes]).to eq(true)
        end
      end

      context 'less than Unearned Income Filing Threshold for assistance year' do
        let(:create_income) do
          inc = ::FinancialAssistance::Income.new({
                                                    kind: ::FinancialAssistance::Income::UNEARNED_INCOME_KINDS.sample,
                                                    frequency_kind: 'yearly',
                                                    amount: 100.00,
                                                    start_on: TimeKeeper.date_of_record.beginning_of_month,
                                                    employer_name: 'Testing employer'
                                                  })
          applicant.incomes = [inc]
          applicant.save!
        end

        it 'should be able to successfully init Application Entity' do
          expect(@entity_init).to be_success
        end

        it 'should return true for mitc_is_required_to_file_taxes' do
          expect(@applicant[:mitc_is_required_to_file_taxes]).to eq(false)
        end
      end
    end
  end

  context 'with deductable_part_of_self_employment_taxes deduction' do
    let!(:deduction) do
      deduction = ::FinancialAssistance::Deduction.new({ kind: 'deductable_part_of_self_employment_taxes',
                                                         amount: 100.00,
                                                         start_on: Date.today.prev_year,
                                                         frequency_kind: 'monthly' })
      applicant.deductions << deduction
      applicant.save!
    end

    before do
      result = subject.call(application.reload)
      @entity_init = AcaEntities::MagiMedicaid::Operations::InitializeApplication.new.call(result.success)
      @deduction = @entity_init.success.applicants.first.deductions.first
    end

    it 'should be able to successfully init Application Entity' do
      expect(@entity_init).to be_success
    end

    it 'should return deduction kind which is allowed in AcaEntities' do
      expect(::AcaEntities::MagiMedicaid::Types::DeductionKind).to include(@deduction.kind)
    end
  end

  context 'for is_filing_as_head_of_household' do
    before do
      result = subject.call(application)
      @entity_init = AcaEntities::MagiMedicaid::Operations::InitializeApplication.new.call(result.success)
      @applicant = @entity_init.success.applicants.first
    end

    it 'should be able to successfully init Application Entity' do
      expect(@entity_init).to be_success
    end

    it 'should return deduction kind which is allowed in AcaEntities' do
      expect(@applicant.is_filing_as_head_of_household).to eq(applicant.is_filing_as_head_of_household)
    end
  end

  context 'total_hours_worked_per_week' do
    let!(:create_job_income12) do
      inc = ::FinancialAssistance::Income.new({ kind: 'wages_and_salaries',
                                                frequency_kind: 'yearly',
                                                amount: 30_000.00,
                                                start_on: TimeKeeper.date_of_record.prev_year,
                                                end_on: TimeKeeper.date_of_record.prev_month,
                                                employer_name: 'Testing employer' })
      applicant.incomes << inc
      applicant.save!
    end

    context 'income end_on is before TimeKeeper.date_of_record' do
      before do
        result = subject.call(application)
        @entity_init = AcaEntities::MagiMedicaid::Operations::InitializeApplication.new.call(result.success)
        @applicant = @entity_init.success.applicants.first
      end

      it 'should be able to successfully init Application Entity' do
        expect(@entity_init).to be_success
      end

      it 'should return zero for applicant hours_worked_per_week' do
        expect(@applicant.hours_worked_per_week).to be_zero
      end
    end
  end

  describe 'had_prior_insurance & prior_insurance_end_date' do
    context 'success' do
      let!(:create_esi_benefit) do
        benefit = ::FinancialAssistance::Benefit.new({
                                                       kind: 'is_enrolled',
                                                       insurance_kind: 'peace_corps_health_benefits',
                                                       start_on: Date.today.prev_year,
                                                       end_on: TimeKeeper.date_of_record.prev_month
                                                     })
        applicant.benefits = [benefit]
        applicant.save!
      end

      before do
        result = subject.call(application)
        @entity_init = AcaEntities::MagiMedicaid::Operations::InitializeApplication.new.call(result.success)
        @applicant = @entity_init.success.applicants.first
      end

      it 'should populate had_prior_insurance' do
        expect(@applicant.had_prior_insurance).to be_truthy
        expect(@applicant.prior_insurance_end_date).to eq(applicant.benefits.first.end_on)
      end

      it 'should not return nil for prior_insurance_end_date' do
        expect(@applicant.prior_insurance_end_date).not_to be_nil
        expect(@applicant.prior_insurance_end_date).to eq(applicant.benefits.first.end_on)
      end
    end
  end

  describe 'had_prior_insurance & prior_insurance_end_date' do
    context 'success' do
      before do
        result = subject.call(application)
        @entity_init = AcaEntities::MagiMedicaid::Operations::InitializeApplication.new.call(result.success)
        @student = @entity_init.success.applicants.first.student
      end

      it 'should populate is_student for student' do
        expect(@student.is_student).to eq(applicant.is_student)
      end

      it 'should populate student_kind for student' do
        expect(@student.student_kind).to eq('full_time')
      end

      it 'should populate student_school_kind for student' do
        expect(@student.student_school_kind).to eq('graduate_school')
      end

      it 'should populate student_school_kind for student' do
        expect(@student.student_status_end_on).to eq(TimeKeeper.date_of_record.end_of_month)
      end
    end
  end

  describe 'is_pregnant without pregnancy_due_on' do
    context 'success' do
      before do
        application.applicants.each do |applicant|
          applicant.update_attributes!({ is_pregnant: true, pregnancy_due_on: nil })
        end
        result = subject.call(application)
        @entity_init = AcaEntities::MagiMedicaid::Operations::InitializeApplication.new.call(result.success)
      end

      it 'should should return success' do
        expect(@entity_init.success?).to be_truthy
      end
    end
  end

  describe 'mitc_income for prospective year application' do
    let(:prospective_year) { TimeKeeper.date_of_record.next_year.year }
    let(:create_job_income1) do
      inc = ::FinancialAssistance::Income.new({ kind: 'wages_and_salaries',
                                                frequency_kind: 'yearly',
                                                amount: 30_000.00,
                                                start_on: Date.new(prospective_year),
                                                employer_name: 'Testing employer' })
      applicant.incomes << inc
      applicant.save!
    end

    let(:create_job_income2) do
      inc = ::FinancialAssistance::Income.new({ kind: 'wages_and_salaries',
                                                frequency_kind: 'monthly',
                                                amount: 100.00,
                                                start_on: Date.new(prospective_year, 2, 1) })
      applicant.incomes << inc
      applicant.save!
    end

    let(:create_job_income3) do
      inc = ::FinancialAssistance::Income.new({ kind: 'wages_and_salaries',
                                                frequency_kind: 'monthly',
                                                amount: 2_500.00,
                                                start_on: TimeKeeper.date_of_record,
                                                end_on: TimeKeeper.date_of_record.end_of_year })
      applicant.incomes << inc
      applicant.save!
    end

    before do
      applicant.incomes.destroy_all
      create_job_income1
      create_job_income2
      create_job_income3
      application.update_attributes!(assistance_year: prospective_year, effective_date: Date.new(prospective_year))
      result = subject.call(application.reload)
      @entity_init = AcaEntities::MagiMedicaid::Operations::InitializeApplication.new.call(result.success)
      @mitc_income = result.success[:applicants].first[:mitc_income]
    end

    it 'should be able to successfully init Application Entity' do
      expect(@entity_init).to be_success
    end

    it 'should be able to successfully return mitc_income with amount' do
      expect(@mitc_income[:amount]).to eq(30_000.00)
    end

    it 'should return taxable_interest for mitc_income as zero' do
      expect(@mitc_income[:taxable_interest]).to be_zero
    end

    it 'should return alimony for mitc_income as zero' do
      expect(@mitc_income[:alimony]).to be_zero
    end

    it 'should return capital_gain_or_loss for mitc_income as zero' do
      expect(@mitc_income[:capital_gain_or_loss]).to be_zero
    end

    it 'should return pensions_and_annuities_taxable_amount for mitc_income as zero' do
      expect(@mitc_income[:pensions_and_annuities_taxable_amount]).to be_zero
    end

    it 'should return farm_income_or_loss for mitc_income as zero' do
      expect(@mitc_income[:farm_income_or_loss]).to be_zero
    end

    it 'should return unemployment_compensation for mitc_income as zero' do
      expect(@mitc_income[:unemployment_compensation]).to be_zero
    end

    it 'should return other_income for mitc_income as zero' do
      expect(@mitc_income[:other_income]).to be_zero
    end

    it 'should return adjusted_gross_income for mitc_income' do
      expect(@mitc_income[:adjusted_gross_income]).to be_a Float
      expect(@mitc_income[:adjusted_gross_income]).not_to be_a Money
    end
  end

  describe "#applicant_benchmark_premium" do
    let(:result) { subject.call(application) }
    context "when all applicants are valid" do

      it "should successfully submit a cv3 application" do
        expect(result).to be_success
      end
    end

    context "when a family member is deleted" do
      before do
        family.family_members.last.delete
        family.reload
      end

      it "should unsuccessfully submit a cv3 application and get a failure response" do
        expect(result).to_not be_success
      end
    end
  end
end
