# frozen_string_literal: true

require 'rails_helper'
require File.join(Rails.root, 'spec/shared_contexts/ivl_eligibility')

describe 'fix_ed_source_curam_cases' do
  before do
    DatabaseCleaner.clean
  end
  include_context 'setup one tax household with one ia member'

  context 'valid curam determination' do
    before :each do
      eligibilty_determination.assign_attributes({e_pdc_id: '3023385'})
      eligibilty_determination.save!(validate: false)
<<<<<<< HEAD
      subject.migrate
      @file_content = CSV.read("#{Rails.root}/list_of_ed_object_ids_for_curam_cases_1.csv")
=======
      invoke_fix_ed_source_curam_cases
      @file_content = CSV.read("#{Rails.root}/list_of_ed_object_ids_for_curam_cases.csv")
>>>>>>> parent of 165afbdce5... Merge remote-tracking branch 'origin/surge_integration_5/22' into ops_release_branch
    end

    it 'should add data to the file' do
      expect(@file_content.size).to be > 1
    end

    it 'should match with the person hbx_id' do
      expect(@file_content[1][0]).to eq(person.hbx_id)
    end

    it 'should match with the ed_object_id' do
      expect(@file_content[1][1]).to eq(eligibilty_determination.id.to_s)
    end

    it 'should match with the expected source' do
      expect(@file_content[1][2]).to eq('Curam')
    end

    it 'should add e_pdc_id data' do
      expect(@file_content[1][3]).to be_truthy
    end

    it 'should update the eligibilty_determination object' do
      expect(eligibilty_determination.source).to eq('Curam')
    end
  end

  context 'invalid curam determination' do
    context 'with e_pdc_id nil' do
      before do
        eligibilty_determination.assign_attributes({e_pdc_id: nil, source: 'Admin'})
        eligibilty_determination.save!(validate: false)
<<<<<<< HEAD
        subject.migrate
=======
        invoke_fix_ed_source_curam_cases
        @file_content = CSV.read("#{Rails.root}/list_of_ed_object_ids_for_curam_cases.csv")
>>>>>>> parent of 165afbdce5... Merge remote-tracking branch 'origin/surge_integration_5/22' into ops_release_branch
      end

      it 'should not update the eligibilty_determination object' do
        expect(eligibilty_determination.source).not_to eq('Curam')
      end
    end

    context 'with e_pdc_id MANUALLY_9_2_2016LOADING530' do
      before do
        eligibilty_determination.assign_attributes({e_pdc_id: 'MANUALLY_9_2_2016LOADING530', source: 'Admin'})
        eligibilty_determination.save!(validate: false)
<<<<<<< HEAD
        subject.migrate
=======
        invoke_fix_ed_source_curam_cases
        @file_content = CSV.read("#{Rails.root}/list_of_ed_object_ids_for_curam_cases.csv")
>>>>>>> parent of 165afbdce5... Merge remote-tracking branch 'origin/surge_integration_5/22' into ops_release_branch
      end

      it 'should not update the eligibilty_determination object' do
        expect(eligibilty_determination.source).not_to eq('Curam')
      end
    end
  end

  after :each do
    FileUtils.rm_rf("#{Rails.root}/list_of_ed_object_ids_for_curam_cases_1.csv")
  end
end

def invoke_fix_ed_source_curam_cases
  fix_ed_source_curam_cases = File.join(Rails.root, 'app/data_migrations/fix_ed_source_curam_cases.rb')
  load fix_ed_source_curam_cases
end
