require 'rails_helper'

RSpec.describe "events/hbx_enrollment/policy.haml.erb", dbclean: :after_each do
  let(:benefit_sponsorship) {  FactoryBot.create :benefit_sponsors_benefit_sponsorship, :with_benefit_market, :with_organization_cca_profile, :with_initial_benefit_application }
  let!(:benefit_application) { benefit_sponsorship.benefit_applications.first }
  let!(:issuer_profile)  { FactoryBot.create(:benefit_sponsors_organizations_issuer_profile) }
  let!(:product) { FactoryBot.create(:benefit_markets_products_health_products_health_product,issuer_profile: issuer_profile) }
  let(:census_employee) { FactoryBot.build(:census_employee, :benefit_group_assignments => [FactoryBot.build(:benefit_group_assignment)]) }
  let(:employee_role) { FactoryBot.build(:employee_role, census_employee: census_employee) }
  let(:benefit_group_assignment) { employee_role.census_employee.benefit_group_assignments.first }
  let(:person) { FactoryBot.create(:person)}
  let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person)}
  let(:hbx_enrollment_member) { FactoryBot.build(:hbx_enrollment_member, applicant_id: family.primary_family_member.id, is_subscriber: true, eligibility_date: TimeKeeper.date_of_record)}
  let!(:hbx_enrollment) { FactoryBot.create(:hbx_enrollment,rating_area_id: benefit_application.recorded_rating_area_id,
                                             sponsored_benefit_id: benefit_application.benefit_packages.first.health_sponsored_benefit.id ,
                                             sponsored_benefit_package_id:benefit_application.benefit_packages.first.id,
                                             benefit_sponsorship_id:benefit_application.benefit_sponsorship.id,
                                             household: family.active_household, employee_role: employee_role,
                                             family: family,
                                             created_at: Time.now,hbx_enrollment_members:[hbx_enrollment_member],
                                             product_id: product.id
  )}

  let(:cobra_begin_date) { Date.new(2016,2,1) }
  let(:member_enrollment) {BenefitSponsors::Enrollments::MemberEnrollment.new(member_id:hbx_enrollment_member.id,product_price:BigDecimal(100),sponsor_contribution:BigDecimal(100))}

  let(:decorated_hbx_enrollment) do
    BenefitSponsors::Enrollments::GroupEnrollment.new(
      sponsor_contribution_total: BigDecimal(200),
      product_cost_total: BigDecimal(300),
      product_cost_total_with_subsidy: BigDecimal(200),
      member_enrollments: [member_enrollment]
    )
  end

  before :each do
    allow(hbx_enrollment).to receive(:broker_agency_account).and_return(nil)
    allow(census_employee).to receive(:cobra_begin_date).and_return(cobra_begin_date)
    allow(hbx_enrollment).to receive(:effective_on).and_return(cobra_begin_date)
    allow(hbx_enrollment).to receive(:cobra_eligibility_date).and_return(cobra_begin_date)
    allow(hbx_enrollment).to receive(:is_cobra_status?).and_return(true)
    allow(hbx_enrollment).to receive(:decorated_hbx_enrollment).and_return(decorated_hbx_enrollment)
  end

  it "generates a policy cv with policy, enrollees and plan elements" do
    render :template=>"events/hbx_enrollment/_policy", :locals=>{hbx_enrollment: hbx_enrollment}
    expect(rendered).to include("</policy>")
    expect(rendered).to include("<enrollees>")
    expect(rendered).to include("<plan>")
    expect(rendered).to include("<premium_total_amount>")
    expect(rendered).to include("<total_responsible_amount>")
  end

  it "includes the special carrier id" do
    special_plan_id_prefix = Settings.aca.carrier_special_plan_identifier_namespace
    special_plan_id = "abcdefg"
    expected_special_plan_id = special_plan_id_prefix + special_plan_id
    product.update_attributes(issuer_assigned_id:special_plan_id)
    render :template=>"events/hbx_enrollment/_policy", :locals=>{hbx_enrollment: hbx_enrollment}
    expect(rendered).to have_selector("plan id alias_ids alias_id id", :text => expected_special_plan_id)
  end

  context "cobra enrollment" do

    before do
      allow(hbx_enrollment).to receive(:kind).and_return("employer_sponsored_cobra")
      render :template=>"events/hbx_enrollment/_policy", :locals=>{hbx_enrollment: hbx_enrollment}
      @doc = Nokogiri::XML(rendered)
    end

    it "should include cobra event type & eligibilty date" do
      expect(@doc.xpath("//event_kind").text).to eq "urn:dc0:terms:v1:qualifying_life_event#cobra"
      expect(@doc.xpath("//cobra_eligibility_date").text).to eq cobra_begin_date.strftime("%Y%m%d")
    end
  end

  context "ivl enrollment with unknown_sep" do

    before do
      allow(hbx_enrollment).to receive(:enrollment_kind).and_return("special_enrollment")
      render :template=>"events/hbx_enrollment/policy", :locals=>{hbx_enrollment: hbx_enrollment}
      @doc = Nokogiri::XML(rendered)
    end

    it "should include exceptional_circumstances event type for unknowsep value" do
      expect(hbx_enrollment.eligibility_event_kind).to eq("unknown_sep")
      expect(@doc.xpath("//x:event_kind", "x"=>"http://openhbx.org/api/terms/1.0").text).to eq "urn:dc0:terms:v1:qualifying_life_event#exceptional_circumstances"
    end
  end
end
