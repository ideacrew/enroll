require "rails_helper"
if ExchangeTestingConfigurationHelper.individual_market_is_enabled?
  require File.join(Rails.root, "app", "data_migrations", "add_new_eligibility_determination")
  describe AddNewEligibilityDetermination, :dbclean => :around_each do
    let(:given_task_name) { "add_new_eligibility_determination" }
    subject { AddNewEligibilityDetermination.new(given_task_name, double(:current_scope => nil)) }
    describe "given a task name" do
      it "has the given task name" do
        expect(subject.name).to eql given_task_name
      end
    end
    describe "add a new eligibility determination to the person" do
      let(:family) {FactoryBot.create(:family, :with_primary_family_member)}
      let!(:tax_household){FactoryBot.create(:tax_household, household:family.active_household,effective_ending_on: nil)}
      let!(:eligibility_determinations){FactoryBot.create(:eligibility_determination, tax_household:tax_household)}
      context "add a new eligibility determination to the person" do
        it "should change person' csr" do
          ClimateControl.modify :effective_date => (TimeKeeper.datetime_of_record+1.day).to_s, :csr_percent_as_integer => 50.to_s, :max_aptc => 200.to_s, :hbx_id => family.person.hbx_id do
            ed = eligibility_determinations
            th = tax_household
            expect(th.latest_eligibility_determination.csr_percent_as_integer).to eq ed.csr_percent_as_integer
            expect(th.latest_eligibility_determination.csr_percent).to eq ed.csr_percent
            subject.migrate
            family.reload
            th.reload
            expect(th.latest_eligibility_determination.csr_percent_as_integer).to eq 50
            expect(th.latest_eligibility_determination.csr_percent).to eq 0.5
          end
        end
      end
      context "change person's aptc" do
        it "should change person' csr" do
          ClimateControl.modify :effective_date => (TimeKeeper.datetime_of_record+1.day).to_s, :csr_percent_as_integer => 50.to_s, :max_aptc => 200.to_s, :hbx_id => family.person.hbx_id do
            ed = eligibility_determinations
            th = tax_household
            expect(th.latest_eligibility_determination.max_aptc).to eq ed.max_aptc
            subject.migrate
            family.reload
            th.reload
            expect(th.latest_eligibility_determination.max_aptc).to eq Money.new(20000)
          end
        end
      end
    end
  end
end

