require 'rails_helper'

describe "shared/_my_portal_links.html.haml" do
  before :each do
    sign_in(user)
    render 'shared/my_portal_links'
  end

  context "with emploee role" do
    let(:user) { FactoryGirl.create(:user, person: person, roles: ["employee"]) }
    let(:person) { FactoryGirl.create(:person, :with_employee_role)}

    it "should have one portal link" do
      expect(rendered).to have_content('My Insured Portal')
    end

    it "should not have a dropdown" do
      expect(rendered).to_not have_selector('dropdownMenu1')
    end

  end

  context "with employer role & employee role" do
    let(:user) { FactoryGirl.create(:user, person: person, roles: ["employee", "employer_staff"]) }
    let(:person) { FactoryGirl.create(:person, :with_employee_role, :with_employer_staff_role)}

    it "should have one portal link" do
      expect(rendered).to have_content('My Insured Portal')
      expect(rendered).to have_content('My Employer Portal')
    end

    it "should have a dropdown" do
      expect(rendered).to have_selector('.dropdown-menu')
    end

  end

end
