require "rails_helper"
require "pry"

describe 'employee with inactive benefit group assignment' do
  let(:employer_profile)  { FactoryGirl.create(:employer_profile) }
  let(:plan_year)         { FactoryGirl.create(:plan_year, aasm_state: "draft", employer_profile: employer_profile) }
  let(:benefit_group) { FactoryGirl.create(:benefit_group, plan_year: plan_year, title: "first_one")}
  let(:census_employee) { FactoryGirl.create(:census_employee, employer_profile_id: employer_profile.id)}
  let(:renew_benefit) { census_employee.add_renew_benefit_group_assignment(benefit_group) }
  
  context "expect an inactive benfit group then change to is_active state" do
    it "should be inactive" do
      expect(renew_benefit.first.is_active).to eq false
    end
    
    it "should now be active" do
      renew_benefit.update(is_active:true)
      expect(renew_benefit.first.is_active).to eq true
    end
  end
end