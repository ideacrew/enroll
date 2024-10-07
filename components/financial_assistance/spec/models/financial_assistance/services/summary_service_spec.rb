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
    shared_examples 'a SummaryService instance' do |applicant_summary_class, can_edit|
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

  describe('#sections') do
    shared_examples "base sections" do
      it "includes personal info, tax info, income, income adjustments, health coverage, and other questions subsections" do
        expect(subject[:subsections].pluck(:title)).to contain_exactly("Personal Information", "Tax Information", "Income", "Income Adjustments", "Health Coverage", "Other Questions")
      end
    end

    shared_examples "base health coverage rows" do
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

    def toggle_single_flag(registry, flag, enabled)
      allow(registry).to receive(:feature_enabled?).and_return(false)
      allow(registry).to receive(:feature_enabled?).with(flag).and_return(enabled)
    end

    shared_examples "flagged row presence" do |registry, flag, key|
      context "when #{flag} flag is enabled" do
        before do
          toggle_single_flag(registry, flag, true)
        end
  
        it "includes the row with key '#{key}'" do
          expect(section).to include(hash_including(key: key))
        end
      end
  
      context "when #{flag} flag is disabled" do
        before do
          toggle_single_flag(registry, flag, false)
        end
  
        it "does not include the row with key '#{key}'" do
          expect(section).not_to include(hash_including(key: key))
        end
      end
    end

    shared_examples "base income rows" do
      it_behaves_like "flagged row presence", FinancialAssistanceRegistry, :unemployment_income, "Does this person receive unemployment compensation, or have they received it this year?", true
    end

    context "when initialized is_concise as false" do
      subject { ::FinancialAssistance::Services::SummaryService.new(is_concise: false, can_edit: false, cfl_service: cfl_service, application: application, applicants: application.active_applicants).sections.first }

      it_behaves_like "base sections"

      describe('personal info subsection') do
        let(:section) { subject[:subsections][0][:rows] }

        it "should return the full list of personal info rows" do
          expect(section.length).to eq(27)
        end
      end

      describe('income subsection') do
        let(:section) { subject[:subsections][2][:rows] }

        it_behaves_like "base income rows"
      end

      describe('health coverage subsection') do
        let(:section) { subject[:subsections][4][:rows] }

        it_behaves_like "base health coverage rows"
        
        describe "enrollment" do
          shared_context "enrollment setup" do |currently_enrolled, currently_enrolled_with_hra|
            before do
              allow(FinancialAssistanceRegistry[:has_enrolled_health_coverage].setting(:currently_enrolled)).to receive(:item).and_return(currently_enrolled)
              allow(FinancialAssistanceRegistry[:has_enrolled_health_coverage].setting(:currently_enrolled_with_hra)).to receive(:item).and_return(currently_enrolled_with_hra)
            end
          end
        
          context "when enrolled with hra" do
            include_context "enrollment setup", false, true

            it "should return hra rows" do
              expect(section.length).to eq(11)
            end
          end
        
          context "when enrolled" do
            include_context "enrollment setup", true, false

            it "should not return hra rows" do
              expect(section.length).to eq(2)
            end
          end
        end
      end
    end

    context "when initialized is_concise as true" do
      subject { ::FinancialAssistance::Services::SummaryService.new(is_concise: true, can_edit: false, cfl_service: cfl_service, application: application, applicants: application.active_applicants).sections.first }

      it_behaves_like "base sections"

      describe('personal info subsection') do
        let(:section) { subject[:subsections][0][:rows] }

        it "should return the concise list of personal info rows" do
          expect(section.length).to eq(6)
        end
      end

      describe('income subsection') do
        let(:section) { subject[:subsections][2][:rows] }

        it_behaves_like "base income rows"
        it_behaves_like "flagged row presence", EnrollRegistry, :american_indian_alaskan_native_income, "Is any of this person's income from American Indian or Alaska Native tribal sources?"
      end

      describe('health coverage subsection') do
        let(:section) { subject[:subsections][4][:rows] }

        it_behaves_like "base health coverage rows"
      end
    end
  end
end
