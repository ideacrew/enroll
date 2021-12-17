# frozen_string_literal: true

require 'rails_helper'
require 'rake'

require File.join(Rails.root, 'app', 'data_migrations', 'delete_nil_evidences')

xdescribe DeleteNilEvidences, dbclean: :after_each do
  let(:given_task_name) { 'delete_nil_evidences' }

  subject { DeleteNilEvidences.new(given_task_name, double(:current_scope => nil)) }

  describe 'given a task name' do
    it 'has the given task name' do
      expect(subject.name).to eql given_task_name
    end
  end

  describe 'delete nil evidences' do
    let!(:application) do
      FactoryBot.create(:financial_assistance_application, hbx_id: '200000126', aasm_state: "determined")
    end

    let!(:applicant) do
      FactoryBot.create(:financial_assistance_applicant,
                        eligibility_determination_id: nil,
                        person_hbx_id: '1629165429385938',
                        is_primary_applicant: true,
                        first_name: 'new',
                        last_name: 'evidence',
                        ssn: "518124854",
                        dob: Date.new(1988, 11, 11),
                        application: application)
    end

    before do
      applicant.set(evidences: [FinancialAssistance::Evidence.new])
    end

    # Validations added to evidence for debugging, cannot run this spec as is.
    xit "successfully deletes the nil evidences" do
      expect(applicant.evidences.count).to eq 1
      expect(applicant.evidences.first.key).to eq nil
      subject.migrate
      expect(applicant.reload.evidences.where(key: nil).present?).to eq false
    end
  end
end
