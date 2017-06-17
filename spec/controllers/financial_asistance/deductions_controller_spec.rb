require 'rails_helper'

RSpec.describe FinancialAssistance::DeductionsController, type: :controller do
	let(:person) { FactoryGirl.create(:person)}
  let(:family) { FactoryGirl.create(:family, :with_primary_family_member,person: person) }

  context "deleting a deduction" do
  	before(:each) do
  		family.applications.create!
  	end

	  it "should remove the deduction instance and decrease count by 1" do
	  	applicant = family.application_in_progress.applicants.create!({family_member_id: family.primary_applicant.id})
	    income = applicant.deductions.create!({kind: "alimony_paid", frequency_kind: "weekly", amount: 1000, start_on: TimeKeeper.date_of_record, end_on: TimeKeeper.date_of_record + 7.days})
	    expect(applicant.deductions.size).to eq 1
	    income.destroy
	    expect(applicant.deductions.size).to eq 0
	  end
 	end
end
