# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::FinancialAssistance::Operations::Applications::Transformers::ApplicationTo::Cv3Application, dbclean: :after_each do
  let!(:person) { FactoryBot.create(:person, hbx_id: "732020")}
  let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person)}
  let!(:application) { FactoryBot.create(:financial_assistance_application, family_id: family.id, aasm_state: 'submitted', hbx_id: "830293", effective_date: DateTime.new(2021,1,1,4,5,6)) }
  let!(:applicant) do
    applicant = FactoryBot.create(:applicant,
                                  first_name: person.first_name,
                                  last_name: person.last_name,
                                  dob: person.dob,
                                  gender: person.gender,
                                  ssn: person.ssn,
                                  application: application,
                                  ethnicity: [],
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
                                  net_annual_income: 10_078.90,
                                  is_post_partum_period: false)
    applicant
  end

  let!(:eligibility_determination) { FactoryBot.create(:financial_assistance_eligibility_determination, application: application) }

  describe 'When Application in draft state is passed' do
    let(:result) { subject.call(application) }

    before :each do
      application.update_attributes(aasm_state: "draft")
    end

    it 'should not pass' do
      expect(result.failure?).to be_truthy
    end
  end

  describe 'When Application is in submitted state passed' do
    let(:result) { subject.call(application) }

    before :each do
      family.family_members.first.update_attributes(person_id: person.hbx_id)
      applicant.update_attributes(person_hbx_id: person.hbx_id, citizen_status: 'alien_lawfully_present', eligibility_determination_id: eligibility_determination.id)
    end

    it 'should pass' do
      expect(result.success?).to be_truthy
      expect(result).to be_a(Dry::Monads::Result::Success)
      expect(result.value!).to be_a(Hash)
    end

    it 'should have oe date for year before effective date' do
      expect(result.value![:oe_start_on]).to eq Date.new((application.effective_date.year - 1), 11, 1)
    end

    it 'should have applicant with person hbx_id' do
      expect(result.value![:applicants].first[:person_hbx_id]).to eq person.hbx_id
    end

    context 'applicant' do
      before do
        request_payload = result.success
        @applicant = request_payload[:applicants].first
      end

      it 'should add is_self_attested_disabled' do
        expect(@applicant[:attestation][:is_self_attested_disabled]).to eq(applicant.is_physically_disabled)
        expect(@applicant[:attestation][:is_self_attested_disabled]).not_to eq(applicant.is_self_attested_disabled)
      end
    end

    context 'mitc_income' do
      before do
        request_payload = result.success
        @mitc_income_hash = request_payload[:applicants].first[:mitc_income]
      end

      it 'should add adjusted_gross_income' do
        expect(@mitc_income_hash[:adjusted_gross_income]).to eq(applicant.net_annual_income)
      end
    end
  end
end