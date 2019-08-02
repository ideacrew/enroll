require 'rails_helper'

RSpec.describe "app/views/events/shared/affected_member.xml.haml", dbclean: :after_each do
  let(:benefit_sponsorship) {  FactoryBot.create :benefit_sponsors_benefit_sponsorship, :with_benefit_market, :with_organization_cca_profile, :with_initial_benefit_application }
  let!(:benefit_application) { benefit_sponsorship.benefit_applications.first }
  let!(:issuer_profile)  { FactoryBot.create(:benefit_sponsors_organizations_issuer_profile) }
  let!(:product) { FactoryBot.create(:benefit_markets_products_health_products_health_product,issuer_profile: issuer_profile) }
  let(:census_employee) { FactoryBot.build(:census_employee, :benefit_group_assignments => [FactoryBot.build(:benefit_group_assignment)]) }
  let(:employee_role) { FactoryBot.build(:employee_role, census_employee: census_employee) }
  let(:benefit_group_assignment) { employee_role.census_employee.benefit_group_assignments.first }
  let(:person) { FactoryBot.create(:person)}
  let(:dep_person) { FactoryBot.create(:person)}
  let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person)}
  let(:hbx_enrollment_member) { FactoryBot.build(:hbx_enrollment_member, applicant_id: family.primary_family_member.id, is_subscriber: true, eligibility_date: TimeKeeper.date_of_record)}

  let!(:family_member) do
    fm = FactoryBot.build(:family_member, person: dep_person, family: family, is_primary_applicant: false, is_consent_applicant: true)
    family.family_members << [fm]
    fm
  end

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

  let(:decorated_hbx_enrollment) {
    BenefitSponsors::Enrollments::GroupEnrollment.new(sponsor_contribution_total:BigDecimal(200),product_cost_total:BigDecimal(300),member_enrollments:[member_enrollment])
  }

  # let(:hbx_enrollment_member) {hbx_enrollment.hbx_enrollment_members.first}

  before :each do
    allow(hbx_enrollment).to receive(:broker_agency_account).and_return(nil)
    allow(census_employee).to receive(:cobra_begin_date).and_return(cobra_begin_date)
    allow(hbx_enrollment).to receive(:effective_on).and_return(cobra_begin_date)
    allow(hbx_enrollment).to receive(:cobra_eligibility_date).and_return(cobra_begin_date)
    allow(hbx_enrollment).to receive(:is_cobra_status?).and_return(true)
    allow(hbx_enrollment).to receive(:decorated_hbx_enrollment).and_return(decorated_hbx_enrollment)
  end

  context "ivl enrollment with responsible party" do

    before do
      dep_mem = family.family_members.where(is_primary_applicant:'false').first
      enrollment_member = hbx_enrollment.hbx_enrollment_members.first
      enrollment_member.update_attributes(applicant_id: dep_mem.id)
      render :template=>"events/shared/_affected_member", :locals=>{hbx_enrollment:hbx_enrollment, hbx_enrollment_member: enrollment_member, subscriber: enrollment_member}
      @doc = Nokogiri::XML(rendered)
    end

    it "should not include primary_family_id" do
      expect(@doc.xpath("//affected_member//primary_family_id").text).to be_empty
    end
  end

  context "ivl enrollment with primary family" do

    before do
      enrollment_member = hbx_enrollment.hbx_enrollment_members.first
      render :template=>"events/shared/_affected_member", :locals=>{hbx_enrollment:hbx_enrollment, hbx_enrollment_member: enrollment_member, subscriber: enrollment_member}
      @doc = Nokogiri::XML(rendered)
    end

    it "should include primary_family_id" do
      expect(@doc.xpath("//affected_member//primary_family_id").text.to_i).to eq hbx_enrollment.subscriber.person.primary_family.hbx_assigned_id
    end
  end
end
