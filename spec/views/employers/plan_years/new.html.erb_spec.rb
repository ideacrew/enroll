require "rails_helper"

RSpec.describe "employers/plan_years/new.html.erb" do
  let(:employer_profile){FactoryGirl.create(:employer_profile)}
  let(:plan_year){FactoryGirl.create(:plan_year, employer_profile: employer_profile)}

  before(:each) do
    plan_year.benefit_groups.build
    assign(:plan_year, plan_year)
    controller.request.path_parameters[:employer_profile_id] = employer_profile.id
    stub_template "shared/_reference_plans_list.html.erb" => ""
    render :template => "employers/plan_years/new.html.erb"
  end

  it "should show the title of Benefit Groups" do
    expect(rendered).to match /Benefit Groups/
  end

  it "displays six relationship benefits" do
    %w(employee child_26_and_over spouse domestic_partner child_under_26 disabled_child_26_and_over).each do |kind|
      expect(rendered).to match /#{kind}/
    end
  end
end
