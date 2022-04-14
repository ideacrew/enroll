# frozen_string_literal: true

require 'csv'
require 'rails_helper'

describe RejectedVerificationTypesOrEvidencesReport do
  before :all do
    DatabaseCleaner.clean
  end

  subject { described_class.new("rejected_verification_types_or_evidences_report", double(:current_scope => nil)) }

  let(:person) { FactoryBot.create(:person, :with_consumer_role) }
  let(:ver_type) { person.verification_types.create!(type_name: 'Citizenship', validation_status: 'rejected') }
  let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
  let(:application) { FactoryBot.create(:application, family_id: family.id, aasm_state: 'submitted', assistance_year: TimeKeeper.date_of_record.year) }
  let(:applicant) do
    FactoryBot.create(:applicant, application: application, dob: person.dob, is_primary_applicant: true,
                                  family_member_id: family.primary_applicant.id, person_hbx_id: person.hbx_id)
  end
  let(:esi_evidence) do
    applicant.create_esi_evidence(key: :esi_mec, title: 'ESI MEC', aasm_state: 'rejected',
                                  due_on: nil, verification_outstanding: false, is_satisfied: true)
  end

  let(:output_csv) { "#{Rails.root}/rejected_verification_types_or_evidences_report.csv" }

  after :all do
    output_csv = "#{Rails.root}/rejected_verification_types_or_evidences_report.csv"
    File.delete(output_csv) if File.exist?(output_csv)
    DatabaseCleaner.clean
  end

  context 'with only verification_types' do
    before do
      ver_type
      subject.migrate
      @csv = CSV.read(output_csv)
    end

    it 'should include details of person and verification_type in the report' do
      expect(@csv.last[1]).to eq(person.first_name)
      expect(@csv.last[7]).to eq(person.hbx_id)
      expect(@csv.last[8]).to eq(ver_type.type_name)
      expect(@csv.last[9]).to eq(l10n('verification_type.validation_status'))
    end
  end

  context 'with only evidences' do
    before do
      esi_evidence
      subject.migrate
      @csv = CSV.read(output_csv)
    end

    it 'should include details of person and evidence in the report' do
      expect(@csv.last[7]).to eq(person.hbx_id)
      expect(@csv.last[8]).to eq(l10n('faa.evidence_type_esi'))
      expect(@csv.last[9]).to eq(esi_evidence.aasm_state.capitalize)
    end
  end

  context 'with both verification_types and evidences' do
    before do
      ver_type
      esi_evidence
      subject.migrate
      @csv = CSV.read(output_csv)
    end

    it 'should include details of person with both verification_type and evidence in the report' do
      v_type_row = @csv.detect { |row| row[7] == person.hbx_id && row[8] == ver_type.type_name }
      expect(v_type_row[7]).to eq(person.hbx_id)
      expect(v_type_row[8]).to eq(ver_type.type_name)
      expect(v_type_row[9]).to eq(l10n('verification_type.validation_status'))

      evidence_row = @csv.detect { |row| row[7] == person.hbx_id && row[8] == l10n('faa.evidence_type_esi') }
      expect(evidence_row[7]).to eq(person.hbx_id)
      expect(evidence_row[8]).to eq(l10n('faa.evidence_type_esi'))
      expect(evidence_row[9]).to eq(esi_evidence.aasm_state.capitalize)
    end
  end
end
