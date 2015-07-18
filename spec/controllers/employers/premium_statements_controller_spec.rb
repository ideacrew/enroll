require 'rails_helper'

RSpec.describe Employers::PremiumStatementsController do
  context "GET show" do
    let(:user) { double("User") }
    let(:person) { double("Person") }
    let(:employer_profile) { double("EmployerProfile") }
    let(:current_plan_year) { double("PlanYear", enrolled: []) }
    let(:hbx_enrollments) { [double("HbxEnrollment")] }

    before do
      expect(EmployerProfile).to receive(:find).and_return(employer_profile)
      expect(employer_profile).to receive(:published_plan_year).and_return(current_plan_year)
      expect(current_plan_year).to receive(:hbx_enrollments).and_return(hbx_enrollments)

    end

    it "should return contribution" do
      sign_in(user)
      xhr :get, :show, id: "test"
      expect(response).to have_http_status(:success)
    end
  end

end