require "rails_helper"

RSpec.describe "insured/thankyou.html.erb" do

  let(:employee_role){FactoryGirl.create(:employee_role)}
  let(:plan){FactoryGirl.create(:plan)}
  let(:benefit_group){ FactoryGirl.build(:benefit_group) }
  let(:hbx_enrollment){ HbxEnrollment.new(benefit_group: benefit_group, employee_role: employee_role, effective_on: 1.month.ago.to_date, updated_at: DateTime.now  ) }

  before :each do
    @person = employee_role.person
    @plan = plan
    @enrollment = hbx_enrollment
    @benefit_group = @enrollment.benefit_group
    @reference_plan = @benefit_group.reference_plan
    @plan = PlanCostDecorator.new(@plan, @enrollment, @benefit_group, @reference_plan)
    render :template => "insured/plan_shoppings/thankyou.html.erb"
  end

  it 'should display the correct plan selection text' do
    expect(rendered).to have_selector('h3', text: 'Confirm Your Plan Selection')
    expect(rendered).to have_selector('p', text: 'Your current plan selection is displayed below. Click the back button if you want to change your selection. Click Purchase button to complete your enrollment.')
    expect(rendered).to have_selector('p', text: 'Your enrollment is not complete until you purchase your plan selection below.')
  end

  it "should match the data from the plan confirmation popup" do
    expect(rendered).to have_selector('p', text: "Your purchase of #{@plan.name} was completed on #{@enrollment.updated_at}.")
    expect(rendered).to have_selector('p', text: "Please print this page for your records.")
    expect(rendered).to have_selector('p', text: "A copy of this confirmation has also been emailed to you.")
    expect(rendered).to have_selector('p', text: "Clicking the Continue button will confirm your purchase.")
  end
end
