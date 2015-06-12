require 'rails_helper'

RSpec.describe Employers::CensusEmployeesController do
  let(:employer_profile_id) { "abecreded" }
  let(:employer_profile) { FactoryGirl.create(:employer_profile) }
  let(:census_employee) {FactoryGirl.create(:census_employee)}
  let(:census_employee_params) {
    {"first_name"=>"aqzz",
       "middle_name"=>"",
       "last_name"=>"White",
       "dob"=>"05/01/2015",
       "ssn"=>"123-12-3112",
       "gender"=>"male",
       "is_business_owner" => true,
       "hired_on"=>"05/02/2015"} }

  describe "GET new" do
    let(:user) { double("user")}

    it "should render the new template" do
      allow(EmployerProfile).to receive(:find).with(employer_profile_id).and_return(employer_profile)
      allow(employer_profile).to receive(:plan_years).and_return("2015")
      sign_in(user)
      get :new, :employer_profile_id => employer_profile_id
      expect(response).to have_http_status(:success)
      expect(response).to render_template("new")
      expect(assigns(:census_employee).class).to eq CensusEmployee
    end

    it "should redirect with no plan_years" do
      allow(EmployerProfile).to receive(:find).with(employer_profile_id).and_return(employer_profile)
      allow(employer_profile).to receive(:plan_years).and_return("")
      sign_in(user)
      get :new, :employer_profile_id => employer_profile_id
      expect(response).to be_redirect
      expect(flash[:notice]).to eq "Please create a plan year before you create your first census employee."
    end
  end

end
