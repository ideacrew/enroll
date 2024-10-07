# frozen_string_literal: true

require 'rails_helper'

describe ::FinancialAssistance::Services::SummaryService do
  let!(:application) { FactoryBot.create(:application, family_id: BSON::ObjectId.new, assistance_year: Date.today.year) }
  let!(:applicant) do
    FactoryBot.create(:applicant, application: application,
                                  ssn: '243108282',
                                  dob: Date.new(1984, 3, 8),
                                  gender: "Male",
                                  first_name: 'Domtest34',
                                  last_name: 'Test',
                                  is_primary_applicant: true)
  end
  let(:cfl_service) { ::FinancialAssistance::Services::ConditionalFieldsLookupService.new }

  describe('.instance_for_action') do
    RSpec.shared_examples 'a SummaryService instance' do |applicant_summary_class, can_edit|
      it "should return instance of SummaryService with applicant_summaries of type #{applicant_summary_class}" do
        applicant_summaries = subject.instance_variable_get(:@applicant_summaries)
        expect(applicant_summaries).to all(be_a(applicant_summary_class))
      end
    
      it "should return instance of SummaryService that is #{can_edit ? 'editable' : 'not editable'}" do
        expect(subject.can_edit_incomes).to eq(can_edit)

        applicant_summaries = subject.instance_variable_get(:@applicant_summaries)
        applicant_summaries.each do |summary|
          edit_links = summary.hash[:subsections].pluck(:edit_link).compact
          if can_edit
            expect(edit_links).not_to be_empty
          else
            expect(edit_links).to be_empty
          end
        end
      end
    end

    context 'when action is raw_application' do
      let(:action_name) { 'raw_application' }
      subject { described_class.instance_for_action(action_name, cfl_service, application, application.active_applicants) }

      it_behaves_like 'a SummaryService instance', FinancialAssistance::Services::SummaryService::Summary::ApplicantSummary::ApplicantSummary::AdminApplicantSummary, false
    end

    context 'when action is review' do
      let(:action_name) { 'review' }
      subject { described_class.instance_for_action(action_name, cfl_service, application, application.active_applicants) }

      it_behaves_like 'a SummaryService instance', FinancialAssistance::Services::SummaryService::Summary::ApplicantSummary::ApplicantSummary::ConsumerApplicantSummary, false
    end

    context 'when action is review_and_submit' do
      let(:action_name) { 'review_and_submit' }
      subject { described_class.instance_for_action(action_name, cfl_service, application, application.active_applicants) }

      it_behaves_like 'a SummaryService instance', FinancialAssistance::Services::SummaryService::Summary::ApplicantSummary::ApplicantSummary::ConsumerApplicantSummary, true
    end
  end

  describe '#sections' do
    describe('when is_concise is false') do
      subject { ::FinancialAssistance::Services::SummaryService.new(is_concise: false, can_edit: false, cfl_service: cfl_service, application: application, applicants: application.active_applicants).sections.first }

      describe('health coverage section') do
        let(:section) { subject[:subsections][4][:rows] }

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
            esi_benefit_hash = section[1][:coverages].first.first
            expect(esi_benefit_hash[:employer_name][:value]).to eq "Test Employer"
            expect(esi_benefit_hash[:employer_address_line_1][:value]).to eq "address_1"
            expect(esi_benefit_hash[:city][:value]).to eq "Dummy City"
          end
        end

        context "when benefits are not present" do
          before do
            applicant.update_attributes(has_eligible_health_coverage: false, has_enrolled_health_coverage: false)
            applicant.save!
          end

          it "should not return esi hash" do
            expect(section[0][:coverages]).to be_nil
            expect(section[1][:coverages]).to be_nil
          end
        end
      end
    end
  end
end
