require 'rails_helper'
require 'aasm/rspec'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

RSpec.describe "views/benefit_sponsors/profiles/employers/employer_profiles/my_account/_census_employees.html.erb_spec.rb", :type => :view, dbclean: :after_each do

  context 'Terminate All Employees button' do

    include_context "setup benefit market with market catalogs and product packages"
    include_context "setup initial benefit application"

    let(:current_effective_date) { TimeKeeper.date_of_record.beginning_of_month }
    let(:effective_on) { current_effective_date }
    let(:aasm_state) { :active }
    let!(:sponsored_benefit) {benefit_sponsorship.benefit_applications.first.benefit_packages.first.health_sponsored_benefit}
    let!(:update_sponsored_benefit) {sponsored_benefit.update_attributes(product_package_kind: :single_product)}
    let(:employer_profile) { benefit_sponsorship.profile }


    let(:person) {FactoryBot.create(:person)}
    let(:census_employee) { create(:census_employee, benefit_sponsorship: benefit_sponsorship, employer_profile: benefit_sponsorship.profile) }
    let!(:employee_role) { FactoryBot.create(:employee_role, person: person, census_employee: census_employee, employer_profile: benefit_sponsorship.profile) }
    let(:family) {FactoryBot.create(:family, :with_primary_family_member, person: person)}

    before :each do
      census_employee.employee_role_id = employee_role.id
      census_employee.save

      view.extend BenefitSponsors::Engine.routes.url_helpers
      view.extend BenefitSponsors::ApplicationHelper
      view.extend ApplicationHelper
      view.extend BenefitSponsors::PermissionHelper
      view.extend EffectiveDatatablesHelper
      view.extend Config::AcaHelper

      assign(:employer_profile, employer_profile)
      allow(view).to receive(:plan_match_tool_is_enabled?).and_return(false)
      allow(view).to receive(:render_datatable).and_return(true)
      allow(view).to receive(:show_oop_pdf_link).and_return(false)
      allow(view).to receive(:env_bucket_name).and_return("dchbx-enroll-test-test")
    end

    it 'should display for HBX admin' do
      allow(view).to receive(:policy_helper).and_return(double("EmployerProfile", updateable?: true, can_modify_employer?:true))
      render template: "benefit_sponsors/profiles/employers/employer_profiles/my_account/_census_employees.html.erb"
      expect(rendered).to match(/Terminate Employee Roster Enrollments/)
    end

    it 'should not display for employer' do
      allow(view).to receive(:policy_helper).and_return(double("EmployerProfile", updateable?: true, can_modify_employer?: false))
      render template: "benefit_sponsors/profiles/employers/employer_profiles/my_account/_census_employees.html.erb"
      expect(rendered).to_not match(/Terminate Employee Roster Enrollments/)
    end

  end
end



























# include_context "setup benefit market with market catalogs and product packages"
# include_context "setup initial benefit application"
#
# let(:current_effective_date) { TimeKeeper.date_of_record.beginning_of_month }
# let(:effective_on) { current_effective_date }
# let(:aasm_state) { :active }
# let!(:sponsored_benefit) {benefit_sponsorship.benefit_applications.first.benefit_packages.first.health_sponsored_benefit}
# let!(:update_sponsored_benefit) {sponsored_benefit.update_attributes(product_package_kind: :single_product)}
# let(:employer_profile) { benefit_sponsorship.profile }
#
# let(:census_employee) { create(:census_employee, :with_active_assignment, benefit_sponsorship: benefit_sponsorship, benefit_sponsors_employer_profile_id: benefit_sponsorship.profile.id, benefit_group: current_benefit_package) }
# let!(:family) {
#   person = FactoryBot.create(:person, last_name: census_employee.last_name, first_name: census_employee.first_name)
#   employee_role = FactoryBot.create(:employee_role, person: person, census_employee: census_employee, benefit_sponsors_employer_profile_id: abc_profile.id)
#   census_employee.update_attributes({employee_role: employee_role})
#   Family.find_or_build_from_employee_role(employee_role)
# }
# let!(:employee_role){census_employee.employee_role}
#
# let(:enrollment_kind) { "open_enrollment" }
# let(:covered_individuals) { family.family_members }
# let(:person) { family.primary_applicant.person }
# let!(:enrollment) { FactoryBot.create(:hbx_enrollment, :with_enrollment_members,
#                                       enrollment_members: covered_individuals,
#                                       household: family.latest_household,
#                                       coverage_kind: "health",
#                                       family: family,
#                                       effective_on: effective_on,
#                                       enrollment_kind: enrollment_kind,
#                                       kind: "employer_sponsored",
#                                       benefit_sponsorship_id: benefit_sponsorship.id,
#                                       sponsored_benefit_package_id: current_benefit_package.id,
#                                       sponsored_benefit_id: current_benefit_package.sponsored_benefits[0].id,
#                                       employee_role_id: employee_role.id,
#                                       product: sponsored_benefit.reference_product,
#                                       benefit_group_assignment_id: census_employee.active_benefit_group_assignment.id)
# }
#
# let(:user_with_hbx_staff_role) { FactoryBot.create(:user, :with_family, :with_hbx_staff_role) }
# let(:user_with_employer_role) {FactoryBot.create(:user, :with_family, :employer_staff) }
# let(:hbx_staff_permission) { FactoryBot.create(:permission, :hbx_staff) }
# let(:non_hbx_employer_profile_policy) { EmployerProfilePolicy.new(user_with_employer_role, employer_profile) }
# let(:hbx_employer_profile_policy) { EmployerProfilePolicy.new(user_with_hbx_staff_role, employer_profile) }
#
# it 'should display for HBX admin' do
#   allow(view).to receive(:current_user).and_return(user_with_hbx_staff_role)
#   allow(view).to receive(:policy_helper).and_return(hbx_employer_profile_policy)
#   user_with_hbx_staff_role.stub_chain('person.hbx_staff_role.permission').and_return(hbx_staff_permission)
#   render "benefit_sponsors/profiles/employers/employer_profiles/ee_roster_enrollment_termination"
#   expect(rendered).to match(/Terminate Employee Roster Enrollments/)
# end
#
# it 'should not display for employer' do
#   allow(view).to receive(:current_user).and_return(user_with_employer_role)
#   render "benefit_sponsors/profiles/employers/employer_profiles/ee_roster_enrollment_termination"
#   expect(rendered).to_not match(/Terminate Employee Roster Enrollments/)
# end

