# frozen_string_literal: true

require 'rails_helper'

describe ::FinancialAssistance::Services::SummaryService do
  assistance_year = TimeKeeper.date_of_record.year
  let!(:application) { FactoryBot.create(:application, family_id: BSON::ObjectId.new, assistance_year: assistance_year) }
  let(:cfl_service) { ::FinancialAssistance::Services::ConditionalFieldsLookupService.new }

  def create_applicant(first_name, ssn, is_primary_applicant: false, relationship_kind: 'child')
    applicant = FactoryBot.create(
      :applicant,
      application: application,
      ssn: ssn,
      dob: Date.new(1984, 3, 8),
      gender: "Male",
      first_name: first_name,
      last_name: 'Test',
      is_primary_applicant: is_primary_applicant
    )

    unless is_primary_applicant
      application.relationships << ::FinancialAssistance::Relationship.new({kind: relationship_kind, applicant_id: applicant.id, relative_id: application.primary_applicant.id})
      application.relationships << ::FinancialAssistance::Relationship.new({kind: relationship_kind, applicant_id: application.primary_applicant.id, relative_id: applicant.id}) if relationship_kind == 'spouse'
      application.save!
    end

    applicant
  end
  let!(:applicant) { create_applicant('Domtest34', '243108282', is_primary_applicant: true) }

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
    def toggle_flag(flag, registry = FinancialAssistanceRegistry, is_enabled: true)
      allow(registry).to receive(:feature_enabled?).and_return(false)
      allow(registry).to receive(:feature_enabled?).with(flag).and_return(true) if is_enabled
    end

    def toggle_fa_flags(flags)
      allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).and_return(false)
      flags.each { |flag| allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(flag).and_return(true) }
    end

    # enforce section structure
    describe "applicant sections" do
      let(:is_concise) { false }

      context("when there is only one applicant") do
        it("it only has one section") do
          expect(subject.length).to eq(1)
        end

        it("it has the correct Applicant summary section title") do
          expect(subject.first[:section_title]).to eq("Domtest34 Test")
        end
      end

      context("when there are three applicants") do
        before do
          create_applicant('Domtest35', '243108283')
          create_applicant('Domtest36', '243108284')
        end

        it("it has four sections") do
          expect(subject.length).to eq(4) # 4 sections: 3 Applicant summary section and 1 Family Relationships summary section
        end

        it("it has the correct Applicant summary section titles") do
          expect(subject[...3].map { |s| s[:section_title] }).to eq(["Domtest34 Test", "Domtest35 Test", "Domtest36 Test"])
        end
      end
    end

    # enforce applicant subsection structure
    describe "applicant subsections" do
      let(:subsection) { subject.first[:subsections][subsection_index] }

      # helper examples

      # enforce general structure of a given subsection
      shared_examples "subsection structure" do |expected_title:, expected_rows:|
        it "includes the #{expected_title} subsection with the expected rows" do # enforce presence of section, expected title, and expected rows
          expect(subsection).not_to be_nil
          expect(subsection[:title]).to eq(expected_title) unless expected_title.include?("nested") # nested subsections do not have titles
          rows = subsection[:rows]
          # reduce sut from descriptive hash to a hash of key-value pairs for easy comparison
          expect(rows.reduce({}) {|stripped_rows, row| stripped_rows.update(row[:key] => row[:value])}).to eq(expected_rows)
        end
      end

      # enforce the presence and absence of row(s) based on a precondition
      shared_examples "conditional rows" do |expected_row_labels:, precondition:|
        precondition_desc = precondition[:desc]
        precondition_proc = precondition[:proc]
        expected_row_labels = [expected_row_labels] unless expected_row_labels.is_a?(Array)

        expected_row_labels.each_with_index do |row_label, index|
          includes_row = "includes_#{index}".to_sym
          let(includes_row) { subsection[:rows].map { |row| row[:key] }.include?(row_label) }

          context "when the precondition that <#{precondition_desc}> holds" do
            before { instance_exec(&precondition_proc) if precondition_proc }
            it "includes the \"#{row_label}\" row" do expect(send(includes_row)).to be true end
          end

          context "when the precondition that <#{precondition_desc}> does not hold" do
            it "does not include the \"#{row_label}\" row" do expect(send(includes_row)).to be false end
          end
        end
      end

      # base examples between summary variants

      shared_examples "base Income subsection" do
        before { applicant.update_attributes!(has_job_income: true, has_self_employment_income: false) }

        it_behaves_like "subsection structure", expected_title: "Income", expected_rows: {
          "Does this person have income from an employer (wages, tips, bonuses, etc.) in #{assistance_year}?" => "Yes",
          "Does this person expect to receive self-employment income in #{assistance_year}?" => "No",
          "Does this person expect to have income from other sources in #{assistance_year}?" => "N/A",
          "Did this person receive Unemployment Income at any point in #{assistance_year}?" => "N/A"
        }
      end

      shared_examples "base Income and Adjustments subsection" do
        before { applicant.update_attributes!(has_deductions: true) }

        it_behaves_like "subsection structure", expected_title: "Income Adjustments", expected_rows: {"Does this person expect to have income adjustments in #{assistance_year}?" => "Yes"}
      end

      shared_examples "base Health Coverage subsection" do
        let!(:eligble_label) { "Does this person currently have access to other health coverage that they are not enrolled in, including coverage they could get through another person?" }
        let!(:enrolled_label) { "Is this person currently enrolled in health coverage?" }

        shared_examples "a Health Coverage subsection with nested coverages subsection" do |kind, insurance_kind:, expected_coverage_subsection_rows:|
          before do
            allow(FinancialAssistanceRegistry[:has_enrolled_health_coverage].setting(:currently_enrolled)).to receive(:item).and_return(true)
            allow(FinancialAssistanceRegistry[:has_eligible_health_coverage].setting(:currently_eligible)).to receive(:item).and_return(true)
            toggle_flag(insurance_kind)

            ben = FactoryBot.build(:financial_assistance_benefit, employer_name: 'Test Employer', kind: kind, insurance_kind: insurance_kind.to_s)
            ben.build_employer_address(kind: 'home', address_1: '300 Circle Dr.', city: 'Dummy City', state: 'DC', zip: '20001')
            ben.build_employer_phone(kind: 'home', country_code: '001', area_code: '123', number: '4567890', primary: true)
            applicant.benefits << ben
            applicant.update_attributes!(has_enrolled_health_coverage: kind == :is_enrolled, has_eligible_health_coverage: kind == :is_eligible)
            applicant.save!
          end

          # enforce base structure on top-level rows
          it_behaves_like "subsection structure", expected_title: "Health Coverage", expected_rows: {
            "Is this person currently enrolled in health coverage?" => kind == :is_enrolled ? "Yes" : "No",
            "Does this person currently have access to other health coverage that they are not enrolled in, including coverage they could get through another person?" => kind == :is_eligible ? "Yes" : "No"
          }

          # enforce nested coverage subsection structure
          describe "nested coverage subsection" do
            # intercept lazily loaded `subsection` reference later used in `subsection structure` helper and override it with the nested coverage subsection under test
            def override_subsection_reference(row_label)
              coverage_nested_subsection = subsection[:rows].find { |row| row[:key] == row_label }[:coverages].first.first
              allow(self).to receive(:subsection).and_return({rows: coverage_nested_subsection.values})
            end
            before { override_subsection_reference(kind == :is_eligible ? eligble_label : enrolled_label) }

            it_behaves_like "subsection structure", expected_title: "Health Coverage nested Coverages subsection", expected_rows: expected_coverage_subsection_rows
          end
        end

        context "when the coverage is enrolled" do
          it_behaves_like "a Health Coverage subsection with nested coverages subsection", :is_enrolled, :insurance_kind => :employer_sponsored_insurance, expected_coverage_subsection_rows: {
            "Coverage through a job (or another person's job, like a spouse or parent)" => " - Present",
            "Employer Name" => "Test Employer",
            "Employer Address Line 1" => "300 Circle Dr.",
            "City" => "Dummy City",
            "State" => "DC",
            "ZIP" => 20_001,
            "Phone Number" => "(123) 456-7890",
            "Employer Identification No. (Ein)" => nil,
            "Is the employee currently in a waiting period and eligible to enroll in the next 3 months?" => "N/A",
            "Does this employer offer a health plan that meets the minimum value standard?" => "N/A",
            "Who can be covered?" => "N/A",
            "How much would the employee only pay for the lowest cost minimum value standard plan?" => nil
          }
        end
      end

      context "when initialized with is_concise as false" do
        let(:is_concise) { false }

        describe "Personal Information subsection" do
          let(:subsection_index) { 0 }

          it_behaves_like "subsection structure", expected_title: "Personal Information", expected_rows: {
            "DOB" => "03/08/1984",
            "Gender" => "Male",
            "Relationship" => "Self",
            "Needs Coverage?" => "N/A",
            "Is this person a US citizen or US national?" => "N/A",
            "Is this person a naturalized citizen?" => "N/A",
            "Do you have eligible immigration status? *" => "N/A",
            "Document Type" => "N/A",
            "Citizenship Number" => "N/A",
            "Alien Number" => "N/A",
            "I 94 Number" => "N/A",
            "Visa Number" => "N/A",
            "Passport Number" => "N/A",
            "SEVIS ID" => "N/A",
            "Naturalization Number" => "N/A",
            "Receipt Number" => "N/A",
            "Card Number" => "N/A",
            "Country of Citizenship" => "N/A",
            "Vlp Description" => "N/A",
            "Expiration Date" => "N/A",
            "Issuing Country" => "N/A",
            "Are you a member of an American Indian or Alaska Native Tribe?" => "N/A",
            "Is this person currently incarcerated?" => "N/A",
            "Race/Ethnicity" => nil
          }

          it_behaves_like "conditional rows", expected_row_labels: ["Tribe State", "Tribe Name", "Tribe Codes"], precondition: { desc: "tribes_information_raw_review flag is enabled", proc: -> { toggle_flag(:tribes_information_raw_review) } }
        end

        describe "Tax Information subsection" do
          let(:subsection_index) { 1 }

          it_behaves_like "subsection structure", expected_title: "Tax Information", expected_rows: {
            "Will this person file taxes for #{assistance_year}?" => "N/A",
            "Will this person be claimed as a tax dependent for #{assistance_year}?" => "N/A",
            "Will this person be filing jointly?" => "N/A",
            "This person will be claimed as a dependent by" => "N/A"
          }
        end

        describe "Income subsection" do
          let(:subsection_index) { 2 }

          it_behaves_like "base Income subsection"
        end

        describe "Income and Adjustments subsection" do
          let(:subsection_index) { 3 }

          it_behaves_like "base Income and Adjustments subsection"
        end

        describe "Health Coverage subsection" do
          let(:subsection_index) { 4 }

          it_behaves_like "base Health Coverage subsection"

          it_behaves_like "conditional rows",
                          expected_row_labels: [
                            "Is this person currently enrolled in health coverage or getting help paying for health coverage through a Health Reimbursement Arrangement?",
                            "Is this person eligible to get health services from the Indian Health Service, a tribal health program, or an urban Indian health program or through referral from one of these programs?",
                            "Has this person ever gotten a health service from the Indian Health Service, a tribal health program, or urban Indian health program or through a referral from one of these programs?",
                            "Was this person found not eligible for MaineCare (Medicaid) or Cub Care (Children's Health Insurance Program) within the last 90 days?",
                            "When was this person denied MaineCare (Medicaid) or Cub Care (Children's Health Insurance Program)?",
                            "Did this person have MaineCare (Medicaid) or Cub Care (Children's Health Insurance Program) that will end soon or that recently ended because of a change in eligibility?",
                            "Has this person's household income or household size changed since they were told their coverage was ending?",
                            "What's the last day of this person’s Medicaid or CHIP coverage?",
                            "Was this person found not eligible for MaineCare (Medicaid) or Cub Care (Children's Health Insurance Program) based on their immigration status since 2019",
                            "Has this person’s immigration status changed since they were not found eligible for MaineCare (Medicaid) or Cub Care (Children’s Health Insurance Program)"
                          ],
                          precondition: {
                            desc: "the applicant has hra health coverage",
                            proc: lambda {
                                    allow(FinancialAssistanceRegistry[:has_enrolled_health_coverage].setting(:currently_enrolled)).to receive(:item).and_return(false)
                                    allow(FinancialAssistanceRegistry[:has_enrolled_health_coverage].setting(:currently_enrolled_with_hra)).to receive(:item).and_return(true)
                                  }
                          }
        end

        describe "Other Questions subsection" do
          let(:subsection_index) { 5 }

          before { toggle_flag(:post_partum_period_one_year) }

          it_behaves_like "subsection structure", expected_title: "Other Questions", expected_rows: {
            "Has this person applied for an SSN?" => "N/A",
            "No SSN Reason" => "N/A",
            "Is this person pregnant?" => "N/A",
            "Pregnancy due date?" => "N/A",
            "How many children is this person expecting?" => 0,
            "Was this person pregnant in the last year?" => "N/A",
            "Pregnancy end date:" => "N/A",
            "Was this person enrolled in Medicaid during the pregnancy?" => "N/A",
            "Was this person in foster care at age 18 or older?" => "N/A",
            "Where was this person in foster care?" => "N/A",
            "How old was this person when they left foster care?" => 0,
            "Was this person enrolled in Medicaid when they left foster care?" => "N/A",
            "Is this person a full-time student?" => "N/A",
            "What is the type of student?" => "N/A",
            "Student status end on date?" => "N/A",
            "What type of school do you go to?" => nil,
            "Is this person blind?" => "N/A",
            "Does this person need help with daily life activities, such as dressing or bathing?" => "N/A",
            "Does this person need help paying for any medical bills from the last 3 months?" => "N/A",
            "Does this person have a disability?" => "N/A"
          }

          it_behaves_like "conditional rows",
                          expected_row_labels: [
                            "Is this person the main person taking care of any children age 18 or younger?",
                            "Which member(s) of the household is this person the caretaker for? (choose all that apply)"
                          ],
                          precondition: {
                            desc: "the applicant is greater than 19 years old and is applying for coverage",
                            proc: -> { applicant.update_attributes(dob: 20.years.ago, is_applying_coverage: true) }
                          }
        end
      end

      context "when initialized with is_concise as true" do
        let(:is_concise) { true }

        describe "Personal Information subsection" do
          let(:subsection_index) { 0 }

          it_behaves_like "subsection structure", expected_title: "Personal Information", expected_rows: { "Age" => 40, "Gender" => "Male", "Relationship" => "Self", "Status" => nil, "Incarcerated" => "N/A", "Needs Coverage?" => "N/A" }
        end

        describe "Tax Information subsection" do
          let(:subsection_index) { 1 }

          it_behaves_like "subsection structure", expected_title: "Tax Information", expected_rows: {
            "Will this person file taxes for #{assistance_year}?" => "N/A",
            "Will this person be claimed as a tax dependent for #{assistance_year}?" => "N/A"
          }

          it_behaves_like "conditional rows", expected_row_labels: "Will this person be filing jointly?", precondition: {
            desc: "applicant is required to file taxes and has a spouse",
            proc: lambda {
              applicant.update!(is_required_to_file_taxes: true)
              create_applicant('Spouse', '243108285', relationship_kind: 'spouse')
            }
          }

          it_behaves_like "conditional rows", expected_row_labels: "This person will be claimed as a dependent by", precondition: {
            desc: "applicant is claimed as tax dependent",
            proc: -> { applicant.update!(is_claimed_as_tax_dependent: true) }
          }
        end

        describe "Income subsection" do
          let(:subsection_index) { 2 }

          it_behaves_like "base Income subsection"

          it_behaves_like "conditional rows", expected_row_labels: "Is any of this person's income from American Indian or Alaska Native tribal sources?", precondition: {
            desc: "american_indian_alaskan_native_income flag is enabled",
            proc: -> { toggle_flag(:american_indian_alaskan_native_income, EnrollRegistry) }
          }
        end

        describe "Income and Adjustments subsection" do
          let(:subsection_index) { 3 }

          it_behaves_like "base Income and Adjustments subsection"
        end

        describe "Health Coverage subsection" do
          let(:subsection_index) { 4 }

          it_behaves_like "base Health Coverage subsection"

          it_behaves_like "conditional rows",
                          expected_row_labels: [
                            "Is this person eligible to get health services from the Indian Health Service, a tribal health program, or an urban Indian health program or through referral from one of these programs?",
                            "Has this person ever gotten a health service from the Indian Health Service, a tribal health program, or urban Indian health program or through a referral from one of these programs?"
                          ],
                          precondition: {
                            desc: "indian_health_service_question flag is enabled and the applicant is an Indian tribe member",
                            proc: lambda {
                              toggle_flag(:indian_health_service_question, EnrollRegistry)
                              applicant.update_attributes(indian_tribe_member: true)
                            }
                          }

          it_behaves_like "conditional rows",
                          expected_row_labels: [
                                            "Was this person found not eligible for MaineCare (Medicaid) or Cub Care (Children's Health Insurance Program) within the last 90 days?",
                                            "When was this person denied MaineCare (Medicaid) or Cub Care (Children's Health Insurance Program)?",
                                            "Did this person have MaineCare (Medicaid) or Cub Care (Children's Health Insurance Program) that will end soon or that recently ended because of a change in eligibility?",
                                            "Has this person's household income or household size changed since they were told their coverage was ending?",
                                            "What's the last day of this person’s Medicaid or CHIP coverage?"
                                          ],
                          precondition: {
                            desc: "has_medicare_cubcare_eligible flag is enabled",
                            proc: -> { toggle_flag(:has_medicare_cubcare_eligible) }
                          }

          it_behaves_like "conditional rows",
                          expected_row_labels: [
                                            "Was this person found not eligible for MaineCare (Medicaid) or Cub Care (Children's Health Insurance Program) based on their immigration status since #{assistance_year - 5}",
                                            "Has this person’s immigration status changed since they were not found eligible for MaineCare (Medicaid) or Cub Care (Children’s Health Insurance Program)"
                                          ],
                          precondition: {
                            desc: "medicaid_chip_driver_questions flag is enabled and the applicant has an eligible immigration status",
                            proc: lambda {
                                    toggle_flag(:medicaid_chip_driver_questions)
                                    applicant.eligible_immigration_status = true
                                  }
                          }

          it_behaves_like "conditional rows",
                          expected_row_labels: [
                                            "Did this person have coverage through a job (for example, a parent’s job) that ended in the last 3 months?",
                                            "What was the last day this person had coverage through the job?"
                                          ],
                          precondition: {
                            desc: "has_dependent_with_coverage flag is enabled and the applicant is less than 19 years old",
                            proc: lambda {
                                    toggle_flag(:has_dependent_with_coverage)
                                    applicant.update_attributes(dob: 18.years.ago)
                                  }
                          }
        end

        describe "Other Questions subsection" do
          let(:subsection_index) { 5 }

          before do
            toggle_flag(:post_partum_period_one_year)
            applicant.update_attributes!(is_student: false, is_physically_disabled: true)
          end

          it_behaves_like "subsection structure", expected_title: "Other Questions", expected_rows: {
            "Is this person pregnant?" => "N/A",
            "Is this person a full-time student?" => "No",
            "Is this person blind?" => "N/A",
            "Does this person need help with daily life activities, such as dressing or bathing?" => "N/A",
            "Does this person need help paying for any medical bills from the last 3 months?" => "N/A",
            "Does this person have a disability?" => "Yes"
          }

          it_behaves_like "conditional rows", expected_row_labels: "Has this person applied for an SSN?", precondition: {
            desc: "the applicant is applying for coverage, has no SSN, and has indicated an SSN application reason",
            proc: -> { applicant.update_attributes!(is_applying_coverage: true, no_ssn: '1', is_ssn_applied: false) }
          }

          it_behaves_like "conditional rows", expected_row_labels: "No SSN Reason", precondition: {
            desc: "the applicant is applying for coverage, has no SSN, has not applied for an SSN, and has given a reason",
            proc: -> { applicant.update_attributes!(is_applying_coverage: true, no_ssn: '1', is_ssn_applied: false, non_ssn_apply_reason: "applicant reason") }
          }

          it_behaves_like "conditional rows", expected_row_labels: ["Pregnancy due date?", "How many children is this person expecting?"], precondition: {
            desc: "the applicant is pregnant",
            proc: -> { applicant.update_attributes!(is_pregnant: true) }
          }

          it_behaves_like "conditional rows", expected_row_labels: "Was this person pregnant in the last year?", precondition: {
            desc: "the applicant is not pregnant",
            proc: -> { applicant.update_attributes!(is_pregnant: false) }
          }

          it_behaves_like "conditional rows", expected_row_labels: "Pregnancy end date:", precondition: {
            desc: "the applicant is not pregnant but was recently pregnant and is in post partum",
            proc: -> { applicant.update_attributes!(is_pregnant: false, is_post_partum_period: true, pregnancy_end_on: 30.days.ago) }
          }

          it_behaves_like "conditional rows", expected_row_labels: "Was this person enrolled in Medicaid during the pregnancy?", precondition: {
            desc: "the applicant is enrolled on medicaid",
            proc: -> { applicant.update_attributes!(is_enrolled_on_medicaid: true) }
          }

          it_behaves_like "conditional rows", expected_row_labels: "Was this person in foster care at age 18 or older?", precondition: {
            desc: "the applicant age is within the applicable foster care range",
            proc: -> { applicant.update_attributes!(dob: 21.years.ago) }
          }

          it_behaves_like "conditional rows", expected_row_labels: ["Where was this person in foster care?", "How old was this person when they left foster care?", "Was this person enrolled in Medicaid when they left foster care?"], precondition: {
            desc: "the applicant age is within the applicable foster care range and had former foster care",
            proc: -> { applicant.update_attributes!(dob: 21.years.ago, is_former_foster_care: true) }
          }

          it_behaves_like "conditional rows", expected_row_labels: ["What is the type of student?", "Student status end on date?", "What type of school do you go to?"], precondition: {
            desc: "the applicant age is a student",
            proc: -> { applicant.update_attributes!(is_student: true) }
          }

          it_behaves_like "conditional rows", expected_row_labels: "Is this person the main person taking care of any children age 18 or younger?", precondition: {
            desc: "the primary_caregiver_other_question flag is enabled and the applicant is greater than 19 years old and is applying for coverage",
            proc: lambda {
              toggle_flag(:primary_caregiver_other_question)
              applicant.update_attributes!(dob: 20.years.ago, is_applying_coverage: true)
            }
          }

          it_behaves_like "conditional rows", expected_row_labels: "Which member(s) of the household is this person the caretaker for? (choose all that apply)", precondition: {
            desc: "the primary_caregiver_relationship_other_question flag is enabled and the applicant is greater than 19 years old and is applying for coverage",
            proc: lambda {
              toggle_flag(:primary_caregiver_relationship_other_question)
              applicant.update_attributes!(dob: 20.years.ago, is_applying_coverage: true)
            }
          }
        end
      end
    end
  end
end
