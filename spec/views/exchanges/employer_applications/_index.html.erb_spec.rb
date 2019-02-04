require 'rails_helper'

RSpec.describe "exchanges/employer_applications/index.html.erb", dbclean: :after_each do
  let!(:employer_profile) { FactoryGirl.create(:employer_profile) }
  let(:employee_role1) {FactoryGirl.create(:employee_role, person: person, employer_profile: employer_profile)}
  let(:family) { FactoryGirl.create(:family, :with_primary_family_member,person: person) }
  let(:user) { FactoryGirl.create(:user, person: person, roles: ["hbx_staff"]) }
  let(:person) { FactoryGirl.create(:person) }

  context 'When employer has valid plan years' do

    let!(:plan_year) {FactoryGirl.create(:plan_year, employer_profile: employer_profile, aasm_state: 'active')}
    let(:benefit_group) {FactoryGirl.create(:benefit_group, plan_year: plan_year)}
    let(:benefit_group_assignment1) {FactoryGirl.build(:benefit_group_assignment, benefit_group: benefit_group)}
    let(:benefit_group_assignment2) {FactoryGirl.build(:benefit_group_assignment, benefit_group: benefit_group)}
    let(:census_employee1) { FactoryGirl.create(:census_employee, benefit_group_assignments: [benefit_group_assignment1],employee_role_id: employee_role1.id,employer_profile_id: employer_profile.id) }

    before :each do
      sign_in(user)
      assign :employer_profile, employer_profile
      render "exchanges/employer_applications/index", employers_action_id: "employers_action_#{employer_profile.id}"
    end

    it 'should have title' do
      expect(rendered).to have_content('Applications')
    end

    it "should have plan year aasm_state" do
      expect(rendered).to match /#{plan_year.aasm_state}/
    end

    it "should have plan year start date" do
      expect(rendered).to match /#{plan_year.start_on}/
    end

    it "should have cancel, terminate, reinstate links" do
      expect(rendered).to match /cancel/
      expect(rendered).to match /terminate/
      expect(rendered).to match /reinstate/
    end
  end

  context 'When employer doesnt have valid plan years' do

    before :each do
      sign_in(user)
      assign :employer_profile, employer_profile
      render "exchanges/employer_applications/index", employers_action_id: "employers_action_#{employer_profile.id}"
    end

    it 'should have title' do
      expect(rendered).to have_content('Applications')
    end

    it "should have not cancel, terminate, reinstate links" do
      expect(rendered).not_to match /cancel/
      expect(rendered).not_to match /terminate/
      expect(rendered).not_to match /reinstate/
    end
  end
end
