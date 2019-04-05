require 'rails_helper'
require File.join(Rails.root, 'app', 'data_migrations', 'reset_e_case_id')

describe ResetECaseId, dbclean: :after_each do

  let(:given_task_name) { 'reset_e_case_id' }
  subject { ResetECaseId.new(given_task_name, double(:current_scope => nil)) }

  describe 'given a task name' do
    it 'has the given task name' do
      expect(subject.name).to eql given_task_name
    end
  end

  describe 'disassociating e_case_id for primary_family of a given hbx_id' do

    let(:family) { FactoryBot.create(:family, :with_primary_family_member)}
    let(:hbx_enrollment) { FactoryBot.create(:hbx_enrollment, household: family.active_household)}

    it 'should unset e_case_id for primary_family' do
      ClimateControl.modify hbx_id: family.primary_family_member.hbx_id do
        family.e_case_id = 'urn:openhbx:hbx:dc0:resources:v1:curam:integrated_case#3554419'
        family.save
        subject.migrate
        family.reload
        expect(family.e_case_id).to eq nil
      end
    end
  end
end
