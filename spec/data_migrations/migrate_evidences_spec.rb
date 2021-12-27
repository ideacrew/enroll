# frozen_string_literal: true

require 'rails_helper'
require 'rake'

require File.join(Rails.root, 'app', 'data_migrations', 'migrate_evidences')

describe MigrateEvidences, dbclean: :after_each do
  let(:given_task_name) { 'migrate_evidences' }

  subject { MigrateEvidences.new(given_task_name, double(:current_scope => nil)) }

  describe 'given a task name' do
    it 'has the given task name' do
      expect(subject.name).to eql given_task_name
    end
  end

  describe 'delete nil evidences' do
    let!(:application) do
      FactoryBot.create(:financial_assistance_application, hbx_id: '200000126', aasm_state: "determined")
    end

    let(:evidence_types) do
      [[:aces_mec, "ACES MEC"], [:esi_mec, "ESI MEC"], [:non_esi_mec, "Non ESI MEC"], [:income, "Income"]]
    end

    let!(:applicant1) do
      FactoryBot.create(:financial_assistance_applicant,
                        eligibility_determination_id: nil,
                        person_hbx_id: '1629165429385938',
                        is_primary_applicant: true,
                        first_name: 'First',
                        last_name: 'Responder',
                        ssn: "518124854",
                        dob: Date.new(1988, 11, 11),
                        application: application)
    end

    let!(:applicant2) do
      FactoryBot.create(:financial_assistance_applicant,
                        eligibility_determination_id: nil,
                        person_hbx_id: '162916542938599',
                        is_primary_applicant: false,
                        first_name: 'Second',
                        last_name: 'Responder',
                        ssn: "518124855",
                        dob: Date.new(1989, 11, 11),
                        application: application)
    end

    let(:document) do
      FinancialAssistance::Document.new
    end

    let(:eligibility_result) do
      FinancialAssistance::EligibilityResult.new({
                                                   :result => "eligible",
                                                   source_transaction_id: "12345678",
                                                   :source => "FDSH",
                                                   :code => "HS0000000",
                                                   :code_description => "Applicant is eligible"
                                                 })
    end

    let(:verification_history) do
      FinancialAssistance::VerificationHistory.new({
                                                     action: "verify",
                                                     modifier: "admin",
                                                     update_reason: "File in Enroll"
                                                   })
    end

    let(:evidences) do
      evidence_types.collect do |type|
        key, title = type
        FinancialAssistance::Evidence.new(key: key,
                                          title: title,
                                          eligibility_status: "attested",
                                          eligibility_results: [eligibility_result],
                                          verification_history: [verification_history],
                                          documents: [document])
      end
    end

    before do
      applicant1.evidences = evidences
      applicant1.save!
      applicant2.evidences = evidences
      applicant2.save!
    end

    it "successfully migrate evidences" do
      FinancialAssistance::Applicant::EVIDENCES.each do |kind|
        application.reload.applicants.each do |applicant|
          evidence = applicant.send(kind)
          expect(evidence.present?).to eq false
        end
      end
      subject.migrate
      FinancialAssistance::Applicant::EVIDENCES.each do |kind|
        application.reload.applicants.each do |applicant|
          evidence = applicant.send(kind)
          expect(evidence.present?).to eq true
          expect(evidence.request_results.present?).to eq true
          expect(evidence.verification_histories.present?).to eq true
          expect(evidence.documents.present?).to eq true
        end
      end
    end
  end
end
