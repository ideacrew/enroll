require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "update_tax_households")
describe UpdateTaxHouseholds, dbclean: :after_each do

  let(:given_task_name) {"update_effective_ending_on"}
  subject {UpdateTaxHouseholds.new(given_task_name, double(:current_scope => nil))}

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end
  describe "Update tax household effective ending on date" do

    let!(:eligibility_date) {TimeKeeper.datetime_of_record}
    let!(:family) {FactoryGirl.create(:family, :with_primary_family_member)}
    let!(:tax_household) {FactoryGirl.create(:tax_household, household: family.active_household, effective_starting_on: Date.new(2017, 1, 1), effective_ending_on: nil, is_eligibility_determined: true)}
    let!(:eligibility_determination) {FactoryGirl.create(:eligibility_determination, tax_household: tax_household, determined_at: eligibility_date,
                                                         determined_on: eligibility_date,
                                                         max_aptc: {"cents" => 283.00, "currency_iso" => "USD"})}

    let!(:family2) {FactoryGirl.create(:family, :with_primary_family_member)}
    let!(:tax_household2) {FactoryGirl.create(:tax_household, household: family2.active_household, effective_starting_on: Date.new(TimeKeeper.date_of_record.year, 1, 1), effective_ending_on: Date.new(TimeKeeper.date_of_record.year, 12, 31))}
    let!(:eligibility_determination2) {FactoryGirl.create(:eligibility_determination, tax_household: tax_household2, determined_at: eligibility_date,
                                                          determined_on: eligibility_date,
                                                          max_aptc: {"cents" => 50.00, "currency_iso" => "USD"})}

    let!(:family3) {FactoryGirl.create(:family, :with_primary_family_member)}
    let!(:tax_household3) {FactoryGirl.create(:tax_household, household: family3.active_household, effective_starting_on: Date.new(TimeKeeper.date_of_record.year-1, 1, 1), effective_ending_on: Date.new(TimeKeeper.date_of_record.year-1, 12, 31))}
    let!(:eligibility_determination3) {FactoryGirl.create(:eligibility_determination, tax_household: tax_household3, determined_at: eligibility_date,
                                                          determined_on: eligibility_date,
                                                          max_aptc: {"cents" => 1.00, "currency_iso" => "USD"})}

    let!(:family4) {FactoryGirl.create(:family, :with_primary_family_member)}
    let!(:tax_household4) {FactoryGirl.create(:tax_household, household: family4.active_household, effective_starting_on: Date.new(2017, 1, 1), effective_ending_on: Date.new(2017, 1, 31))}
    let!(:eligibility_determination4) {FactoryGirl.create(:eligibility_determination, tax_household: tax_household4, determined_at: eligibility_date,
                                                          determined_on: eligibility_date,
                                                          max_aptc: {"cents" => 3.00, "currency_iso" => "USD"})}

    let!(:family5) {FactoryGirl.create(:family, :with_primary_family_member)}
    let!(:tax_household5) {FactoryGirl.create(:tax_household, household: family5.active_household, effective_starting_on: Date.new(2018, 1, 1), effective_ending_on: nil)}
    let!(:eligibility_determination5) {FactoryGirl.create(:eligibility_determination, tax_household: tax_household5, determined_at: eligibility_date,
                                                          determined_on: eligibility_date,
                                                          max_aptc: {"cents" => 100.00, "currency_iso" => "USD"})}

    it "should be nil if the effective_ending_on is nil" do
      allow(ENV).to receive(:[]).with("tax_household_year").and_return TimeKeeper.date_of_record.year
      th=tax_household
      expect(th.effective_ending_on).to eq nil
      subject.migrate
      family.reload
      th.reload
      expect(th.effective_ending_on).to eq nil
    end

    it "should be updated if the effective_starting_on is same as current year" do
      allow(ENV).to receive(:[]).with("tax_household_year").and_return TimeKeeper.date_of_record.year
      th=tax_household2
      expect(th.effective_starting_on.year).to eq TimeKeeper.date_of_record.year
      expect(th.effective_ending_on).not_to eq nil
      subject.migrate
      family.reload
      th.reload
      expect(th.effective_ending_on).to eq nil
    end

    it "should not be updated if the effective_starting_on is not same as current year" do
      allow(ENV).to receive(:[]).with("tax_household_year").and_return TimeKeeper.date_of_record.year-1
      th=tax_household3
      expect(th.effective_starting_on.year).to eq TimeKeeper.date_of_record.year-1
      subject.migrate
      family.reload
      th.reload
      expect(th.effective_ending_on).not_to eq nil
    end
  end
end
