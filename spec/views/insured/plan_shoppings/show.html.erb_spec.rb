require "rails_helper"

RSpec.describe "insured/show" do

  let(:employee_role){FactoryGirl.create(:employee_role)}
  let(:plan){FactoryGirl.create(:plan)}
  let(:benefit_group){ FactoryGirl.build(:benefit_group) }
  let(:hbx_enrollment){ HbxEnrollment.new(benefit_group: benefit_group,
    hbx_enrollment_members: [],
    employee_role: employee_role,
    effective_on: 1.month.ago.to_date, updated_at: DateTime.now  ) }
  let(:broker_person){ FactoryGirl.create(:person, :first_name=>'fred', :last_name=>'flintstone')}
  
  let(:current_broker_user) { FactoryGirl.create(:user, :roles => ['broker_agency_staff'],
 		:person => broker_person) }
  before :each do
    allow(hbx_enrollment).to receive(:humanized_dependent_summary).and_return(2)
    @person = employee_role.person
    @plan = plan
    @enrollment = hbx_enrollment
    @hbx_enrollment = hbx_enrollment
    @benefit_group = @enrollment.benefit_group
    @reference_plan = @benefit_group.reference_plan
    @plan = PlanCostDecorator.new(@plan, @enrollment, @benefit_group, @reference_plan)
    @plans=[]
    stub_template "insured/plan_shoppings/_plan_details.html.erb" => []
    stub_template "shared/_signup_progress.html.erb" => ''
    stub_template "insured/_plan_filters.html.erb" => ''
  end

  it 'should display information about the employee' do
    render :template => "insured/plan_shoppings/show.html.erb"
    expect(rendered).to have_selector('p', text:  @person.full_name)
    expect(rendered).to have_selector('p', text:  @benefit_group.plan_year.employer_profile.dba)
  end

end