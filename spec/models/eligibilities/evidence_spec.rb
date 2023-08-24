# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Eligibilities::Evidence, type: :model, dbclean: :after_each do
  let!(:application) do
    FactoryBot.create(
      :application,
      family_id: BSON::ObjectId.new,
      aasm_state: 'submitted',
      assistance_year: TimeKeeper.date_of_record.year,
      effective_date: Date.today
    )
  end

  let!(:applicant) do
    FactoryBot.create(
      :applicant,
      application: application,
      dob: Date.today - 40.years,
      is_primary_applicant: true,
      family_member_id: BSON::ObjectId.new
    )
  end

  let(:income) do
    income = FactoryBot.build(:financial_assistance_income)
    applicant.incomes << income
  end

  describe 'Evidences present the applicant' do
    context '.extend_due_on' do
      before do
        applicant.create_income_evidence(
          key: :income,
          title: 'Income',
          aasm_state: 'pending',
          due_on: nil,
          verification_outstanding: false,
          is_satisfied: true
        )
        applicant.create_esi_evidence(
          key: :esi_mec,
          title: 'Esi',
          aasm_state: 'pending',
          due_on: nil,
          verification_outstanding: false,
          is_satisfied: true
        )
      end

      let(:new_due_date) do
        applicant.schedule_verification_due_on + 30.days
      end

      it 'should update due date' do
        evidence = applicant.income_evidence

        expect(evidence.due_on).to be_nil
        expect(evidence.verification_histories).to be_empty

        output = evidence.extend_due_on(30.days, 'system')
        evidence.reload

        expect(output).to be_truthy
        expect(evidence.due_on).to eq new_due_date
        expect(evidence.verification_histories).to be_present

        history = evidence.verification_histories.first
        expect(history.action).to eq 'extend_due_date'
        expect(history.update_reason).to eq "Extended due date to #{evidence.due_on.strftime('%m/%d/%Y')}"
        expect(history.updated_by).to eq 'system'
      end

      it 'should update default due date for 30 days' do
        evidence = applicant.income_evidence
        expect(evidence.extend_due_on).to be_truthy
      end
    end

    context '.request_determination' do
      before do
        applicant.create_income_evidence(
          key: :income,
          title: 'Income',
          aasm_state: 'pending',
          due_on: nil,
          verification_outstanding: false,
          is_satisfied: true
        )
        applicant.create_esi_evidence(
          key: :esi_mec,
          title: 'Esi',
          aasm_state: 'pending',
          due_on: nil,
          verification_outstanding: false,
          is_satisfied: true
        )
      end

      let(:updated_by) { '12345' }
      let(:update_reason) { "Requested Hub for verification" }
      let(:action) { 'request_hub' }
      let(:event) { double(success?: true, value!: double(publish: true)) }

      it 'should update due date' do
        evidence = applicant.esi_evidence

        evidence.stub(:construct_payload) { {} }
        evidence.stub(:event) { event }
        evidence.stub(:generate_evidence_updated_event) { true }

        expect(evidence.verification_histories).to be_empty

        result = evidence.request_determination(action, update_reason, updated_by)
        evidence.reload

        expect(result).to be_truthy
        expect(evidence.verification_histories).to be_present

        history = evidence.verification_histories.first
        expect(history.action).to eq action
        expect(history.update_reason).to eq update_reason
        expect(history.updated_by).to eq updated_by
      end
    end

    context 'validating a payload in during an admin FDSH hub call' do
      let(:updated_by) { 'admin' }
      let(:update_reason) { "Requested Hub for verification" }
      let(:action) { 'request_hub' }
      let(:event) { double(success?: false, value!: double(publish: true)) }

      let!(:person) { FactoryBot.create(:person, :with_consumer_role, hbx_id: '100095')}
      let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person)}
      let!(:application) { FactoryBot.create(:financial_assistance_application, family_id: family.id, aasm_state: 'submitted', hbx_id: "830293", effective_date: TimeKeeper.date_of_record.beginning_of_year) }
      let(:applicant1_has_enrolled_health_coverage) { false }
      let(:applicant1_has_eligible_health_coverage) { false }
      let(:applicant1_is_applying_coverage) { true }

      let(:applicant1_has_job_income) { false }
      let(:applicant1_has_self_employment_income) { false }
      let(:applicant1_has_unemployment_income) { false }
      let(:applicant1_has_other_income) { false }

      let(:applicant1_has_deductions) { false }

      let!(:applicant) do
        applicant = FactoryBot.create(:applicant,
                                      :with_student_information,
                                      first_name: person.first_name,
                                      last_name: person.last_name,
                                      dob: person.dob,
                                      gender: person.gender,
                                      ssn: person.ssn,
                                      application: application,
                                      ethnicity: nil,
                                      is_primary_applicant: true,
                                      person_hbx_id: person.hbx_id,
                                      is_self_attested_blind: false,
                                      is_applying_coverage: applicant1_is_applying_coverage,
                                      is_required_to_file_taxes: true,
                                      is_filing_as_head_of_household: true,
                                      is_pregnant: false,
                                      is_primary_caregiver: true,
                                      is_primary_caregiver_for: [],
                                      has_job_income: applicant1_has_job_income,
                                      has_self_employment_income: applicant1_has_self_employment_income,
                                      has_unemployment_income: applicant1_has_unemployment_income,
                                      has_other_income: applicant1_has_other_income,
                                      has_deductions: applicant1_has_deductions,
                                      is_self_attested_disabled: true,
                                      is_physically_disabled: false,
                                      citizen_status: 'us_citizen',
                                      has_enrolled_health_coverage: applicant1_has_enrolled_health_coverage,
                                      has_eligible_health_coverage: applicant1_has_eligible_health_coverage,
                                      has_eligible_medicaid_cubcare: false,
                                      is_claimed_as_tax_dependent: false,
                                      is_incarcerated: false,
                                      net_annual_income: 10_078.90,
                                      is_post_partum_period: false,
                                      is_veteran_or_active_military: true)
        applicant
      end

      let!(:eligibility_determination) { FactoryBot.create(:financial_assistance_eligibility_determination, application: application) }

      let(:premiums_hash) do
        {
          [person.hbx_id] => {:health_only => {person.hbx_id => [{:cost => 200.0, :member_identifier => person.hbx_id, :monthly_premium => 200.0}]}}
        }
      end

      let(:slcsp_info) do
        {
          person.hbx_id => {:health_only_slcsp_premiums => {:cost => 200.0, :member_identifier => person.hbx_id, :monthly_premium => 200.0}}
        }
      end

      let(:lcsp_info) do
        {
          person.hbx_id => {:health_only_lcsp_premiums => {:cost => 100.0, :member_identifier => person.hbx_id, :monthly_premium => 100.0}}
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

      context 'with aptc active' do
        before do
          eligibility_determination.update(max_aptc: 720.0)

          applicant.create_income_evidence(
            key: :income,
            title: 'Income',
            aasm_state: :negative_response_received,
            due_on: TimeKeeper.date_of_record,
            verification_outstanding: true,
            is_satisfied: false
          )
        end

        it 'should validate when constructing the payload' do
          evidence = applicant.income_evidence

          # use to mock verification_history
          # evidence.stub(:event) { event }
          # evidence.stub(:generate_evidence_updated_event) { true }

          # expect(evidence.verification_histories).to be_empty

          result = evidence.request_determination(action, update_reason, updated_by)
          evidence.reload
          binding.irb

          expect(result).to be_falsey
          # expect(evidence.aasm_status).to eq(:negative_response_received)
          expect(evidence.verification_histories).to be_present

          history = evidence.verification_histories.first
          expect(history.action).to eq action
          expect(history.update_reason).to eq update_reason
          expect(history.updated_by).to eq updated_by
        end
      end
    end

    context 'reject' do
      let(:evidence) do
        evidence = applicant.create_income_evidence(
          key: :income,
          title: 'Income',
          aasm_state: 'pending',
          due_on: nil,
          verification_outstanding: false,
          is_satisfied: true
        )

        evidence
      end

      before do
        evidence.move_to_rejected!
        evidence.reload
      end

      shared_examples_for 'transition to rejected' do |initial_state|
        let(:aasm_state) { initial_state }

        it 'should transition to rejected' do
          expect(evidence.aasm_state).to eq 'rejected'
        end
      end

      it_behaves_like "transition to rejected", 'pending'
      it_behaves_like "transition to rejected", 'review'
      it_behaves_like "transition to rejected", 'attested'
      it_behaves_like "transition to rejected", 'verified'
      it_behaves_like "transition to rejected", 'outstanding'
    end
  end

  describe 'clone_embedded_documents' do
    let!(:income_evidence) do
      applicant.create_income_evidence(key: :income,
                                       title: 'Income',
                                       aasm_state: 'pending',
                                       due_on: Date.today,
                                       verification_outstanding: true,
                                       is_satisfied: false)
    end

    let!(:application2) do
      FactoryBot.create(:application, family_id: application.family_id, aasm_state: 'draft',
                                      assistance_year: TimeKeeper.date_of_record.year, effective_date: Date.today)
    end

    let!(:applicant2) do
      FactoryBot.create(:applicant, application: application, dob: Date.today - 40.years,
                                    is_primary_applicant: true, family_member_id: applicant.family_member_id)
    end

    let!(:income_evidence2) do
      applicant2.create_income_evidence(key: :income,
                                        title: 'Income',
                                        aasm_state: 'pending',
                                        due_on: Date.today,
                                        verification_outstanding: true,
                                        is_satisfied: false)
    end

    before do
      create_embedded_docs_for_evidence(income_evidence)
      income_evidence.verification_histories.first.update_attributes!(date_of_action: TimeKeeper.date_of_record - 1.day)
      income_evidence.request_results.first.update_attributes!(date_of_action: TimeKeeper.date_of_record - 1.day)
      income_evidence.clone_embedded_documents(income_evidence2)
      @new_verification_history = income_evidence.verification_histories.first
      @new_request_result = income_evidence.request_results.first
      @new_wfst = income_evidence.workflow_state_transitions.first
      @new_document = income_evidence.documents.first
    end

    it 'should clone verification_history' do
      expect(income_evidence.verification_histories).not_to be_empty
      expect(@new_verification_history.created_at).not_to be_nil
      expect(@new_verification_history.updated_at).not_to be_nil
    end

    it 'should clone request_result' do
      expect(income_evidence.request_results).not_to be_empty
      expect(@new_request_result.created_at).not_to be_nil
      expect(@new_request_result.updated_at).not_to be_nil
    end

    it 'should clone workflow_state_transition' do
      expect(income_evidence.workflow_state_transitions).not_to be_empty
      expect(@new_wfst.created_at).not_to be_nil
      expect(@new_wfst.updated_at).not_to be_nil
    end

    it 'should clone documents' do
      expect(income_evidence.documents).not_to be_empty
      expect(@new_document.created_at).not_to be_nil
      expect(@new_document.updated_at).not_to be_nil
    end

    it 'should copy the date_of_action of the copied document' do
      income_evidence2.verification_histories.first.save
      expect(income_evidence.verification_histories.first.date_of_action).to eql(income_evidence2.verification_histories.first.date_of_action)
    end

    it 'should copy the date_of_action of the request result' do
      income_evidence2.request_results.first.save
      expect(income_evidence.request_results.first.date_of_action).to eql(income_evidence2.request_results.first.date_of_action)
    end
  end

  context "verification reasons" do
    if EnrollRegistry[:enroll_app].setting(:site_key).item == :me
      it "should have crm document system as verification reason" do
        expect(VlpDocument::VERIFICATION_REASONS).to include("Self-Attestation")
        expect(::Eligibilities::Evidence::VERIFY_REASONS).to include("CRM Document Management System")
        expect(EnrollRegistry[:verification_reasons].item).to include("CRM Document Management System")
      end
    end
    if EnrollRegistry[:enroll_app].setting(:site_key).item == :dc
      it "should have salesforce as verification reason" do
        expect(VlpDocument::VERIFICATION_REASONS).to include("Self-Attestation")
        expect(::Eligibilities::Evidence::VERIFY_REASONS).to include("Salesforce")
        expect(EnrollRegistry[:verification_reasons].item).to include("Salesforce")
      end
    end
  end
end

def create_embedded_docs_for_evidence(evidence)
  create_verification_history(evidence)
  create_request_result(evidence)
  create_workflow_state_transition(evidence)
  create_document(evidence)
end

def create_verification_history(evidence)
  evidence.verification_histories.create(action: 'verify', update_reason: 'Document in EnrollApp', updated_by: 'admin@user.com')
end

def create_request_result(evidence)
  evidence.request_results.create(result: 'verified', source: 'FDSH IFSV', raw_payload: 'raw_payload')
end

def create_workflow_state_transition(evidence)
  evidence.workflow_state_transitions.create(to_state: "approved", transition_at: TimeKeeper.date_of_record, reason: "met minimum criteria",
                                             comment: "consumer provided proper documentation", user_id: BSON::ObjectId.from_time(DateTime.now))
end

def create_document(evidence)
  evidence.documents.create(title: 'document.pdf', creator: 'mehl', subject: 'document.pdf', publisher: 'mehl', type: 'text', identifier: 'identifier', source: 'enroll_system', language: 'en')
end
