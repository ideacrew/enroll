require "rails_helper"

RSpec.describe "insured/plan_shoppings/receipt.html.erb" do

  def new_member
    random_value = rand(999_999_999)
    instance_double(
      "HbxEnrollmentMember",
      primary_relationship: "self:#{random_value}",
      person: new_person(random_value)
    )
  end

  def enrollment
    instance_double(
      "HbxEnrollment",
      updated_at: TimeKeeper.date_of_record,
      hbx_enrollment_members: members,
      effective_on: TimeKeeper.date_of_record.beginning_of_month,
      plan: new_plan,
      is_cobra_status?: false,
      coverage_kind: 'health',
      hbx_id: "3939393",
      is_shop?: true,
      employee_role: double("EmployeeRole"),
      composite_rated?: true
    )
  end

  def new_person(random_value)
    instance_double(
      "Person",
      full_name: "John Doe:#{random_value}",
      age_on: 21,
      dob: double("dob")
    )
  end

  def new_plan
    double(
      "Plan",
      title: "My Silly Plan",
      name: "My Silly Plan",
      carrier_profile: carrier_profile
    )
  end

  def plan_cost_decorator
    double(
      "PlanCostDecorator",
      title: new_plan.title,
      premium_for: double("premium_for"),
      employer_contribution_for: double("employer_contribution_for"),
      employee_cost_for: double("employee_cost_for"),
      total_premium: double("total_premium"),
      total_employer_contribution: double("total_employer_contribution"),
      total_employee_cost: double("total_employee_cost"),
      issuer_profile: double(legal_name: "carefirst"),
      metal_level: "Silver",
      coverage_kind: "health",
      kind: "health",
      name: new_plan.name,
      metal_level_kind: ''
    )
  end

  let(:members) { [new_member, new_member] }
  let(:carrier_profile){ double("CarrierProfile", legal_name: "my legal name") }

  let(:member_enrollment) {BenefitSponsors::Enrollments::MemberEnrollment.new(member_id:'',product_price:BigDecimal(100),sponsor_contribution:BigDecimal(100))}
  let(:group_enrollment) {double(member_enrollments:[member_enrollment], product_cost_total:0.0,sponsor_contribution_total:0.0, employee_cost_total:0.0)}
  let(:member_group) {double(group_enrollment:group_enrollment)}

  before :each do
    assign :enrollment, enrollment
    assign :member_group, member_group
    @plan = plan_cost_decorator

    allow(@plan).to receive(:sole_source?).and_return(true)
    allow(view).to receive(:policy_helper).and_return(double('FamilyPolicy', updateable?: true))
    allow(view).to receive(:policy_helper).and_return(double('FamilyPolicy', can_access_progress?: true))
    allow(view).to receive(:show_pay_now?).and_return false
    render file: "insured/plan_shoppings/receipt.en.html.erb"
  end

  it "should match the data on the confirmation receipt" do
    #expect(rendered).to have_selector('p', text: "Your enrollment has been submitted as of #{enrollment.updated_at}.")
    expect(rendered).to have_selector('p', text: /Your enrollment has been submitted as/)
    expect(rendered).to have_selector('p', text: /Please print this page for your records. A copy of this confirmation/)
  end

  it "should match the enrollment memebers" do
    enrollment.hbx_enrollment_members.each do |enr_member|
      expect(rendered).to match(/#{enr_member.person.full_name}/m)
      expect(rendered).to match(/#{enr_member.primary_relationship}/m)
      expect(rendered).to match(/#{dob_in_words(enr_member.person.age_on(Time.now.utc.to_date),enr_member.person.dob)}/m)
      expect(rendered).to match(/#{@plan.premium_for(enr_member)}/m)
      expect(rendered).to match(/#{@plan.employer_contribution_for(enr_member)}/m)
      expect(rendered).to match(/#{@plan.employee_cost_for(enr_member)}/m)
      expect(rendered).to match(/#{@plan.total_premium(enr_member)}/m)
      expect(rendered).to match(/#{@plan.total_employer_contribution(enr_member)}/m)
      expect(rendered).to match(/#{@plan.total_employee_cost(enr_member)}/m)
    end
  end

  it "should have print area" do
    expect(rendered).to have_selector('#printArea')
    expect(rendered).to have_selector('a#btnPrint')
  end

  it "should have market" do
    expect(rendered).to match('Market')
    expect(rendered).to match('Employer Sponsored')
  end

  it "should not have cobra msg" do
    expect(rendered).not_to match("Your employer may charge an additional administration fee for your COBRA/Continuation coverage. If you have any questions, please direct them to the Employer")
  end

  context "doesn't have a Pay Now option and messaging" do
    before do
      allow(view).to receive(:show_pay_now?).and_return false
    end
    it "doesn't have a Pay now button" do
      render file: "insured/plan_shoppings/receipt.en.html.erb"
      expect(rendered).to_not have_selector('btn-btn-default', text: /Pay Now/)
    end

    it "doesn't have Pay Now messaging" do
      render file: "insured/plan_shoppings/receipt.en.html.erb"
      expect(rendered).to_not have_content(/Select PAY NOW to make your first premium payment online/)
      expect(rendered).to_not have_content(/Select PAY NOW to make your first premium payment directly to Kaiser Permanente/)
    end
  end

  context "have Pay Now options and messaging" do
    let!(:user){FactoryBot.create(:user)}
    let!(:person){FactoryBot.create(:person, user: user)}
    before do
      sign_in(user)
      allow(view).to receive(:show_pay_now?).and_return true
    end

    it "should have a Pay now button" do
      render file: "insured/plan_shoppings/receipt.en.html.erb"
      expect(rendered).to have_selector('button', text: /Pay Now/)
    end
  end
end
