# frozen_string_literal: true

require 'rails_helper'
require File.join(Rails.root, 'app', 'data_migrations', 'migrate_thhm_csr_variant')

describe MigrateThhmCsrVariant do

  let(:given_task_name) { 'migrate_thm_csr_variant' }
  subject { MigrateThhmCsrVariant.new(given_task_name, double(:current_scope => nil)) }

  describe 'given a task name' do
    it 'has the given task name' do
      expect(subject.name).to eql given_task_name
    end
  end

  describe 'changing tax household member csr percent' do
    let(:family)  { FactoryBot.create(:family, :with_primary_family_member) }
    let!(:tax_household){ FactoryBot.create(:tax_household, household: family.active_household, effective_ending_on: nil) }
    let!(:tax_household_member) { tax_household.tax_household_members.create!(is_ia_eligible: true, applicant_id: family.family_members[0].id, csr_percent_as_integer: nil) }
    let!(:eligibility_determinations){ FactoryBot.create(:eligibility_determination, tax_household: tax_household, csr_percent_as_integer: '-1') }

    it "should change thhm csr" do
      ed = eligibility_determinations
      th = tax_household
      csr_percent_as_integer = ed.csr_percent_as_integer
      expect(th.latest_eligibility_determination.csr_percent_as_integer).to eq csr_percent_as_integer
      subject.migrate
      family.reload
      th.reload
      expect(th.tax_household_members.first.csr_percent_as_integer).to eq csr_percent_as_integer
    end
  end
end