# before :each do
#
#   view.extend Pundit
#   view.extend BenefitSponsors::Engine.routes.url_helpers
#   # view.extend BenefitSponsors::Employers::EmployerHelper
#   # view.extend BenefitSponsors::ApplicationHelper
#   # view.extend BenefitSponsors::RegistrationHelper
#
#   # allow(employer_profile).to receive(:census_employees).and_return [census_employee]
#   assign(:employer_profile, employer_profile)
#   # assign(:available_employee_names, "employee_names")
#   assign(:census_employees, [])
#   allow(view).to receive(:generate_checkbook_urls_employers_employer_profile_path).and_return('/')
#   allow(view).to receive(:current_user).and_return(user_with_employer_role)
#   allow(view).to receive(:policy_helper).and_return(non_hbx_employer_profile_policy)
#   binding.pry
#   render "benefit_sponsors/profiles/employers/employer_profiles/my_account/census_employees"
#   # /Users/saidineshmekala/IDEACREW/enroll/components/benefit_sponsors/app/views/benefit_sponsors/profiles/employers/employer_profiles/my_account/_census_employees.html.erb
#   render template: "benefit_sponsors/profiles/employers/employer_profiles/my_account/_census_employees.html.erb"
#   # render "profiles/employers/employer_profiles/my_account/census_employees"
# end


# let!(:update){census_employee.employee_role = employee_role
# census_employee.save
# }

# let!(:employee_role){census_employee.employee_role}

# let(:enrollment_kind) { "open_enrollment" }
# let(:covered_individuals) { family.family_members }
# let(:person) { family.primary_applicant.person }
# let!(:enrollment) { FactoryBot.create(:hbx_enrollment, :with_enrollment_members,
#                                     enrollment_members: covered_individuals,
#                                     household: family.latest_household,
#                                     coverage_kind: "health",
#                                     family: family,
#                                     effective_on: effective_on,
#                                     enrollment_kind: enrollment_kind,
#                                     kind: "employer_sponsored",
#                                     benefit_sponsorship_id: benefit_sponsorship.id,
#                                     sponsored_benefit_package_id: current_benefit_package.id,
#                                     sponsored_benefit_id: current_benefit_package.sponsored_benefits[0].id,
#                                     employee_role_id: employee_role.id,
#                                     product: sponsored_benefit.reference_product)
# }

#
# let(:user_with_hbx_staff_role) { FactoryBot.create(:user, :with_family, :with_hbx_staff_role) }
# let(:user_with_employer_role) {FactoryBot.create(:user, :with_family, :employer_staff) }
# let(:hbx_staff_permission) { FactoryBot.create(:permission, :hbx_staff) }
# let(:non_hbx_employer_profile_policy) { EmployerProfilePolicy.new(user_with_employer_role, employer_profile) }
# let(:hbx_employer_profile_policy) { EmployerProfilePolicy.new(user_with_hbx_staff_role, employer_profile) }


