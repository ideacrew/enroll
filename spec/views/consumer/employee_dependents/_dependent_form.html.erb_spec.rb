require 'rails_helper'

describe "consumer/employee_dependents/_dependent_form.html.erb" do
  let(:person) { FactoryGirl.create(:person) }
  let(:user) { FactoryGirl.create(:user, person: person) }
  let(:family) { Family.new }
  let(:family_member) { family.family_members.new }
  let(:dependent) { Forms::EmployeeDependent.new(family_id: family.id) }

  context "with consumer_role_id" do
    before :each do
      sign_in user
      @request.env['HTTP_REFERER'] = 'consumer_role_id'
      render "consumer/employee_dependents/dependent_form", dependent: dependent, person: person
    end

    it "should have dependent_list area" do
      expect(rendered).to have_selector("li.dependent_list")
    end

    it "should have required for ssn" do
      expect(rendered).to have_selector('input[placeholder="SOCIAL SECURITY *"]')
      expect(rendered).to have_selector('input[required="required"]')
    end

    it "should have consumer_fields area" do
      expect(rendered).to have_selector("div#consumer_fields")
    end
  end
end
