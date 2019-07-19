require 'rails_helper'

RSpec.describe Employers::EmployerProfilesController, dbclean: :after_each do


  describe "GET index"  do

    let(:user) { double("user") }

    it 'should redirect' do
      sign_in(user)
      get :index
      expect(response).to redirect_to("/benefit_sponsors/profiles/registrations/new?profile_type=benefit_sponsor")
    end

  end

  describe "GET new" do

    let(:user) { double("user") }

    it "should redirect" do
      sign_in(user)
      get :new
      expect(response).to redirect_to("/benefit_sponsors/profiles/registrations/new?profile_type=benefit_sponsor")
    end
  end

  describe "GET show_profile" do

    let(:user) { double("user") }
    let(:employer_profile) { FactoryBot.create(:employer_profile) }

    it "should redirect" do
      sign_in(user)
      get :show_profile, params: {employer_profile_id: employer_profile}
      expect(response).to redirect_to("/benefit_sponsors/profiles/registrations/new?profile_type=benefit_sponsor")
    end
  end

  describe "GET show" do

    let(:user) { double("user") }
    let(:employer_profile) { FactoryBot.create(:employer_profile) }

    it "should redirect" do
      sign_in(user)
      get :show, params: {id: employer_profile}
      expect(response).to redirect_to("/benefit_sponsors/profiles/registrations/new?profile_type=benefit_sponsor")
    end
  end

  describe "GET welcome", dbclean: :after_each do
    let(:user) { double("user") }

    it "should redirect" do
      sign_in(user)
      get :welcome
      expect(response).to redirect_to("/benefit_sponsors/profiles/registrations/new?profile_type=benefit_sponsor")
    end

  end


  describe "GET search", dbclean: :after_each do
    let(:user) { double("user")}
    let(:person) { double("Person")}
    before(:each) do
      allow(user).to receive(:person).and_return(person)
      sign_in user
      get :search
    end

    it "renders the 'search' template" do
      expect(response).to have_http_status(:success)
      expect(response).to render_template("search")
      expect(assigns[:employer_profile]).to be_a(Forms::EmployerCandidate)
    end
  end


  describe "GET export_census_employees", dbclean: :after_each do
    let(:user) { FactoryBot.create(:user) }
    let(:employer_profile) { FactoryBot.create(:employer_profile) }

    it "should export cvs" do
      sign_in(user)
      get :export_census_employees, params: {employer_profile_id: employer_profile}, format: :csv
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET new Document", dbclean: :after_each do
    let(:user) { FactoryBot.create(:user) }
    let(:employer_profile) { FactoryBot.create(:employer_profile) }
    it "should load upload Page" do
      sign_in(user)
      get :new_document, params: {id: employer_profile}, xhr: true
      expect(response).to have_http_status(:success)
    end
  end


  describe "POST Upload Document", dbclean: :after_each do
    let(:user) { FactoryBot.create(:user) }
    let(:employer_profile) { FactoryBot.create(:employer_profile) }
    #let(:params) { { id: employer_profile.id, file:'test/JavaScript.pdf', subject: 'JavaScript.pdf' } }

    let(:subject){"Employee Attestation"}
    let(:file) { double }
    let(:temp_file) { double }
    let(:file_path) { Rails.root+'test/JavaScript.pdf' }

    before(:each) do
      @controller = Employers::EmployerProfilesController.new
      #allow(file).to receive(:original_filename).and_return("some-filename")
      allow(file).to receive(:tempfile).and_return(temp_file)
      allow(temp_file).to receive(:path)
      allow(@controller).to receive(:file_path).and_return(file_path)
      allow(@controller).to receive(:file_name).and_return("sample-filename")
      #allow(@controller).to receive(:file_content_type).and_return("application/pdf")
    end

    context "upload document", dbclean: :after_each do
      it "redirects to document list page" do
        sign_in user
        post :upload_document, params: {id: employer_profile.id, file: file, subject: subject}
        expect(response).to have_http_status(:redirect)
      end
    end
  end

  describe "Delete Document", dbclean: :after_each do
    let(:user) { FactoryBot.create(:user) }
    let(:employer_profile) { FactoryBot.create(:employer_profile) }

    it "should delete documents" do
      sign_in(user)
      get :delete_documents, params: {id: employer_profile.id, ids:[1]}, xhr: true
      expect(response).to have_http_status(:success)
    end
  end  

  describe "POST terminate_employee_roster_enrollments" do
    let!(:terminate_employee_profile) { FactoryBot.create(:employer_with_planyear, plan_year_state: 'active')}
    let!(:benefit_group) { terminate_employee_profile.published_plan_year.benefit_groups.first}
    let!(:census_employees) do
      FactoryBot.create :census_employee, :owner, employer_profile: terminate_employee_profile
      employee = FactoryBot.create(
        :census_employee,
        employer_profile: terminate_employee_profile
      )
      employee.add_benefit_group_assignment(benefit_group, benefit_group.start_on)
    end
    let!(:plan) do
      FactoryBot.create(
        :plan,
        :with_premium_tables,
        market: 'shop',
        metal_level: 'gold',
        active_year: benefit_group.start_on.year,
        hios_id: "11111111122302-01", csr_variant_id: "01"
      )
    end
    let!(:ce) { terminate_employee_profile.census_employees.non_business_owner.first }
    let!(:family) do
      person = FactoryBot.create(:person, last_name: ce.last_name, first_name: ce.first_name)
      employee_role = FactoryBot.create(
        :employee_role,
        person: person,
        census_employee: ce,
        employer_profile: terminate_employee_profile
      )
      ce.update_attributes({employee_role: employee_role})
      Family.find_or_build_from_employee_role(employee_role)
    end
    let!(:person) { family.primary_applicant.person }
    let!(:hbx_enrollment) do
      FactoryBot.create(
        :hbx_enrollment,
        family: family,
        household: family.active_household,
        coverage_kind: "health",
        effective_on: benefit_group.start_on,
        enrollment_kind: "open_enrollment",
        kind: "employer_sponsored",
        benefit_group_id: benefit_group.id,
        employee_role_id: person.active_employee_roles.first.id,
        benefit_group_assignment_id: ce.active_benefit_group_assignment.id,
        plan_id: plan.id
      )
    end
    let(:renewing_plan_year) { FactoryBot.create(:renewing_plan_year, employer_profile: terminate_employee_profile) }
    let(:first_enrollment) { terminate_employee_profile.active_plan_year.enrollments_for_plan_year.first }

    let(:hbx_staff_permission) { FactoryBot.create(:permission, :hbx_staff) }
    let(:user) { FactoryBot.create(:user, :with_family, :hbx_staff) }

    before do
      user.stub_chain('person.hbx_staff_role.permission').and_return(hbx_staff_permission)
      sign_in(user)
    end

    it "should show an error message if no active plan year present" do
      profile_no_plan_year = instance_double("EmployerProfile", id: double("id"))
      allow(profile_no_plan_year).to receive(:active_plan_year).and_return(nil)
      allow(EmployerProfile).to receive(:find).and_return(profile_no_plan_year)
      expect(profile_no_plan_year.active_plan_year.present?).to eq(false)
      post(
        :terminate_employee_roster_enrollments,
        employer_profile_id: profile_no_plan_year.id,
        termination_date: "1/1/2020",
        transmit_xml: true
      )
      error_message = "No Active Plan Year present, unable to terminate employee enrollments."
      expect(flash[:error]).to eq(error_message)
      redirect_path = employers_employer_profile_path(profile_no_plan_year) + "?tab=employees"
      expect(response).to redirect_to(redirect_path)
    end

    it "should terminate employees for a active plan year" do
      expect(terminate_employee_profile.active_plan_year.present?).to eq(true)
      expect(first_enrollment.terminated_on).to eq(nil)
      post(
        :terminate_employee_roster_enrollments,
        employer_profile_id: terminate_employee_profile.id,
        termination_date: "1/1/2020",
        transmit_xml: true
      )
      first_enrollment.reload
      expect(first_enrollment.terminated_on.present?).to eq(true)
      expect(first_enrollment.terminated_on.class).to eq(Date)
      flash_message = "Successfully terminated employee enrollments."
      expect(flash[:notice]).to eq(flash_message)
      redirect_path = employers_employer_profile_path(terminate_employee_profile) + "?tab=employees"
      expect(response).to redirect_to(redirect_path)
    end

    it "should terminate employees for a renewing plan year" do
      allow(terminate_employee_profile).to receive(:renewing_plan_year).and_return(true)
      expect(first_enrollment.terminated_on).to eq(nil)
      post(
        :terminate_employee_roster_enrollments,
        employer_profile_id: terminate_employee_profile.id,
        termination_date: "1/1/2020",
        transmit_xml: true
      )
      first_enrollment.reload
      expect(first_enrollment.terminated_on.present?).to eq(true)
      expect(first_enrollment.terminated_on.class).to eq(Date)
      flash_message = "Successfully terminated employee enrollments."
      expect(flash[:notice]).to eq(flash_message)
      redirect_path = employers_employer_profile_path(terminate_employee_profile) + "?tab=employees"
      expect(response).to redirect_to(redirect_path)
    end
  end
end
