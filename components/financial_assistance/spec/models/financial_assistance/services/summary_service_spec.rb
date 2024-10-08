# frozen_string_literal: true

require 'rails_helper'

describe ::FinancialAssistance::Services::SummaryService do
  assistance_year = TimeKeeper.date_of_record.year
  let!(:application) { FactoryBot.create(:application, family_id: BSON::ObjectId.new, assistance_year: assistance_year) }
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

  describe '.instance_for_action' do
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

  describe '#sections' do
    subject { described_class.new(is_concise: is_concise, can_edit: false, cfl_service: cfl_service, application: application, applicants: application.active_applicants).sections }
    
    # helper method to toggle a single flag in the registry
    def toggle_single_flag(registry, flag, enabled)
      allow(registry).to receive(:feature_enabled?).and_return(false)
      allow(registry).to receive(:feature_enabled?).with(flag).and_return(enabled)
    end

    # helper examples
    # enforce general structure of a given subsection
    shared_examples "subsection structure" do |subsection_title, expected_rows|
      it "includes the #{subsection_title} subsection with the expected rows" do # enforce presence of section, expected title, and expected rows
        expect(subsection).not_to be_nil
        expect(subsection[:title]).to eq(subsection_title)
        rows = subsection[:rows]
        expect(rows.map { |row| row[:key] }).to match_array(expected_rows.keys)
        expect(rows.map { |row| row[:value] }).to match_array(expected_rows.values)
      end
    end

    # enforce the presence and absence of a row based on a precondition
    shared_examples "conditional row" do |row_label, precondition_args|
      precondition_desc = precondition_args[:desc]
      precondition_proc = precondition_args[:proc]
      let(:includes_row) { subsection[:rows].map { |row| row[:key] }.include?(row_label) }
      
      context "when the precondition that <#{precondition_desc}> holds" do
        before do instance_exec(&precondition_proc) if precondition_proc end # setup the precondition
        it "includes the \"#{row_label}\" row" do expect(includes_row).to be true end # enforce the presence of the row
      end
    
      context "when the precondition that <#{precondition_desc}> does not hold" do
        it "does not include the \"#{row_label}\" row" do expect(includes_row).to be false end # enforce the absence of the row without the precondtion
      end
    end

    context "when initialized with is_concise as false" do
      let(:is_concise) { false }

      describe "Personal Information subsection" do
        let(:subsection) { subject.first[:subsections][0] }
       
        it_behaves_like "subsection structure", "Personal Information", {
          "DOB"=>"03/08/1984",
          "Sex"=>"Male",
          "Relationship"=>"Self",
          "Needs Coverage?"=>"N/A",
          "Is this person a US citizen or US national?"=>"N/A",
          "Is this person a naturalized or derived citizen?"=>"N/A",
          "Does this person have an eligible immigration status?"=>"N/A",
          "Document Type"=>"N/A",
          "Citizenship Number"=>"N/A",
          "Alien Number"=>"N/A",
          "I 94 Number"=>"N/A",
          "Visa Number"=>"N/A",
          "Passport Number"=>"N/A",
          "SEVIS ID"=>"N/A",
          "Naturalization Number"=>"N/A",
          "Receipt Number"=>"N/A",
          "Card Number"=>"N/A",
          "Country of Citizenship"=>"N/A",
          "Document Description"=>"N/A",
          "Expiration Date"=>"N/A",
          "Issuing Country"=>"N/A",
          "Are you a member of an American Indian or Alaska Native Tribe?"=>"N/A",
          "Tribe State"=>"N/A",
          "Tribe Name"=>"N/A",
          "Tribe Codes"=>nil,
          "Is this person currently incarcerated?"=>"N/A",
          "Race/Ethnicity"=>nil       
        }
      end

      describe "Tax Information subsection" do
        let(:subsection) { subject.first[:subsections][1] }
       
        it_behaves_like "subsection structure", "Tax Information", {
          "Will this person file taxes for #{assistance_year}?"=>"N/A",
          "Will this person be claimed as a tax dependent for #{assistance_year}?"=>"N/A",
          "Will this person be filing jointly?"=>"N/A",
          "This person will be claimed as a dependent by"=>"N/A"
        }
      end
    end

    context "when initialized with is_concise as true" do
      let(:is_concise) { true }

      describe "Personal Information subsection" do
        let(:subsection) { subject.first[:subsections][0] }
       
        it_behaves_like "subsection structure", "Personal Information", { "Age"=>40, "Sex"=>"Male", "Relationship"=>"Self", "Status"=>nil, "Incarcerated"=>"N/A", "Needs Coverage?"=>"N/A" }
      end

      describe "Tax Information subsection" do
        let(:subsection) { subject.first[:subsections][1] }
        
        it_behaves_like "subsection structure", "Tax Information", {
          "Will this person file taxes for #{assistance_year}?"=>"N/A",
          "Will this person be claimed as a tax dependent for #{assistance_year}?"=>"N/A",
          "Will this person be filing jointly?"=>"N/A",
          "This person will be claimed as a dependent by"=>"N/A"
        }

        it_behaves_like "conditional row", "Will this person be filing jointly?", {
          desc: "applicant is required to file taxes and has a spouse", 
          proc: -> {
            applicant.update(is_required_to_file_taxes: true)
            applicant.save
            application.relationships << ::FinancialAssistance::Relationship.new({kind: "spouse", applicant_id: applicant.id, relative_id: applicant.id}) # mock spouse relationship to self
            application.save
          }
        }

        it_behaves_like "conditional row", "This person will be claimed as a dependent by", {
          desc: "applicant is claimed as tax dependent", 
          proc: -> {
            applicant.update(is_claimed_as_tax_dependent: true)
            applicant.save
          }
        }
      end

      describe "Income subsection" do
        let(:subsection) { subject.first[:subsections][2] }

        before do
          applicant.update_attributes(has_job_income: true, has_self_employment_income: false)
          applicant.save
        end

        it_behaves_like "subsection structure", "Income", {
          "Does this person have income from an employer"=>"Yes",
          "Does this person have self-employment income?"=>"No",
          "Does this person have income from other sources?"=>"N/A",
          "Does this person receive unemployment compensation, or have they received it this year?"=>"N/A"
        }

        it_behaves_like "conditional row", "Is any of this person's income from American Indian or Alaska Native tribal sources?", {
          desc: "american_indian_alaskan_native_income flag is enabled", 
          proc: -> { toggle_single_flag(EnrollRegistry, :american_indian_alaskan_native_income, true) }
        }
      end

      describe "Income and Adjustments subsection" do
        let(:subsection) { subject.first[:subsections][3] }

        before do
          applicant.update_attributes(has_deductions: true)
          applicant.save
        end

        it_behaves_like "subsection structure", "Income Adjustments", {"Does this person have adjustments to income?"=>"Yes"}
      end
    end
  end
end
