require 'rails_helper'
RSpec.describe "app/views/events/enrollment_event.xml.haml" do

  let!(:site)                  { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
  let!(:rating_area)           { FactoryBot.create_default :benefit_markets_locations_rating_area }
  let!(:service_area)          { FactoryBot.create_default :benefit_markets_locations_service_area }
  let!(:rating_area2)           { FactoryBot.create_default :benefit_markets_locations_rating_area, active_year: TimeKeeper.date_of_record.prev_year.year }
  let!(:service_area2)          { FactoryBot.create_default :benefit_markets_locations_service_area, active_year: TimeKeeper.date_of_record.prev_year.year }
  let(:benefit_sponsorship) do
    create(
        :benefit_sponsors_benefit_sponsorship,
        :with_organization_cca_profile,
        :with_renewal_benefit_application,
        :with_rating_area,
        :with_service_areas,
        initial_application_state: :active,
        renewal_application_state: :enrollment_open,
        default_effective_period: ((TimeKeeper.date_of_record.end_of_month + 1.day)..(TimeKeeper.date_of_record.end_of_month + 1.year)),
        site: site,
        aasm_state: :active
    )
  end

  let(:employer_profile) { benefit_sponsorship.profile }
  let(:active_benefit_package) { employer_profile.active_benefit_application.benefit_packages.first }
  let(:active_sponsored_benefit) {  employer_profile.active_benefit_application.benefit_packages.first.sponsored_benefits.first}

  let(:person) {FactoryBot.create(:person, first_name: 'John', last_name: 'Smith', dob: '1966-10-10'.to_date, ssn: '123456789')}
  let(:census_employee) { create(:census_employee, :with_active_assignment, benefit_sponsorship: benefit_sponsorship, benefit_sponsors_employer_profile_id: benefit_sponsorship.profile.id, benefit_group: active_benefit_package) }
  let!(:family) {
    person = FactoryBot.create(:person, last_name: census_employee.last_name, first_name: census_employee.first_name)
    employee_role = FactoryBot.create(:employee_role, person: person, census_employee: census_employee, benefit_sponsors_employer_profile_id: employer_profile.id)
    census_employee.update_attributes({employee_role: employee_role})
    Family.find_or_build_from_employee_role(employee_role)
  }
  let!(:issuer_profile)  { FactoryBot.create(:benefit_sponsors_organizations_issuer_profile) }
  let!(:employee_role){census_employee.employee_role}
  let(:hbx_enrollment_member) { FactoryBot.build(:hbx_enrollment_member, applicant_id: family.primary_family_member.id, is_subscriber: true, eligibility_date: TimeKeeper.date_of_record)}
  let!(:hbx_enrollment) { FactoryBot.create(:hbx_enrollment,
                                               household: family.latest_household,
                                               coverage_kind: "health",
                                               family: family,
                                               effective_on: employer_profile.active_benefit_application.start_on,
                                               enrollment_kind: "open_enrollment",
                                               kind: "employer_sponsored",
                                               aasm_state: 'coverage_selected',
                                               rating_area_id: rating_area.id,
                                               benefit_sponsorship_id: benefit_sponsorship.id,
                                               sponsored_benefit_package_id: active_benefit_package.id,
                                               sponsored_benefit_id: active_sponsored_benefit.id,
                                               employee_role_id: employee_role.id,
                                               product: active_sponsored_benefit.reference_product,
                                               hbx_enrollment_members:[hbx_enrollment_member],
                                               benefit_group_assignment_id: census_employee.active_benefit_group_assignment.id) }

  let(:member_enrollment) {BenefitSponsors::Enrollments::MemberEnrollment.new(member_id:hbx_enrollment_member.id,product_price:BigDecimal(100),sponsor_contribution:BigDecimal(100))}

  let(:decorated_hbx_enrollment) {
    BenefitSponsors::Enrollments::GroupEnrollment.new(sponsor_contribution_total:BigDecimal(200),product_cost_total:BigDecimal(300),member_enrollments:[member_enrollment])
  }

  context "enrollment cv for termianted policy" do

    before do
      product = active_sponsored_benefit.reference_product
      product.issuer_profile = issuer_profile
      product.save
      allow(hbx_enrollment).to receive(:decorated_hbx_enrollment).and_return(decorated_hbx_enrollment)
      hbx_enrollment.aasm_state = 'coverage_terminated'
      hbx_enrollment.terminate_reason = 'non_payment'
      hbx_enrollment.save
      render :template => "events/enrollment_event", :locals => {hbx_enrollment: hbx_enrollment}
      @doc = Nokogiri::XML(rendered)
    end

    it "should include qualifying_reason" do
      expect(@doc.xpath("//x:qualifying_reason", "x" => "http://openhbx.org/api/terms/1.0").text).to eq "urn:openhbx:terms:v1:benefit_maintenance#non_payment"
    end
  end
end