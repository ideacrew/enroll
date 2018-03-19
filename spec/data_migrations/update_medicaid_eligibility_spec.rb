require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "update_medicaid_eligibility")

describe UpdateMedicaidEligibility, dbclean: :after_each do

  let(:given_task_name) { "update_medicaid_eligibility" }
  subject { UpdateMedicaidEligibility.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "updating medicaid eligibility for a person" do

    let!(:person100) { FactoryGirl.create(:person, :with_family)}
    let!(:family) { person100.primary_family }
    let!(:tax_household) { FactoryGirl.create(:tax_household, household: family.households.first, effective_ending_on: nil)}
    let!(:tax_household_member) { tax_household.tax_household_members.create!(applicant_id: family.family_members.first.id, is_medicaid_chip_eligible: false) }

    before(:each) do
      allow(ENV).to receive(:[]).with("primary_id").and_return(person100.hbx_id)
      allow(ENV).to receive(:[]).with("dependents_ids").and_return(person100.hbx_id)
      allow(ENV).to receive(:[]).with("eligiblility_year").and_return(tax_household.effective_starting_on.year)
    end

    it "should update medicaid eligibility" do
      expect(tax_household_member.is_medicaid_chip_eligible).to eq false
      subject.migrate
      tax_household_member.reload
      expect(tax_household_member.is_medicaid_chip_eligible).to eq true
    end
  end
end
