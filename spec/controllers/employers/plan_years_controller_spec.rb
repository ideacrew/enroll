require 'rails_helper'

RSpec.describe Employers::PlanYearsController, :dbclean => :after_each do
  describe "create" do
    login_user
    include_context "BradyWork"
    let(:employer_profile) { mikes_employer }
    let(:plan_year) { mikes_plan_year }
    let(:benefit_group) { mikes_benefit_group }
    let(:relationship_benefit) { FactoryGirl.build(:relationship_benefit) }

    context "create" do
      before do
        relationship_benefit_params = relationship_benefit.attributes.to_hash
        benefit_group_params = benefit_group.attributes.to_hash
        benefit_group_params[:relationship_benefits_attributes] = {"0" => relationship_benefit_params}
        @plan_year_params = plan_year.attributes.to_hash
        @plan_year_params[:benefit_groups_attributes] = {"0" => benefit_group_params}
        @plan_year_params.deep_merge!({ start_on: "01/01/2015",
                                        end_on: "12/31/2015",
                                        open_enrollment_start_on: "11/01/2014",
                                        open_enrollment_end_on: "11/30/2014"
                                      })
      end

      it "should create a new plan year with valid params" do
        post :create, plan_year: @plan_year_params, employer_profile_id: employer_profile.id
        expect(employer_profile.plan_years.size).to eq (1)
      end

      it "should not create a new plan year with invalid params" do
        @plan_year_params[:benefit_groups_attributes]["0"]["premium_pct_as_int"] = 30
        post :create, plan_year: @plan_year_params, employer_profile_id: employer_profile.id
        expect(response).to render_template("new")
      end
    end

    context "new" do
      it "should initialize new plan year object" do
        get :new, employer_profile_id: employer_profile.id
        expect(response).to render_template("new")
      end
    end

  end
end
