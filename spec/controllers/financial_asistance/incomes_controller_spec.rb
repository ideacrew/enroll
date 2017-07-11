require 'rails_helper'

RSpec.describe FinancialAssistance::IncomesController, type: :controller do
  let(:person) { FactoryGirl.create(:person)}
  let(:family) { FactoryGirl.create(:family, :with_primary_family_member,person: person) }

  context "deleting an income" do
  	before(:each) do
  		family.applications.create!
  	end

    it "should remove the income instance and decrease count by 1" do
    	applicant = family.application_in_progress.applicants.create!({family_member_id: family.primary_applicant.id})
      income = applicant.incomes.create!({kind: "wages_and_salaries", frequency_kind: "weekly", amount: 1000, start_on: TimeKeeper.date_of_record, end_on: TimeKeeper.date_of_record + 7.days})
      expect(applicant.incomes.size).to eq 1
      income.destroy
      expect(applicant.incomes.size).to eq 0
    end
  end
end

