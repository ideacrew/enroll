require 'rails_helper'

describe "insured/plan_shoppings/_coverage_information.html.slim", dbclean: :after_each do

  let(:person) {FactoryBot.create(:person)}
  let(:family) { FactoryBot.create(:family, :with_primary_family_member)}
  let(:active_household) {family.active_household}
  let(:hbx_enrollment_member){ FactoryBot.build(:hbx_enrollment_member, is_subscriber:true, applicant_id: family.family_members.first.id, coverage_start_on: TimeKeeper.date_of_record, eligibility_date: TimeKeeper.date_of_record) }
  let!(:enrollment) { FactoryBot.create(:hbx_enrollment,household: active_household, family: family, hbx_enrollment_members:[hbx_enrollment_member])}
  let(:member_enrollment) {BenefitSponsors::Enrollments::MemberEnrollment.new(member_id:hbx_enrollment_member.id,product_price:BigDecimal(100),sponsor_contribution:BigDecimal(100))}
  let(:group_enrollment) {double(member_enrollments:[member_enrollment], product_cost_total:0.0,sponsor_contribution_total:0.0, employee_cost_total:0.0)}
  let(:member_group) {double(group_enrollment:group_enrollment)}

  before :each do
    assign(:enrollment, enrollment)
    assign(:member_group, member_group)
  end

  it "when enrollment is single plan sponosored benefit should return dash for premium & employer contribution" do
    allow(enrollment).to receive(:composite_rated?).and_return(true)
    render "insured/plan_shoppings/coverage_information", enrollment: enrollment
    expect(rendered).to have_selector('td', text: "--")
  end

  it "when enrollment is not a single plan sponosored benefit should return amount for premium & employer contribution" do
    allow(enrollment).to receive(:composite_rated?).and_return(false)
    render "insured/plan_shoppings/coverage_information", enrollment: enrollment
    expect(rendered).to have_selector('td', text: 0.0)
  end

  it "should display osse amount if the enrollment has an osse subsidy" do
    enrollment.update_attributes!(eligible_child_care_subsidy: 10.0)
    allow(enrollment).to receive(:composite_rated?).and_return(false)
    render "insured/plan_shoppings/coverage_information", enrollment: enrollment
    expect(rendered).to have_selector('td', text: 10.0)
    expect(rendered).to have_content(l10n("osse_subsidy_title_shortname"))
  end

  it "should not display osse amount if the enrollment does not have an osse subsidy" do
    allow(enrollment).to receive(:composite_rated?).and_return(false)
    render "insured/plan_shoppings/coverage_information", enrollment: enrollment
    expect(rendered).to_not have_content(l10n('program_assistance'))
    expect(rendered).to_not have_content(l10n("osse_subsidy_title_shortname"))
  end
end
