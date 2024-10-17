# frozen_string_literal: true

require 'rails_helper'

describe ::FinancialAssistance::Services::SummaryService do
  let!(:application) { FactoryBot.create(:application, family_id: BSON::ObjectId.new, assistance_year: Date.today.year) }
  let(:applicant) do
    FactoryBot.create(:applicant, application: application,
                                  ssn: '243108282',
                                  dob: Date.new(1984, 3, 8),
                                  gender: "Male",
                                  first_name: 'Domtest34',
                                  last_name: 'Test',
                                  is_primary_applicant: true)
  end
  let(:cfl_service) { ::FinancialAssistance::Services::ConditionalFieldsLookupService.new }
  subject { ::FinancialAssistance::Services::SummaryService.new(is_concise: false, can_edit: false, cfl_service: cfl_service, application: application, applicants: application.active_applicants) }
  describe 'applicant_summaries' do
    context "when benefits are present" do
      let!(:benefit) do
        ben = FactoryBot.build(:financial_assistance_benefit, employer_name: 'Test Employer', insurance_kind: 'employer_sponsored_insurance')
        ben.build_employer_address(kind: 'home', address_1: 'address_1', city: 'Dummy City', state: 'DC', zip: '20001')
        ben.build_employer_phone(kind: 'home', country_code: '001', area_code: '123', number: '4567890', primary: true)
        applicant.benefits << ben
        applicant.update_attributes(has_eligible_health_coverage: true)
        applicant.save!
        ben
      end

      it "should return esi hash" do
        esi_benefit_hash = subject.sections.first[:subsections][4][:rows][1][:coverages].first.first
        expect(esi_benefit_hash[:employer_name][:value]).to eq "Test Employer"
        expect(esi_benefit_hash[:employer_address_line_1][:value]).to eq "address_1"
        expect(esi_benefit_hash[:city][:value]).to eq "Dummy City"
      end
    end
  end
end
