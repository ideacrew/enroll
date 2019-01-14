require "rails_helper"

RSpec.describe "employers/plan_years/_reference_plan_summary_modal.html.erb" do
  let(:employer_profile){FactoryBot.create(:employer_profile)}
  let(:plan) { FactoryBot.create(:plan) }
  before(:each) do
    assign(:employer_profile, employer_profile)
    assign(:plan, plan)
    assign(:employer_profile_id, employer_profile.id)
    @plan = plan
    @visit_types = []
    @coverage_kind = 'health'
    @hios_id = '1203940129312'
    @reference_plan_id = plan.id
    @employer_profile_id = employer_profile.id
    @start_on = 2016
  end

  it "it should display the titles " do
    render partial: "employers/plan_years/reference_plan_summary_modal"
    expect(rendered).to have_selector('th', count: 3)
  end

  it "it should not have the modal-body-swap class" do
    render partial: "employers/plan_years/reference_plan_summary_modal"
    expect(rendered).to_not have_selector('.modal-body-swap')
  end

  it "it should have the modal-body-swap class" do
    assign(:details, 'details')
    render partial: "employers/plan_years/reference_plan_summary_modal"
    expect(rendered).to have_selector('.modal-body-swap')
  end

end
