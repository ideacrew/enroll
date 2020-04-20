require 'rails_helper'
require 'rake'

require File.join(Rails.root, 'app', 'data_migrations', 'delete_duplicate_tax_households')

describe DeleteDuplicateTaxHouseholds, dbclean: :after_each do
  let(:given_task_name) { 'delete_duplicate_tax_households' }

  subject { DeleteDuplicateTaxHouseholds.new(given_task_name, double(:current_scope => nil)) }

  describe 'given a task name' do
    it 'has the given task name' do
      expect(subject.name).to eql given_task_name
    end
  end

  describe 'for a given hxb_id' do
    let(:person) { FactoryBot.create(:person, :with_family) }

    around do |example|
      ClimateControl.modify person_hbx_id: hbx_id do
        example.run
      end
    end


    context 'for an invalid person hbx_id' do
      let(:hbx_id) { 'hbx_id' }

      it 'should do nothing' do
        expect { subject.migrate }.not_to raise_error
      end
    end

    context 'has duplicate tax household' do
      let(:hbx_id) { person.hbx_id }
      let(:household) { person.primary_family.active_household }
      let(:tax_household) { FactoryBot.create(:tax_household, household: household) }
      let(:tax_household2) { FactoryBot.create(:tax_household, household: household) }
      let(:tax_household_member) { FactoryBot.create(:tax_household_member, tax_household: tax_household, family_member: person.primary_family.family_members.first) }
      let(:tax_household_member2) { FactoryBot.create(:tax_household_member, tax_household: tax_household2, family_member: person.primary_family.family_members.first) }

      before do
        tax_household.tax_household_members << tax_household_member
        tax_household2.tax_household_members << tax_household_member2
        household.tax_households << tax_household
        household.tax_households << tax_household2

        person.save!
        subject.migrate
        person.reload
      end

      it 'should delete duplicate tax households' do
        expect { person.primary_family.active_household.tax_households.count.to eq(1) }
      end
    end
  end
end
