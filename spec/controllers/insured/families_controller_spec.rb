require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

#Mock announcement class
class Announcement
  def self.current_msg_for_employee
    []
  end

  def current_msg_for_employer
    []
  end
end

RSpec.describe Insured::FamiliesController, dbclean: :after_each do
  context "set_current_user with no person" do
    let(:user) { FactoryBot.create(:user, person: person) }
    let(:person) { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role) }
    let(:family) { FactoryBot.create(:family, :with_primary_family_member) }

    before :each do
      sign_in user
    end

    it "should assigns the family if user is hbx_staff and dependent consumer" do
      get :home, params: {:family => family.id.to_s}
      expect(assigns(:family)).to eq family
    end

    it "should redirect" do
      get :home, params: {:family => family.id}
      expect(response).to be_redirect
    end
  end

  context "set_current_user  as agent" do
    let(:user) { FactoryBot.create(:user, last_portal_visited: "test.com", id: 77, email: 'x@y.com', person: person) }
    let(:person) { FactoryBot.create(:person) }

    it "should raise the error on invalid person_id" do
      allow(session).to receive(:[]).and_return(33)
      allow(person).to receive(:agent?).and_return(true)
      expect{get :home}.to raise_error(ArgumentError)
    end
  end
end

RSpec.describe Insured::FamiliesController, dbclean: :after_each do

  include_context "setup benefit market with market catalogs and product packages"
  include_context "setup initial benefit application"

  let(:hbx_enrollments) { double("HbxEnrollment", order: nil, waived: nil, any?: nil, non_external: nil, effective_on: Date.today) }
  let(:person) { FactoryBot.create(:person, addresses: [], is_homeless: false, is_temporarily_out_of_state: false) }
  let(:family) { FactoryBot.create(:family, :with_primary_family_member_and_dependent, person: person) }
  let(:user) { FactoryBot.create(:user, person: person) }
  let(:family_members) { family.family_members }
  let(:household) { FactoryBot.create(:household, family: family, hbx_enrollments: hbx_enrollments, is_active: true) }
  let(:addresses) { [double] }
  let(:census_employee) { FactoryBot.create(:census_employee, employer_profile: abc_profile) }
  let(:employee_roles) { [FactoryBot.create(:employee_role, :census_employee => census_employee)] }
  let(:resident_role) { FactoryBot.create(:resident_role) }
  let(:consumer_role) { FactoryBot.create(:consumer_role, bookmark_url: "/families/home", identity_validation: 'valid', person: person) }
  let(:qle) { FactoryBot.create(:qualifying_life_event_kind, pre_event_sep_in_days: 30, post_event_sep_in_days: 0) }
  let(:sep) { double("SpecialEnrollmentPeriod") }
  let(:permission) { FactoryBot.create(:permission, :hbx_staff) }

  before :each do
    allow(hbx_enrollments).to receive(:+).with(HbxEnrollment.family_canceled_enrollments(family)).and_return(
      HbxEnrollment.family_canceled_enrollments(family) + [hbx_enrollments]
    )
    allow(hbx_enrollments).to receive(:order).and_return(hbx_enrollments)
    allow(hbx_enrollments).to receive(:waived).and_return([])
    allow(hbx_enrollments).to receive(:any?).and_return(false)
    allow(hbx_enrollments).to receive(:non_external).and_return(hbx_enrollments)
    allow(hbx_enrollments).to receive(:sort_by!).and_return(hbx_enrollments)
    allow(hbx_enrollments).to receive(:reverse!).and_return(hbx_enrollments)
    allow(user).to receive(:last_portal_visited).and_return("test.com")
    allow(person).to receive(:primary_family).and_return(family)
    allow(person).to receive(:consumer_role).and_return(consumer_role)
    allow(person).to receive(:active_employee_roles).and_return(employee_roles)
    allow(person).to receive(:is_resident_role_active?).and_return(true)
    allow(person).to receive(:resident_role).and_return(resident_role)
  end

  describe "GET home variables" do
    context "HBX admin variables to show all enrollments" do
      let(:user_with_hbx_staff_role) { FactoryBot.create(:user, :with_family, :hbx_staff) }
      let(:consumer_person) { FactoryBot.create(:person, :with_consumer_role) }
      let(:testing_family) { FactoryBot.create(:family, :with_primary_family_member, person: consumer_person) }
      let(:testing_enrollments) do
        5.times do
          instance_double("HbxEnrollment", family_id: testing_family.id)
        end
      end
      let(:consumer_role) { FactoryBot.create(:consumer_role, bookmark_url: "/families/home", identity_validation: 'valid') }

      it "should assign all_hbx_enrollments_for_admin variable if hbx admin user" do
        testing_family.stub_chain('primary_applicant.person_id').and_return(user_with_hbx_staff_role.person.id)
        user_with_hbx_staff_role.person.hbx_staff_role.update!(permission_id: permission.id)
        sign_in(user_with_hbx_staff_role)
        get :home, params: {:family => testing_family.id.to_s}
        expect(assigns.keys).to include("all_hbx_enrollments_for_admin")
      end

      it "should not assign all_hbx_enrollments_for_admin for non hbx admin user" do
        user = FactoryBot.create(:user)
        allow_any_instance_of(Person).to receive(:has_multiple_roles?).and_return(false)
        allow(testing_family).to receive(:person).and_return(user.person)
        sign_in(user)
        get :home, params: {:family => testing_family.id.to_s}
        expect(assigns.keys).to_not include("all_hbx_enrollments_for_admin")
      end
    end
  end

  describe "GET home" do
    before :each do
      allow(family).to receive(:enrollments).and_return(hbx_enrollments)
      allow(family).to receive(:enrollments_for_display).and_return(hbx_enrollments)
      allow(family).to receive(:coverage_waived?).and_return(false)
      allow(family).to receive(:latest_active_sep).and_return sep
      allow(hbx_enrollments).to receive(:active).and_return(hbx_enrollments)
      allow(hbx_enrollments).to receive(:changing).and_return([])
      allow(user).to receive(:has_employee_role?).and_return(true)
      allow(user).to receive(:has_consumer_role?).and_return(true)
      allow(user).to receive(:last_portal_visited=).and_return("test.com")
      allow(user).to receive(:save).and_return(true)
      allow(user).to receive(:person).and_return(person)
      allow(person).to receive(:consumer_role).and_return(consumer_role)
      allow(person).to receive(:addresses).and_return(addresses)
      allow(person).to receive(:has_multiple_roles?).and_return(true)
      allow(consumer_role).to receive(:save!).and_return(true)
      allow(hbx_enrollments).to receive(:each).and_return(hbx_enrollments)
      allow(hbx_enrollments).to receive(:reject).and_return(hbx_enrollments)
      allow(hbx_enrollments).to receive(:inject).and_return(hbx_enrollments)
      allow(hbx_enrollments).to receive(:compact).and_return(hbx_enrollments)

      session[:portal] = "insured/families"
    end

    context "#check_for_address_info" do
      before :each do
        allow(person).to receive(:user).and_return(user)
        allow(user).to receive(:identity_verified?).and_return(false)
        allow(consumer_role).to receive(:identity_verified?).and_return(false)
        allow(consumer_role).to receive(:application_verified?).and_return(false)
        allow(person).to receive(:has_active_employee_role?).and_return(false)
        allow(person).to receive(:is_consumer_role_active?).and_return(true)
        allow(person).to receive(:active_employee_roles).and_return([])
        allow(person).to receive(:employee_roles).and_return([])
        allow(user).to receive(:get_announcements_by_roles_and_portal).and_return []
        allow(family).to receive(:check_for_consumer_role).and_return true
        allow(family).to receive(:active_family_members).and_return(family_members)
        sign_in user
      end

      it "should redirect to ridp page if user has not verified identity" do
        get :home
        expect(response).to redirect_to("/insured/consumer_role/ridp_agreement")
      end

      it "should redirect to edit page if user do not have addresses" do
        allow(person).to receive(:addresses).and_return []
        get :home
        expect(response).to redirect_to(edit_insured_consumer_role_path(consumer_role))
      end
    end

    describe "#init_qle", dbclean: :after_each do
      let!(:shop_visible_qle)  { FactoryBot.create(:qualifying_life_event_kind, start_on: TimeKeeper.date_of_record.last_year, market_kind: 'shop', is_visible: true) }
      let!(:fehb_visible_qle)  { FactoryBot.create(:qualifying_life_event_kind, start_on: TimeKeeper.date_of_record.last_year, market_kind: 'fehb', is_visible: true) }
      let!(:shop_non_visible_qle)  { FactoryBot.create(:qualifying_life_event_kind, start_on: TimeKeeper.date_of_record.last_year, market_kind: 'shop', is_visible: false) }
      let!(:ivl_visible_qle)  { FactoryBot.create(:qualifying_life_event_kind, start_on: TimeKeeper.date_of_record.last_year, market_kind: 'individual', is_visible: true) }
      let!(:ivl_non_visible_qle)  { FactoryBot.create(:qualifying_life_event_kind, start_on: TimeKeeper.date_of_record.last_year, market_kind: 'individual', is_visible: false) }
      let(:shop_params)  {{market: "shop_market_events"}}
      let(:ivl_params)  {{market: "individual_market_events"}}

      context "user with both consumer and employee role", dbclean: :after_each do
        before :each do
          @controller = Insured::FamiliesController.new
          @controller.instance_variable_set(:@person, person)
          allow(person).to receive(:user).and_return(user)
          allow(person).to receive(:has_active_employee_role?).and_return(true)
          allow(person).to receive(:has_active_consumer_role?).and_return(true)
          allow(person).to receive(:active_employee_roles).and_return(employee_roles)
          allow(employee_roles.first).to receive(:market_kind).and_return('shop')
          allow(user).to receive(:has_hbx_staff_role?).and_return false
          allow(EnrollRegistry[:aca_shop_market].feature).to receive(:is_enabled).and_return(true)
          sign_in user
        end

        it "should return shop visible qles only" do
          allow(@controller).to receive(:params).and_return(shop_params)
          expect(@controller.instance_eval { init_qualifying_life_events }).to eq [shop_visible_qle]
        end

        it "should return ivl visible qles only" do
          allow(@controller).to receive(:params).and_return(ivl_params)
          expect(@controller.instance_eval { init_qualifying_life_events }).to eq [ivl_visible_qle]
        end
      end

      context "user with consumer role", dbclean: :after_each do
        before :each do
          @controller = Insured::FamiliesController.new
          @controller.instance_variable_set(:@person, person)
          allow(person).to receive(:user).and_return(user)
          allow(person).to receive(:has_active_employee_role?).and_return(false)
          allow(person).to receive(:has_multiple_roles?).and_return(false)
          allow(person).to receive(:has_active_consumer_role?).and_return(true)
          allow(person).to receive(:consumer_role).and_return(consumer_role)
          allow(consumer_role).to receive(:is_a?).with(ConsumerRole).and_return true
          allow(consumer_role).to receive(:is_a?).with(EmployeeRole).and_return false
          allow(person).to receive(:active_employee_roles).and_return([])
          allow(user).to receive(:has_hbx_staff_role?).and_return false
          sign_in user
        end

        it "should return ivl visible qles only" do
          allow(@controller).to receive(:params).and_return(ivl_params)
          expect(@controller.instance_eval { init_qualifying_life_events }).to eq [ivl_visible_qle]
        end
      end

      context "user with employee role", dbclean: :after_each do
        before :each do
          @controller = Insured::FamiliesController.new
          @controller.instance_variable_set(:@person, person)
          allow(person).to receive(:user).and_return(user)
          allow(person).to receive(:has_active_employee_role?).and_return(true)
          allow(person).to receive(:has_active_consumer_role?).and_return(false)
          allow(person).to receive(:has_multiple_roles?).and_return(false)
          allow(person).to receive(:active_employee_roles).and_return(employee_roles)
          allow(user).to receive(:has_hbx_staff_role?).and_return false
          sign_in user
        end

        it "should return shop visible qles only" do
          allow(@controller).to receive(:params).and_return(shop_params)
          expect(@controller.instance_eval { init_qualifying_life_events }).to eq [shop_visible_qle]
        end
      end

      context "user with fehb employee role", dbclean: :after_each do
        before :each do
          @controller = Insured::FamiliesController.new
          @controller.instance_variable_set(:@person, person)
          allow(person).to receive(:user).and_return(user)
          allow(person).to receive(:has_active_employee_role?).and_return(true)
          allow(person).to receive(:has_active_consumer_role?).and_return(false)
          allow(person).to receive(:has_multiple_roles?).and_return(false)
          allow(person).to receive(:active_employee_roles).and_return(employee_roles)
          allow(employee_roles.first).to receive(:is_a?).with(ConsumerRole).and_return false
          allow(employee_roles.first).to receive(:is_a?).with(ResidentRole).and_return false
          allow(employee_roles.first).to receive(:is_a?).with(EmployeeRole).and_return true
          allow(employee_roles.first).to receive(:employer_profile).and_return abc_profile
          allow(abc_profile).to receive(:is_a?).with(BenefitSponsors::Organizations::FehbEmployerProfile).and_return true
          allow(user).to receive(:has_hbx_staff_role?).and_return false
          allow(EnrollRegistry[:aca_shop_market].feature).to receive(:is_enabled).and_return(true)
          sign_in user
        end

        it "should return fehb visible qles only" do
          allow(@controller).to receive(:params).and_return(shop_params)
          expect(@controller.instance_eval { init_qualifying_life_events }).to eq [fehb_visible_qle]
        end
      end

      context "user with hbx_staff role", dbclean: :after_each do
        before :each do
          @controller = Insured::FamiliesController.new
          @controller.instance_variable_set(:@person, person)
          allow(person).to receive(:user).and_return(user)
          allow(person).to receive(:has_active_employee_role?).and_return(true)
          allow(person).to receive(:has_active_consumer_role?).and_return(true)
          allow(person).to receive(:has_multiple_roles?).and_return(true)
          allow(person).to receive(:active_employee_roles).and_return(employee_roles)
          allow(user).to receive(:has_hbx_staff_role?).and_return true
          allow(person).to receive(:active_employee_roles).and_return([])
          allow(EnrollRegistry[:aca_shop_market].feature).to receive(:is_enabled).and_return(true)
          sign_in user
        end

        it "should return all shop qles" do
          allow(@controller).to receive(:params).and_return(shop_params)
          @controller.instance_eval { init_qualifying_life_events }
          expect(@controller.instance_variable_get(:@qualifying_life_events)).to eq [shop_visible_qle, shop_non_visible_qle]
        end

        it "should return all ivl qles" do
          allow(@controller).to receive(:params).and_return(ivl_params)
          @controller.instance_eval { init_qualifying_life_events }
          expect(@controller.instance_variable_get(:@qualifying_life_events)).to eq [ivl_visible_qle, ivl_non_visible_qle]
        end
      end
    end

    context "for SHOP market", dbclean: :after_each do
      let(:employee_roles) { double(market_kind: 'shop') }
      let(:employee_role) { FactoryBot.create(:employee_role, bookmark_url: "/families/home", employer_profile: abc_profile) }
      let(:census_employee) { FactoryBot.create(:census_employee, employee_role_id: employee_role.id, employer_profile: abc_profile) }

      before :each do
        FactoryBot.create(:announcement, content: "msg for Employee", audiences: ['Employee'])
        allow(person).to receive(:has_active_employee_role?).and_return(true)
        allow(person).to receive(:active_employee_roles).and_return([employee_role])
        allow(person).to receive(:employee_roles).and_return([employee_role])
        allow(family).to receive(:coverage_waived?).and_return(true)
        allow(family).to receive(:active_family_members).and_return(family_members)
        allow(family).to receive(:check_for_consumer_role).and_return nil
        allow(employee_role).to receive(:census_employee_id).and_return census_employee.id
        allow(EnrollRegistry[:aca_shop_market].feature).to receive(:is_enabled).and_return(true)
        allow(Announcement).to receive(:current_msg_for_employee).and_return(["msg for Employee"])
        allow(Announcement).to receive(:audience_kinds).and_return(%w[Employer Employee IVL Broker GA Web_Page])
        sign_in user
        get :home
      end

      it "should be a success" do
        expect(response).to have_http_status(:success)
      end

      it "should render my account page" do
        expect(response).to render_template("home")
      end

      it "should assign variables" do
        expect(assigns(:qualifying_life_events)).to be_an_instance_of(Array)
        expect(assigns(:hbx_enrollments)).to eq(hbx_enrollments)
        expect(assigns(:employee_role)).to eq(employee_role)
      end

      it "should get shop market events" do
        expect(assigns(:qualifying_life_events)).to eq QualifyingLifeEventKind.shop_market_events
      end

      it "should get announcement" do
        expect(flash.now[:warning]).to eq [{ :announcement => 'msg for Employee', :is_announcement => true }]
      end
    end

    context "for IVL market" do
      let(:user) { FactoryBot.create(:user, person: person) }

      before :each do
        allow(user).to receive(:idp_verified?).and_return true
        allow(user).to receive(:identity_verified?).and_return true
        allow(user).to receive(:last_portal_visited).and_return ''
        allow(person).to receive(:has_active_employee_role?).and_return(false)
        allow(person).to receive(:is_consumer_role_active?).and_return(true)
        allow(person).to receive(:active_employee_roles).and_return([])
        allow(person).to receive(:employee_roles).and_return(nil)
        allow(family).to receive(:active_family_members).and_return(family_members)
        allow(family).to receive(:check_for_consumer_role).and_return true
        sign_in user
        get :home
      end

      it "should be a success" do
        expect(response).to have_http_status(:success)
      end

      it "should render my account page" do
        expect(response).to render_template("home")
      end

      it "should assign variables" do
        expect(assigns(:qualifying_life_events)).to be_an_instance_of(Array)
        expect(assigns(:hbx_enrollments)).to eq(hbx_enrollments)
        expect(assigns(:employee_role)).to be_nil
      end

      it "should get individual market events" do
        expect(assigns(:qualifying_life_events)).to eq QualifyingLifeEventKind.individual_market_events
      end

      context "who has not passed ridp" do
        let(:user) { double(identity_verified?: false, last_portal_visited: '', idp_verified?: false) }
        let(:user) { FactoryBot.create(:user) }

        before do
          allow(user).to receive(:idp_verified?).and_return false
          allow(user).to receive(:identity_verified?).and_return false
          allow(consumer_role).to receive(:identity_verified?).and_return false
          allow(consumer_role).to receive(:application_verified?).and_return false
          allow(user).to receive(:last_portal_visited).and_return ''
          allow(person).to receive(:user).and_return(user)
          allow(person).to receive(:has_active_employee_role?).and_return(false)
          allow(person).to receive(:is_consumer_role_active?).and_return(true)
          allow(person).to receive(:active_employee_roles).and_return([])
          sign_in user
          get :home
        end

        it "should be a redirect" do
          expect(response).to have_http_status(:redirect)
        end
      end
    end

    context "for both ivl and shop", dbclean: :after_each do
      let(:employee_roles) { double(market_kind: 'shop') }
      let(:employee_role) { double("EmployeeRole", bookmark_url: "/families/home") }
      let(:enrollments) { double }
      let(:employee_role2) { FactoryBot.create(:employee_role2, employer_profile: abc_profile) }
      let(:census_employee) { FactoryBot.create(:census_employee, employee_role_id: employee_role2.id, employer_profile: abc_profile) }

      before :each do
        sign_in user
        allow(person).to receive(:has_active_employee_role?).and_return(true)
        allow(person).to receive(:employee_roles).and_return(employee_roles)
        allow(person.employee_roles).to receive(:last).and_return(employee_role)
        allow(person).to receive(:active_employee_roles).and_return(employee_roles)
        allow(employee_roles).to receive(:first).and_return(employee_role)
        allow(employee_roles).to receive(:count).and_return(1)
        allow(person).to receive(:is_consumer_role_active?).and_return(true)
        allow(employee_roles).to receive(:active).and_return([employee_role])
        allow(family).to receive(:coverage_waived?).and_return(true)
        allow(hbx_enrollments).to receive(:waived).and_return([waived_hbx])
        allow(enrollments).to receive(:non_external).and_return(enrollments)
        allow(family).to receive(:enrollments).and_return(enrollments)
        allow(enrollments).to receive(:order).and_return([display_hbx])
        allow(family).to receive(:enrollments_for_display).and_return([{"hbx_enrollment" => {"_id" => display_hbx.id}}])
        allow(family).to receive(:check_for_consumer_role).and_return true
        allow(controller).to receive(:update_changing_hbxs).and_return(true)
        allow(employee_role).to receive(:census_employee_id).and_return census_employee.id
      end

      context "with waived_hbx when display_hbx is employer_sponsored" do
        let(:waived_hbx) { HbxEnrollment.new(kind: 'employer_sponsored', effective_on: TimeKeeper.date_of_record) }
        let(:display_hbx) { HbxEnrollment.new(kind: 'employer_sponsored', aasm_state: 'coverage_selected', effective_on: TimeKeeper.date_of_record) }
        let(:employee_role) { FactoryBot.create(:employee_role, employer_profile: abc_profile) }
        let(:census_employee) { FactoryBot.create(:census_employee, employee_role_id: employee_role.id, employer_profile: abc_profile) }
        before :each do
          allow(family).to receive(:active_family_members).and_return(family_members)
          allow(employee_role).to receive(:census_employee_id).and_return census_employee.id
          allow(EnrollRegistry[:aca_shop_market].feature).to receive(:is_enabled).and_return(true)
          get :home
        end
        it "should be a success" do
          expect(response).to have_http_status(:success)
        end

        it "should render my account page" do
          expect(response).to render_template("home")
        end

        it "should assign variables" do
          expect(assigns(:qualifying_life_events)).to be_an_instance_of(Array)
          expect(assigns(:hbx_enrollments)).to eq([display_hbx])
          expect(assigns(:employee_role)).to eq(employee_role)
        end
      end

      context "with waived_hbx when display_hbx is individual" do
        let(:waived_hbx) { HbxEnrollment.new(kind: 'employer_sponsored', effective_on: TimeKeeper.date_of_record) }
        let(:display_hbx) { HbxEnrollment.new(kind: 'individual', aasm_state: 'coverage_selected', effective_on: TimeKeeper.date_of_record) }
        let(:employee_role) { FactoryBot.create(:employee_role, employer_profile: abc_profile) }
        let(:census_employee) { FactoryBot.create(:census_employee, employee_role_id: employee_role.id, employer_profile: abc_profile) }
        before :each do
          allow(family).to receive(:active_family_members).and_return(family_members)
          allow(employee_role).to receive(:census_employee_id).and_return census_employee.id
          allow(EnrollRegistry[:aca_shop_market].feature).to receive(:is_enabled).and_return(true)
          get :home
        end
        it "should be a success" do
          expect(response).to have_http_status(:success)
        end

        it "should render my account page" do
          expect(response).to render_template("home")
        end

        it "should assign variables" do
          expect(assigns(:qualifying_life_events)).to be_an_instance_of(Array)
          expect(assigns(:hbx_enrollments)).to eq([display_hbx])
          expect(assigns(:employee_role)).to eq(employee_role)
        end
      end
    end
  end

  describe "GET verification" do
    let(:person) { FactoryBot.create(:person, :with_consumer_role) }
    let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
    let(:user) { FactoryBot.create(:user, person: person) }
    let(:family_member) { FamilyMember.new(:person => person) }

    before :each do
      sign_in user
    end

    it "should be success" do
      get :verification
      expect(response).to have_http_status(:success)
    end

    it "should error out" do
      expect { get '/insured/families/verification.bac' }.to raise_error(ActionController::UrlGenerationError)
    end

    it "renders verification template" do
      get :verification
      expect(response).to render_template("verification")
    end

    it "assign variables" do
      get :verification
      expect(assigns(:family_members)).to be_an_instance_of(Array)
      expect(assigns(:family_members)).to eq(family.family_members)
    end

    context 'with invalid mime types' do
      # these should respond with a UrlGenerationError due to the use of `format: false` in the routes file
      it "js should return an error" do
        expect { get :verfication, format: :js }.to raise_error(ActionController::UrlGenerationError)
      end

      it "json should return an error" do
        expect { get :verfication, format: :json }.to raise_error(ActionController::UrlGenerationError)
      end

      it "xml should return an error" do
        expect { get :verfication, format: :xml }.to raise_error(ActionController::UrlGenerationError)
      end
    end
  end

  describe "GET manage_family" do
    before :each do
      allow(person).to receive(:active_employee_roles).and_return(employee_roles)
      allow(family).to receive(:coverage_waived?).and_return(true)
      allow(family).to receive(:active_family_members).and_return(family_members)
      allow(employee_roles.first).to receive(:market_kind).and_return('shop')
      sign_in user
    end

    it "should be a success" do
      allow(person).to receive(:has_multiple_roles?).and_return(false)
      get :manage_family
      expect(response).to have_http_status(:success)
    end

    it "should render manage family section" do
      allow(person).to receive(:has_multiple_roles?).and_return(false)
      get :manage_family
      expect(response).to render_template("manage_family")
    end

    it "should assign variables" do
      allow(person).to receive(:has_multiple_roles?).and_return(false)
      get :manage_family
      expect(assigns(:qualifying_life_events)).to be_an_instance_of(Array)
      expect(assigns(:family_members)).to eq(family_members)
    end

    it "assigns variable to change QLE to IVL flow" do
      allow(person).to receive(:has_multiple_roles?).and_return(true)
      get :manage_family, params: {market: "shop_market_events"}
      expect(assigns(:manually_picked_role)).to eq "shop_market_events"
    end

    it "assigns variable to change QLE to Employee flow" do
      allow(person).to receive(:has_multiple_roles?).and_return(true)
      get :manage_family, params: {market: "individual_market_events"}
      expect(assigns(:manually_picked_role)).to eq "individual_market_events"
    end

    it "doesn't assign the variable to show different flow for QLE" do
      allow(person).to receive(:has_multiple_roles?).and_return(false)
      get :manage_family, params: {market: "shop_market_events"}
      expect(assigns(:manually_picked_role)).to eq nil
    end
  end

  describe "GET personal" do
    before do
      allow(controller).to receive(:authorize).and_return(true)
    end

    context "render template" do
      before :each do
        allow(family).to receive(:active_family_members).and_return(family_members)
        sign_in user
        get :personal
      end

      it "should be a success" do
        expect(response).to have_http_status(:success)
      end

      it "should render person edit page" do
        expect(response).to render_template("personal")
      end

      it "should assign variables" do
        expect(assigns(:family_members)).to eq(family_members)
      end
    end

    context "choosing contact_method via dropdown is enabled" do
      before :each do
        allow(family).to receive(:active_family_members).and_return(family_members)
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:fehb_market).and_return(true)
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:aca_shop_market).and_return(true)
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:contact_method_via_dropdown).and_return(true)
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:prevent_concurrent_sessions).and_return(false)
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:preferred_user_access).and_return(false)
        sign_in user
        get :personal
      end

      it "should not assign value" do
        expect(assigns(:contact_preferences_mapping)).to eq(nil)
      end
    end

    context "choosing contact_method via dropdown is disabled (choose from checkbox)" do
      before :each do
        allow(family).to receive(:active_family_members).and_return(family_members)
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:fehb_market).and_return(true)
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:aca_shop_market).and_return(true)
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:contact_method_via_dropdown).and_return(false)
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:prevent_concurrent_sessions).and_return(false)
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:preferred_user_access).and_return(false)
        sign_in user
        get :personal
      end

      it "should assign value" do
        expect(assigns(:contact_preferences_mapping)).not_to be_nil
      end
    end
  end

  describe "GET inbox" do
    before :each do
      allow(family).to receive(:active_family_members).and_return(family_members)
      sign_in user
    end

    it "should be a success" do
      get :inbox
      expect(response).to have_http_status(:success)
    end

    it "should be a success" do
      expect { get '/inbox.BAC' }.to raise_error(ActionController::UrlGenerationError)
    end

    it "should render inbox" do
      get :inbox
      expect(response).to render_template("inbox")
    end

    it "should assign variables" do
      get :inbox
      expect(assigns(:folder)).to eq("Inbox")
    end

    context 'with invalid mime types' do
      it "js should return an error" do
        get :inbox, format: :js
        expect(response).to have_http_status(:not_acceptable)
      end

      it "json should return an error" do
        get :inbox, format: :json
        expect(response).to have_http_status(:not_acceptable)
      end

      it "xml should return an error" do
        get :inbox, format: :xml
        expect(response).to have_http_status(:not_acceptable)
      end
    end
  end

  describe "GET verification, manage_family, personal, inbox with auth" do
    let(:person) { FactoryBot.create(:person, :with_consumer_role) }
    let(:user) { FactoryBot.create(:user, person: person) }
    let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }

    before do
      allow(person).to receive(:primary_family).and_return(family)
      allow(person).to receive(:user).and_return(user)
    end

    context 'as a user not associated with the account' do
      let(:fake_person) { FactoryBot.create(:person, :with_consumer_role) }
      let(:fake_user) { FactoryBot.create(:user, person: fake_person) }
      let!(:fake_family) { FactoryBot.create(:family, :with_primary_family_member, person: fake_person) }

      before do
        fake_person.consumer_role.move_identity_documents_to_verified
        sign_in(fake_user)
      end

      it 'redirects the user to their own account on verification' do
        # unlike some of the other endpoints, /verification needs to check the session[:person_id] to avoid erroring out
        session[:person_id] = person.id
        get :verification, params: { family: family.id }

        expect(response).to render_template("verification")
        expect(assigns(:family)).to eq(fake_family)
      end

      it 'redirects the user to their own account on manage_family' do
        get :manage_family, params: { family: family.id }

        expect(response).to render_template("manage_family")
        expect(assigns(:family)).to eq(fake_family)
      end

      it 'redirects the user to their own account on personal' do
        get :personal, params: { family: family.id }

        expect(response).to render_template("personal")
        expect(assigns(:family)).to eq(fake_family)
      end

      it 'redirects the user to their own account on inbox' do
        get :inbox, params: { family: family.id }

        expect(response).to render_template("inbox")
        expect(assigns(:family)).to eq(fake_family)
      end
    end

    context 'as an admin' do
      let!(:admin_person) { FactoryBot.create(:person, :with_hbx_staff_role) }
      let!(:admin_user) { FactoryBot.create(:user, :with_hbx_staff_role, person: admin_person) }
      let!(:permission) { FactoryBot.create(:permission, :super_admin) }

      before do
        admin_person.hbx_staff_role.update_attributes(permission_id: permission.id)
        sign_in(admin_user)
      end

      it 'should be a success on GET verification' do
        # unlike some of the other endpoints, /verification needs to check the session[:person_id] to avoid erroring out
        session[:person_id] = person.id
        get :verification, params: { family: family.id }

        expect(response).to render_template("verification")
        expect(assigns(:family)).to eq(family)
      end

      it 'should be a success on GET manage_family' do
        get :manage_family, params: { family: family.id }

        expect(response).to render_template("manage_family")
        expect(assigns(:family)).to eq(family)
      end

      it 'should be a success on GET personal' do
        get :personal, params: { family: family.id }

        expect(response).to render_template("personal")
        expect(assigns(:family)).to eq(family)
      end

      it 'should be a success on GET inbox' do
        get :inbox, params: { family: family.id }

        expect(response).to render_template("inbox")
        expect(assigns(:family)).to eq(family)
      end
    end

    context 'as broker' do
      let!(:broker_user) {FactoryBot.create(:user, :person => writing_agent.person, roles: ['broker_role', 'broker_agency_staff_role'])}
      let(:broker_agency_profile) { FactoryBot.build(:benefit_sponsors_organizations_broker_agency_profile, market_kind: :individual)}
      let(:writing_agent) { FactoryBot.create(:broker_role, benefit_sponsors_broker_agency_profile_id: broker_agency_profile.id, aasm_state: 'active') }
      let(:assister)  do
        assister = FactoryBot.build(:broker_role,
                                    benefit_sponsors_broker_agency_profile_id: broker_agency_profile.id,
                                    aasm_state: 'active',
                                    npn: "SMECDOA00")
        assister.save(validate: false)
        assister
      end

      context 'associated with the family' do
        before do
          family.broker_agency_accounts << BenefitSponsors::Accounts::BrokerAgencyAccount.new(benefit_sponsors_broker_agency_profile_id: broker_agency_profile.id,
                                                                                              writing_agent_id: writing_agent.id,
                                                                                              start_on: Time.now,
                                                                                              is_active: true)
          sign_in(broker_user)
        end

        it 'should be a success on GET verification' do
          # unlike some of the other endpoints, /verification needs to check the session[:person_id] to avoid erroring out
          session[:person_id] = person.id
          get :verification, params: { family: family.id }

          expect(response).to have_http_status(:success)
          expect(response).to render_template("verification")
          expect(assigns(:family)).to eq(family)
        end

        it 'should be a success on GET manage_family' do
          get :manage_family, params: { family: family.id }

          expect(response).to have_http_status(:success)
          expect(response).to render_template("manage_family")
          expect(assigns(:family)).to eq(family)
        end

        it 'should be a success on GET personal' do
          get :personal, params: { family: family.id }

          expect(response).to have_http_status(:success)
          expect(response).to render_template("personal")
          expect(assigns(:family)).to eq(family)
        end

        it 'should be a success on GET inbox' do
          get :inbox, params: { family: family.id }

          expect(response).to have_http_status(:success)
          expect(response).to render_template("inbox")
          expect(assigns(:family)).to eq(family)
        end
      end

      context 'not associated with the family' do
        before do
          sign_in(broker_user)
        end

        it 'should not be a success on GET verification' do
          # unlike some of the other endpoints, /verification needs to check the session[:person_id] to avoid erroring out
          session[:person_id] = person.id
          get :verification, params: { family: family.id }

          expect(response).to have_http_status(:redirect)
          expect(response).to_not render_template("verification")
          expect(flash[:error]).to eq("Access not allowed for family_policy.verification?, (Pundit policy)")
        end

        it 'should not be a success on GET manage_family' do
          get :manage_family, params: { family: family.id }

          expect(response).to have_http_status(:redirect)
          expect(response).to_not render_template("manage_family")
          expect(flash[:error]).to eq("Access not allowed for family_policy.manage_family?, (Pundit policy)")
        end

        it 'should not be a success on GET personal' do
          get :personal, params: { family: family.id }

          expect(response).to have_http_status(:redirect)
          expect(response).to_not render_template("personal")
          expect(flash[:error]).to eq("Access not allowed for family_policy.personal?, (Pundit policy)")
        end

        it 'should not be a success on GET inbox' do
          get :inbox, params: { family: family.id }

          expect(response).to have_http_status(:redirect)
          expect(response).to_not render_template("inbox")
          expect(flash[:error]).to eq("Access not allowed for family_policy.inbox?, (Pundit policy)")
        end
      end
    end
  end

  describe "GET find_sep" do
    let(:special_enrollment_period) {[double("SpecialEnrollmentPeriod")]}

    context "with a person with an address" do
      before do
        allow(employee_roles.first).to receive(:market_kind).and_return('shop')
        allow(family).to receive_message_chain("special_enrollment_periods.where").and_return([special_enrollment_period])
        sign_in user
      end

      context "with a valid mime type" do
        before :each do
          get :find_sep, params: {hbx_enrollment_id: "2312121212", change_plan: "change_plan"}
        end

        it "should be a success" do
          expect(response).to have_http_status(:success)
        end

        it "should render my account page" do
          expect(response).to render_template("find_sep")
        end

        it "should assign variables" do
          expect(assigns(:hbx_enrollment_id)).to eq("2312121212")
          expect(assigns(:change_plan)).to eq('change_plan')
        end
      end

      context 'with an invalid mime type' do
        it "js should return an error" do
          get :find_sep, params: {hbx_enrollment_id: "2312121212", change_plan: "change_plan"}, format: :js
          expect(response).to have_http_status(:not_acceptable)
        end

        it "json should return an error" do
          get :find_sep, params: {hbx_enrollment_id: "2312121212", change_plan: "change_plan"}, format: :json
          expect(response).to have_http_status(:not_acceptable)
        end

        it "xml should return an error" do
          get :find_sep, params: {hbx_enrollment_id: "2312121212", change_plan: "change_plan"}, format: :xml
          expect(response).to have_http_status(:not_acceptable)
        end
      end
    end
  end

  describe "POST record_sep", dbclean: :after_each do
    before :each do
      date = TimeKeeper.date_of_record - 10.days
      @qle = FactoryBot.create(:qualifying_life_event_kind, :effective_on_event_date)
      @family = FactoryBot.build(:family, :with_primary_family_member)
      special_enrollment_period = @family.special_enrollment_periods.new(effective_on_kind: date)
      special_enrollment_period.selected_effective_on = date.strftime('%m/%d/%Y')
      special_enrollment_period.qualifying_life_event_kind = @qle
      special_enrollment_period.qle_on = date.strftime('%m/%d/%Y')
      special_enrollment_period.save
      allow(person).to receive(:primary_family).and_return(@family)
      allow(person).to receive(:hbx_staff_role).and_return(nil)
      sign_in user
    end

    context 'when its initial enrollment' do
      before :each do
        post :record_sep, params: {qle_id: @qle.id, qle_date: Date.today}
      end

      it "should redirect" do
        special_enrollment_period = @family.special_enrollment_periods.last
        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(new_insured_group_selection_path({person_id: person.id, consumer_role_id: person.consumer_role.try(:id), enrollment_kind: 'sep', effective_on_date: special_enrollment_period.effective_on, qle_id: @qle.id}))
      end
    end

    context 'when its change of plan' do

      before :each do
        allow(@family).to receive(:enrolled_hbx_enrollments).and_return([double])
        post :record_sep, params: {qle_id: @qle.id, qle_date: Date.today}
      end

      it "should redirect with change_plan parameter" do
        expect(response).to have_http_status(:redirect)
        expect(controller).to redirect_to(new_insured_group_selection_path({person_id: person.id, consumer_role_id: person.consumer_role.try(:id), change_plan: 'change_plan', enrollment_kind: 'sep', qle_id: @qle.id}))
      end
    end
  end

  describe "qle kinds" do
    before(:each) do
      @qle = FactoryBot.create(:qualifying_life_event_kind)
      @family = FactoryBot.build(:family, :with_primary_family_member)
      allow(person).to receive(:primary_family).and_return(@family)
      sign_in(user)
    end

    context "#check_marriage_reason" do
      it "renders the check_marriage reason template" do
        get 'check_marriage_reason', params: {:date_val => (TimeKeeper.date_of_record - 10.days).strftime("%m/%d/%Y"), :qle_id => @qle.id, :format => 'js'}, xhr: true
        expect(response).to have_http_status(:success)
        expect(response).to render_template(:check_marriage_reason)
        expect(assigns(:qle_date_calc)).to eq assigns(:qle_date) - Settings.aca.qle.with_in_sixty_days.days
      end
    end

    context "#check_move_reason" do
      it "renders the 'check_move_reason' template" do
        get 'check_move_reason', params: {:date_val => (TimeKeeper.date_of_record - 10.days).strftime("%m/%d/%Y"), :qle_id => @qle.id, :format => 'js'}, xhr: true
        expect(response).to have_http_status(:success)
        expect(response).to render_template(:check_move_reason)
        expect(assigns(:qle_date_calc)).to eq assigns(:qle_date) - Settings.aca.qle.with_in_sixty_days.days
      end

      it "returns qualified_date as true" do
        get 'check_move_reason', params: {:date_val => (TimeKeeper.date_of_record - 10.days).strftime("%m/%d/%Y"), :qle_id => @qle.id, :format => 'js'}, xhr: true
        expect(response).to have_http_status(:success)
        expect(assigns['qualified_date']).to eq(true)
      end

      it "returns qualified_date as false" do
        get 'check_move_reason',  params: {:date_val => (TimeKeeper.date_of_record + 31.days).strftime("%m/%d/%Y"), :qle_id => @qle.id, :format => 'js'}, xhr: true
        expect(response).to have_http_status(:success)
        expect(assigns['qualified_date']).to eq(false)
      end
    end

    context "#check_insurance_reason" do
      it "renders the 'check_insurance_reason' template" do
        get 'check_insurance_reason',  params: {:date_val => (TimeKeeper.date_of_record - 10.days).strftime("%m/%d/%Y"), :qle_id => @qle.id, :format => 'js'}, xhr: true
        expect(response).to have_http_status(:success)
        expect(response).to render_template(:check_insurance_reason)
      end

      it "returns qualified_date as true" do
        get 'check_insurance_reason',params: {:date_val => (TimeKeeper.date_of_record - 10.days).strftime("%m/%d/%Y"), :qle_id => @qle.id, :format => 'js'}, xhr: true
        expect(response).to have_http_status(:success)
        expect(assigns['qualified_date']).to eq(true)
      end

      it "returns qualified_date as false" do
        get 'check_insurance_reason', params: {:date_val => (TimeKeeper.date_of_record + 31.days).strftime("%m/%d/%Y"), :qle_id => @qle.id, :format => 'js'}, xhr: true
        expect(response).to have_http_status(:success)
        expect(assigns['qualified_date']).to eq(false)
      end
    end
  end

  describe "GET check_qle_date", dbclean: :after_each do
    before(:each) do
      sign_in(user)
    end

    it "renders the 'check_qle_date' template" do
      get 'check_qle_date', params: {:date_val => (TimeKeeper.date_of_record - 10.days).strftime("%m/%d/%Y"), :format => 'js'}, xhr: true
      expect(response).to have_http_status(:success)
    end

    describe "with valid params" do
      context 'with the correct mime type' do
        it "returns qualified_date as true" do
          get 'check_qle_date',params: {:date_val => (TimeKeeper.date_of_record - 10.days).strftime("%m/%d/%Y"), :format => 'js'}, xhr: true
          expect(response).to have_http_status(:success)
          expect(assigns['qualified_date']).to eq(true)
        end
      end

      context 'with the incorrect mime type' do
        it "html should return an error" do
          get 'check_qle_date', params: {:date_val => (TimeKeeper.date_of_record - 10.days).strftime("%m/%d/%Y")}, format: :html
          expect(response).to have_http_status(:not_acceptable)
        end

        it "json should return an error" do
          get 'check_qle_date', params: {:date_val => (TimeKeeper.date_of_record - 10.days).strftime("%m/%d/%Y")}, format: :json
          expect(response).to have_http_status(:not_acceptable)
        end

        it "xml should return an error" do
          get 'check_qle_date', params: {:date_val => (TimeKeeper.date_of_record - 10.days).strftime("%m/%d/%Y")}, format: :xml
          expect(response).to have_http_status(:not_acceptable)
        end
      end
    end

    describe "with invalid params" do

      it "returns qualified_date as false for invalid future date" do
        get 'check_qle_date',params: {:date_val => (TimeKeeper.date_of_record + 31.days).strftime("%m/%d/%Y"), :format => 'js'}, xhr: true
        expect(assigns['qualified_date']).to eq(false)
      end

      it "returns qualified_date as false for invalid past date" do
        get 'check_qle_date', params: {:date_val => (TimeKeeper.date_of_record - 61.days).strftime("%m/%d/%Y"), :format => 'js'}, xhr: true
        expect(assigns['qualified_date']).to eq(false)
      end
    end

    context "qle event when person has dual roles" do
      before :each do
        allow(person).to receive(:user).and_return(user)
        allow(person).to receive(:has_active_employee_role?).and_return(true)
        allow(person).to receive(:has_active_consumer_role?).and_return(true)
        @qle = FactoryBot.create(:qualifying_life_event_kind)
        @family = FactoryBot.build(:family, :with_primary_family_member)
        allow(person).to receive(:is_consumer_role_active?).and_return(true)
        @qle = FactoryBot.create(:qualifying_life_event_kind)
        @family = FactoryBot.build(:family, :with_primary_family_member)
        allow(person).to receive(:primary_family).and_return(@family)
      end

      it "future_qualified_date return true/false when qle market kind is shop" do
        date = TimeKeeper.date_of_record.strftime("%m/%d/%Y")
        get :check_qle_date,params: {date_val: date, qle_id: qle.id, format: :js}
        expect(response).to have_http_status(:success)
        expect(assigns(:future_qualified_date)).to eq(false)
      end

      it "future_qualified_date should return nil when qle market kind is indiviual" do
        qle = FactoryBot.build(:qualifying_life_event_kind, market_kind: "individual")
        allow(QualifyingLifeEventKind).to receive(:find).and_return(qle)
        date = TimeKeeper.date_of_record.strftime("%m/%d/%Y")
        get :check_qle_date, params: {date_val: date, qle_id: qle.id, format: :js}
        expect(response).to have_http_status(:success)
        expect(assigns(:qualified_date)).to eq true
        expect(assigns(:future_qualified_date)).to eq(nil)
      end
    end

    context "GET check_qle_date", dbclean: :after_each do
      include_context "setup benefit market with market catalogs and product packages"
      include_context "setup initial benefit application"

      let(:current_effective_date) { TimeKeeper.date_of_record.beginning_of_month }

      let!(:user) { FactoryBot.create(:user) }
      let!(:person1) { FactoryBot.create(:person) }
      let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person1) }

      let(:employee_role) {FactoryBot.create(:employee_role, person: person1, employer_profile: abc_profile)}
      let(:census_employee) { create(:census_employee, benefit_sponsorship: benefit_sponsorship, employer_profile: abc_profile) }

      before :each do
        allow(user).to receive(:person).and_return person1
        allow(person1).to receive(:primary_family).and_return family
        allow(employee_role).to receive(:census_employee).and_return census_employee
      end

      context "normal qle event" do
        it "should return true" do
          date = TimeKeeper.date_of_record.strftime("%m/%d/%Y")
          get :check_qle_date,params: {date_val: date, format: :js}
          expect(response).to have_http_status(:success)
          expect(assigns(:qualified_date)).to eq true
        end

        it "should return false" do
          sign_in user
          date = (TimeKeeper.date_of_record + 40.days).strftime("%m/%d/%Y")
          get :check_qle_date, params: {date_val: date, format: :js}
          expect(response).to have_http_status(:success)
          expect(assigns(:qualified_date)).to eq false
        end
      end

      context "QLEK based on event date", dbclean: :after_each do
        subject { BenefitSponsors::Observers::NoticeObserver.new }

        before(:each) do
          sign_in(user)
        end

        it "should return event date" do
          date = (TimeKeeper.date_of_record + 8.days).strftime("%m/%d/%Y")
          qle.update_attributes(qle_event_date_kind: :qle_on)
          get :check_qle_date, params: {date_val: date, qle_id: qle.id, format: :js}
          expect(response).to have_http_status(:success)
          expect(assigns(:qle_date)).to eq Date.strptime(date, "%m/%d/%Y")
        end
      end

      context "QLEK based on reporting date", dbclean: :after_each do
        subject { BenefitSponsors::Observers::NoticeObserver.new }

        before(:each) do
          sign_in(user)
        end

        it "should return reporting date" do
          date = (TimeKeeper.date_of_record + 8.days).strftime("%m/%d/%Y")
          qle.update_attributes(qle_event_date_kind: :submitted_at)
          get :check_qle_date, params: {date_val: date, qle_id: qle.id, format: :js}
          expect(response).to have_http_status(:success)
          expect(assigns(:qle_date)).to eq TimeKeeper.date_of_record
        end
      end

      context "QLEK with eligibity start & end dates", dbclean: :after_each do
        subject { BenefitSponsors::Observers::NoticeObserver.new }

        before(:each) do
          sign_in(user)
        end

        context "Event date cover eligibity dates" do

          it "should return true" do
            date = (TimeKeeper.date_of_record + 8.days).strftime("%m/%d/%Y")
            qle.update_attributes(qle_event_date_kind: :qle_on, coverage_start_on: TimeKeeper.date_of_record, coverage_end_on: TimeKeeper.date_of_record.next_month.end_of_month)
            get :check_qle_date, params: {date_val: date, qle_id: qle.id, format: :js}
            expect(response).to have_http_status(:success)
            expect(assigns(:qualified_date)).to eq true
          end
        end

        context "Event date outside eligibity dates" do

          it "should return false" do
            date = (TimeKeeper.date_of_record + 8.days).strftime("%m/%d/%Y")
            qle.update_attributes(qle_event_date_kind: :qle_on, coverage_start_on: TimeKeeper.date_of_record.last_month, coverage_end_on: TimeKeeper.date_of_record)
            get :check_qle_date, params: {date_val: date, qle_id: qle.id, format: :js}
            expect(response).to have_http_status(:success)
            expect(assigns(:qualified_date)).to eq false
          end
        end

        context "Reporting date cover eligibity dates" do

          it "should return true" do
            date = (TimeKeeper.date_of_record + 8.days).strftime("%m/%d/%Y")
            qle.update_attributes(qle_event_date_kind: :submitted_at, coverage_start_on: TimeKeeper.date_of_record, coverage_end_on: TimeKeeper.date_of_record.end_of_month)
            get :check_qle_date, params: {date_val: date, qle_id: qle.id, format: :js}
            expect(response).to have_http_status(:success)
            expect(assigns(:qualified_date)).to eq true
          end
        end

        context "Reporting date outside eligibity dates" do

          it "should return false" do
            date = (TimeKeeper.date_of_record + 8.days).strftime("%m/%d/%Y")
            qle.update_attributes(qle_event_date_kind: :submitted_at, coverage_start_on: TimeKeeper.date_of_record.last_month, coverage_end_on: TimeKeeper.date_of_record - 1.day)
            get :check_qle_date, params: {date_val: date, qle_id: qle.id, format: :js}
            expect(response).to have_http_status(:success)
            expect(assigns(:qualified_date)).to eq false
          end
        end
      end

      context "special qle events which can not have future date" do
        subject { BenefitSponsors::Observers::NoticeObserver.new }

        before(:each) do
          sign_in(user)
        end

        it "should return true" do
          date = (TimeKeeper.date_of_record + 8.days).strftime("%m/%d/%Y")
          get :check_qle_date, params: {date_val: date, qle_id: qle.id, format: :js}
          expect(response).to have_http_status(:success)
          expect(assigns(:qualified_date)).to eq true
        end

        it "should return false" do
          date = (TimeKeeper.date_of_record - 8.days).strftime("%m/%d/%Y")
          get :check_qle_date, params: {date_val: date, qle_id: qle.id, format: :js}
          expect(response).to have_http_status(:success)
          expect(assigns(:qualified_date)).to eq false
        end

        it "should return false and also notify sep request denied" do
          date = TimeKeeper.date_of_record.prev_month.strftime("%m/%d/%Y")
          get :check_qle_date, params: {qle_id: qle.id, date_val: date, qle_title: qle.title, qle_reporting_deadline: date, qle_event_on: date, format: :js}
          expect(assigns(:qualified_date)).to eq false

          expect(subject.notifier).to receive(:notify) do |event_name, payload|
            expect(event_name).to eq "acapi.info.events.employee.employee_notice_for_sep_denial"
            expect(payload[:event_object_kind]).to eq 'BenefitSponsors::BenefitApplications::BenefitApplication'
            expect(payload[:event_object_id]).to eq initial_application.id.to_s
            expect(payload[:notice_params][:qle_title]).to eq qle.title
            expect(payload[:notice_params][:qle_reporting_deadline]).to eq date
            expect(payload[:notice_params][:qle_event_on]).to eq date
          end
          subject.deliver(recipient: employee_role, event_object: initial_application, notice_event: "employee_notice_for_sep_denial", notice_params: {qle_title: qle.title, qle_reporting_deadline: date, qle_event_on: date})
        end

        it "should have effective_on_options" do
          date = (TimeKeeper.date_of_record - 8.days).strftime("%m/%d/%Y")
          effective_on_options = [TimeKeeper.date_of_record, TimeKeeper.date_of_record - 10.days]
          allow(QualifyingLifeEventKind).to receive(:find).and_return(qle)
          allow(qle).to receive(:is_dependent_loss_of_coverage?).and_return(true)
          allow(qle).to receive(:employee_gaining_medicare).and_return(effective_on_options)
          get :check_qle_date, params: {date_val: date, qle_id: qle.id, format: :js}
          expect(response).to have_http_status(:success)
        end
      end
    end

    context "delete delete_consumer_broker" do
      let(:family) {FactoryBot.build(:family)}
      before :each do
        allow(EnrollRegistry[:send_broker_fired_event_to_edi].feature).to receive(:is_enabled).and_return(true)
        allow(person).to receive(:hbx_staff_role).and_return(double('hbx_staff_role', permission: double('permission',modify_family: true)))
        allow(person).to receive(:agent?).and_return(true)
        family.broker_agency_accounts = [
          FactoryBot.build(:broker_agency_account, family: family, employer_profile: nil)
        ]
        allow(Family).to receive(:find).and_return family
      end

      it "should delete consumer broker" do
        expect(family).to receive(:notify_broker_update_on_impacted_enrollments_to_edi)
        delete :delete_consumer_broker, params: {:id => family.id }
        expect(response).to have_http_status(:redirect)
        expect(family.current_broker_agency).to be nil
      end
    end
  end

  describe 'GET sep_zip_compare', dbclean: :after_each do
    # TODO: Refactor this
    # Will need to make it work without this
    # Also for MA too
    if EnrollRegistry[:enroll_app].setting(:site_key) == 'me'
      let!(:service_area) { FactoryBot.create(:benefit_markets_locations_service_area, covered_states: nil, county_zip_ids: [county_zip.id]) }
      let(:county_zip) { FactoryBot.create(:benefit_markets_locations_county_zip, zip: '04330', county_name: 'Kennebec')}
      let(:approved_response) do
        {is_approved: true}.to_json
      end
      let(:rejected_response) do
        {is_approved: false}.to_json
      end
      before(:each) do
        sign_in(user)
        get :sep_zip_compare, params: {old_zip: old_zip, new_zip: new_zip}
      end

      context 'new zip is outside state' do
        let(:new_zip) { '11111' }
        let(:old_zip) { '' }

        it 'should return false' do
          expect(response.body).to eq rejected_response
        end
      end

      context 'new zip is inside state & old zip is outside' do
        let(:new_zip) { county_zip.zip }
        let(:old_zip) { '12312' }

        it 'should return true' do
          expect(response.body).to eq approved_response
        end
      end

      context 'new zip & old zip is inside state' do
        let(:new_zip) { county_zip.zip }

        context 'old zip is in same county' do
          let(:old_county_zip) { FactoryBot.create(:benefit_markets_locations_county_zip, zip: '04260', county_name: county_zip.county_name)}
          let(:old_zip) { old_county_zip.zip }

          it 'should return false' do
            expect(response.body).to eq rejected_response
          end
        end

        context 'old zip is in different county' do
          let(:old_county_zip) do
            FactoryBot.create(
              :benefit_markets_locations_county_zip,
              zip: EnrollRegistry[:enroll_app].setting(:contact_center_zip_code).item,
              county_name: EnrollRegistry[:enroll_app].setting(:contact_center_county).item
            )
          end
          let(:old_zip) { old_county_zip.zip }

          it 'should return true' do
            expect(response.body).to eq approved_response
          end
        end
      end
    end
  end

  describe "GET upload_notice_form", dbclean: :after_each do
    let(:person) { FactoryBot.create(:person, :with_hbx_staff_role) }
    let(:user) { FactoryBot.create(:user, person: person, roles: ["hbx_staff"]) }
    let(:permission) { FactoryBot.create(:permission, :hbx_staff) }

    before(:each) do
      allow(EnrollRegistry[:show_upload_notices].feature).to receive(:is_enabled).and_return(true)
      user.person.hbx_staff_role.update!(permission_id: permission.id)
      sign_in(user)
    end

    it "displays the upload_notice_form view" do
      get :upload_notice_form
      expect(response).to have_http_status(:success)
      expect(response).to render_template(:upload_notice_form)
    end

    it "should redirect unless enabled" do
      allow(EnrollRegistry[:show_upload_notices].feature).to receive(:is_enabled).and_return(false)
      get :upload_notice_form
      expect(response).to redirect_to(root_path)
      expect(flash[:notice]).to eq("Upload Notice Form is Disabled")
    end

    context 'invalid mime types' do
      it "js should return an error" do
        get :upload_notice_form, format: :js
        expect(response).to have_http_status(:not_acceptable)
      end

      it "json should return an error" do
        get :upload_notice_form, format: :json
        expect(response).to have_http_status(:not_acceptable)
      end

      it "xml should return an error" do
        get :upload_notice_form, format: :xml
        expect(response).to have_http_status(:not_acceptable)
      end
    end
  end

  describe "GET upload_application" do
    let(:person) { FactoryBot.create(:person, :with_hbx_staff_role) }
    let(:user) { FactoryBot.create(:user, person: person, roles: ["hbx_staff"]) }
    let(:permission) { FactoryBot.create(:permission, :hbx_staff) }

    before(:each) do
      user.person.hbx_staff_role.update!(permission_id: permission.id)
      sign_in(user)
    end

    context 'with valid/invalid mime types' do
      it "html should return success" do
        get :upload_application
        expect(response).to have_http_status(:success)
      end

      it "js should return an error" do
        get :upload_application, format: :js
        expect(response).to have_http_status(:not_acceptable)
      end

      it "json should return an error" do
        get :upload_application, format: :json
        expect(response).to have_http_status(:not_acceptable)
      end

      it "xml should return an error" do
        get :upload_application, format: :xml
        expect(response).to have_http_status(:not_acceptable)
      end
    end
  end

  describe "GET healthcare_for_childcare_program" do
    let(:person) { FactoryBot.create(:person, :with_hbx_staff_role, :with_consumer_role) }
    let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
    let(:user) { FactoryBot.create(:user, person: person, roles: ["hbx_staff"]) }
    let(:permission) { FactoryBot.create(:permission, :hbx_staff) }

    before(:each) do
      allow(controller).to receive(:ivl_osse_enabled?).and_return(true)
      user.person.hbx_staff_role.update!(permission_id: permission.id)
      sign_in(user)
    end

    context 'with valid/invalid mime types' do
      it "html should return success" do
        get :healthcare_for_childcare_program, params: { person_id: person.id }
        expect(response).to have_http_status(:success)
      end

      it "js should return an error" do
        get :healthcare_for_childcare_program, params: { person_id: person.id }, format: :js
        expect(response).to have_http_status(:not_acceptable)
      end

      it "json should return an error" do
        get :healthcare_for_childcare_program, params: { person_id: person.id }, format: :json
        expect(response).to have_http_status(:not_acceptable)
      end

      it "xml should return an error" do
        get :healthcare_for_childcare_program, params: { person_id: person.id }, format: :xml
        expect(response).to have_http_status(:not_acceptable)
      end
    end
  end

  describe "GET healthcare_for_childcare_program_form" do
    let(:person) { FactoryBot.create(:person, :with_hbx_staff_role) }
    let(:user) { FactoryBot.create(:user, person: person, roles: ["hbx_staff"]) }
    let(:permission) { FactoryBot.create(:permission, :hbx_staff) }

    before(:each) do
      user.person.hbx_staff_role.update!(permission_id: permission.id)
      sign_in(user)
    end

    context 'with valid/invalid mime types' do
      it "html should return success" do
        get :healthcare_for_childcare_program_form, params: { person_id: person.id }
        expect(response).to have_http_status(:success)
      end

      it "js should return an error" do
        get :healthcare_for_childcare_program_form, params: { person_id: person.id }, format: :js
        expect(response).to have_http_status(:not_acceptable)
      end

      it "json should return an error" do
        get :healthcare_for_childcare_program_form, params: { person_id: person.id }, format: :json
        expect(response).to have_http_status(:not_acceptable)
      end

      it "xml should return an error" do
        get :healthcare_for_childcare_program_form, params: { person_id: person.id }, format: :xml
        expect(response).to have_http_status(:not_acceptable)
      end
    end
  end

  describe "GET brokers" do
    let(:person) { FactoryBot.create(:person, :with_hbx_staff_role) }
    let(:user) { FactoryBot.create(:user, person: person, roles: ["hbx_staff"]) }
    let(:permission) { FactoryBot.create(:permission, :hbx_staff) }

    before(:each) do
      user.person.hbx_staff_role.update!(permission_id: permission.id)
      sign_in(user)
    end

    context 'with valid/invalid mime types' do
      it "html should return success" do
        get :brokers, params: { tab: 'home' }
        expect(response).to have_http_status(:success)
      end

      it "js should return an error" do
        get :brokers, params: { tab: 'home' }, format: :js
        expect(response).to have_http_status(:not_acceptable)
      end

      it "json should return an error" do
        get :brokers, params: { tab: 'home' }, format: :json
        expect(response).to have_http_status(:not_acceptable)
      end

      it "xml should return an error" do
        get :brokers, params: { tab: 'home' }, format: :xml
        expect(response).to have_http_status(:not_acceptable)
      end
    end
  end

  describe "GET check_move_reason" do
    let(:person) { FactoryBot.create(:person, :with_hbx_staff_role) }
    let(:user) { FactoryBot.create(:user, person: person, roles: ["hbx_staff"]) }
    let(:permission) { FactoryBot.create(:permission, :hbx_staff) }
    let(:qle) { FactoryBot.create(:qualifying_life_event_kind, pre_event_sep_in_days: 30, post_event_sep_in_days: 0) }

    before(:each) do
      user.person.hbx_staff_role.update!(permission_id: permission.id)
      sign_in(user)
    end

    context 'with valid/invalid mime types' do
      it "html should return an error" do
        get :check_move_reason, params: {:date_val => (TimeKeeper.date_of_record - 10.days).strftime("%m/%d/%Y"), :qle_id => qle.id}
        expect(response).to have_http_status(:not_acceptable)
      end

      it "js should return success" do
        get :check_move_reason, params: {:date_val => (TimeKeeper.date_of_record - 10.days).strftime("%m/%d/%Y"), :qle_id => qle.id}, format: :js
        expect(response).to have_http_status(:success)
      end

      it "json should return an error" do
        get :check_move_reason, params: {:date_val => (TimeKeeper.date_of_record - 10.days).strftime("%m/%d/%Y"), :qle_id => qle.id}, format: :json
        expect(response).to have_http_status(:not_acceptable)
      end

      it "xml should return an error" do
        get :check_move_reason, params: {:date_val => (TimeKeeper.date_of_record - 10.days).strftime("%m/%d/%Y"), :qle_id => qle.id}, format: :xml
        expect(response).to have_http_status(:not_acceptable)
      end
    end
  end

  describe "GET check_insurance_reason" do
    let(:person) { FactoryBot.create(:person, :with_hbx_staff_role) }
    let(:user) { FactoryBot.create(:user, person: person, roles: ["hbx_staff"]) }
    let(:permission) { FactoryBot.create(:permission, :hbx_staff) }
    let(:qle) { FactoryBot.create(:qualifying_life_event_kind, pre_event_sep_in_days: 30, post_event_sep_in_days: 0) }

    before(:each) do
      user.person.hbx_staff_role.update!(permission_id: permission.id)
      sign_in(user)
    end

    context 'with valid/invalid mime types' do
      it "html should return an error" do
        get :check_insurance_reason, params: {:date_val => (TimeKeeper.date_of_record - 10.days).strftime("%m/%d/%Y"), :qle_id => qle.id}
        expect(response).to have_http_status(:not_acceptable)
      end

      it "js should return success" do
        get :check_insurance_reason, params: {:date_val => (TimeKeeper.date_of_record - 10.days).strftime("%m/%d/%Y"), :qle_id => qle.id}, format: :js
        expect(response).to have_http_status(:success)
      end

      it "json should return an error" do
        get :check_insurance_reason, params: {:date_val => (TimeKeeper.date_of_record - 10.days).strftime("%m/%d/%Y"), :qle_id => qle.id}, format: :json
        expect(response).to have_http_status(:not_acceptable)
      end

      it "xml should return an error" do
        get :check_insurance_reason, params: {:date_val => (TimeKeeper.date_of_record - 10.days).strftime("%m/%d/%Y"), :qle_id => qle.id}, format: :xml
        expect(response).to have_http_status(:not_acceptable)
      end
    end
  end

  describe "GET check_marriage_reason" do
    let(:person) { FactoryBot.create(:person, :with_hbx_staff_role) }
    let(:user) { FactoryBot.create(:user, person: person, roles: ["hbx_staff"]) }
    let(:permission) { FactoryBot.create(:permission, :hbx_staff) }
    let(:qle) { FactoryBot.create(:qualifying_life_event_kind, pre_event_sep_in_days: 30, post_event_sep_in_days: 0) }

    before(:each) do
      user.person.hbx_staff_role.update!(permission_id: permission.id)
      sign_in(user)
    end

    context 'with valid/invalid mime types' do
      it "html should return an error" do
        get :check_marriage_reason, params: {:date_val => (TimeKeeper.date_of_record - 10.days).strftime("%m/%d/%Y"), :qle_id => qle.id}
        expect(response).to have_http_status(:not_acceptable)
      end

      it "js should return success" do
        get :check_marriage_reason, params: {:date_val => (TimeKeeper.date_of_record - 10.days).strftime("%m/%d/%Y"), :qle_id => qle.id}, format: :js
        expect(response).to have_http_status(:success)
      end

      it "json should return an error" do
        get :check_marriage_reason, params: {:date_val => (TimeKeeper.date_of_record - 10.days).strftime("%m/%d/%Y"), :qle_id => qle.id}, format: :json
        expect(response).to have_http_status(:not_acceptable)
      end

      it "xml should return an error" do
        get :check_marriage_reason, params: {:date_val => (TimeKeeper.date_of_record - 10.days).strftime("%m/%d/%Y"), :qle_id => qle.id}, format: :xml
        expect(response).to have_http_status(:not_acceptable)
      end
    end
  end

  describe "GET event_logs", dbclean: :after_each do
    let(:person) { FactoryBot.create(:person, :with_hbx_staff_role) }
    let(:user) { FactoryBot.create(:user, person: person, roles: ["hbx_staff"]) }
    let(:permission) { FactoryBot.create(:permission, :hbx_staff) }

    before(:each) do
      allow(controller).to receive(:authorize).and_return(true)
      user.person.hbx_staff_role.update!(permission_id: permission.id)
      sign_in(user)
    end

    context 'with valid/invalid mime types' do
      it "html should return success" do
        get :event_logs, params: { person_id: person.id }
        expect(response).to have_http_status(:success)
      end

      it "js should return an error" do
        get :event_logs, params: { person_id: person.id }, format: :js
        expect(response).to have_http_status(:not_acceptable)
      end

      it "json should return an error" do
        get :event_logs, params: { person_id: person.id }, format: :json
        expect(response).to have_http_status(:not_acceptable)
      end

      it "xml should return an error" do
        get :event_logs, params: { person_id: person.id }, format: :xml
        expect(response).to have_http_status(:not_acceptable)
      end
    end
  end

  describe "GET upload_notice", dbclean: :after_each do
    let(:consumer_role2) { FactoryBot.create(:consumer_role) }
    let(:person2) { FactoryBot.create(:person, :with_family, :with_ssn, :with_hbx_staff_role) }
    let(:permission) { FactoryBot.create(:permission, :hbx_staff) }
    let(:user2) { FactoryBot.create(:user, person: person2, roles: ["hbx_staff"]) }
    let(:file) { double }
    let(:temp_file) { double }
    let(:file_path) { File.dirname(__FILE__) }
    let(:bucket_name) { 'notices' }
    let(:doc_id) { "urn:openhbx:terms:v1:file_storage:s3:bucket:#{bucket_name}#sample-key" }
    let(:subject) {"New Notice"}

    before(:each) do
      user2.person.hbx_staff_role.update!(permission_id: permission.id)
      @controller = Insured::FamiliesController.new
      allow(file).to receive(:original_filename).and_return("some-filename")
      allow(file).to receive(:tempfile).and_return(temp_file)
      allow(temp_file).to receive(:path)
      @controller.instance_variable_set(:@person, person2)
      allow(@controller).to receive(:file_path).and_return(file_path)
      allow(@controller).to receive(:file_name).and_return("sample-filename")
      allow(@controller).to receive(:file_content_type).and_return("application/pdf")
      allow(Aws::S3Storage).to receive(:save).with(file_path, bucket_name).and_return(doc_id)
      person2.consumer_role = consumer_role2
      person2.consumer_role.gender = 'male'
      person2.save
      request.env["HTTP_REFERER"] = "/insured/families/upload_notice_form"
      sign_in(user2)
    end

    it "when successful displays 'File Saved'" do
      file = fixture_file_upload("#{Rails.root}/test/JavaScript.pdf")
      post :upload_notice, params: {:file => file, :subject => subject}
      expect(flash[:notice]).to eq("File Saved")
      expect(response).to have_http_status(:found)
      expect(response).to be_redirect
    end

    it "does not allow docx files to be uploaded" do
      file = fixture_file_upload("#{Rails.root}/test/sample.docx")
      post :upload_notice, params: {:file => file, :subject => subject}
      expect(flash[:error]).to include("Unable to upload file.")
      expect(response).to be_redirect
    end

    it "when failure displays 'File not uploaded'" do
      post :upload_notice
      expect(flash[:error]).to eq("File or Subject not provided")
      expect(response).to have_http_status(:found)
      expect(response).to be_redirect
    end

    context "notice_upload_secure_message" do

      let(:notice) do
        Document.new({ title: "file_name", creator: "hbx_staff", subject: "notice", identifier: "urn:openhbx:terms:v1:file_storage:s3:bucket:#bucket_name#key",
                       format: "file_content_type" })
      end

      before do
        allow(@controller).to receive(:authorized_document_download_path).with("Person", person2.id, "documents", notice.id).and_return("/path/")
        @controller.send(:notice_upload_secure_message, notice, subject)
      end

      it "adds a message to person inbox" do
        expect(person2.inbox.messages.count).to eq(2) #1 welcome message, 1 upload notification
      end
    end

    context "notice_upload_email" do
      context "person has a consumer role" do
        context "person has chosen to receive electronic communication" do
          it "sends the email" do
            consumer_role2.update_attributes!(contact_method: "Paper and Electronic communications")
            expect(@controller.send(:notice_upload_email)).to be_a_kind_of(Mail::Message)
          end
        end

        context "person has chosen not to receive electronic communication" do
          it "should not sent the email" do
            consumer_role2.update_attributes!(contact_method: "Only Paper communication")
            expect(@controller.send(:notice_upload_email)).to be nil
          end
        end
      end

      context "person has a employee role" do
        let(:employee_role2) { FactoryBot.create(:employee_role) }

        before do
          person2.consumer_role = nil
          person2.employee_roles = [employee_role2]
          person2.save
        end

        context "person has chosen to receive electronic communication" do
          it "sends the email" do
            employee_role2.update_attributes!(contact_method: "Paper and Electronic communications")
            expect(@controller.send(:notice_upload_email)).to be_a_kind_of(Mail::Message)
          end
        end

        context "person has chosen not to receive electronic communication" do
          it "should not sent the email" do
            employee_role2.update_attributes!(contact_method: "Only Paper communication")
            expect(@controller.send(:notice_upload_email)).to be nil
          end
        end
      end
    end
  end

  describe "POST transition_family_members_update" do
    let(:user_with_hbx_staff_role) { FactoryBot.create(:user, :with_family, :hbx_staff) }
    let(:permission) { FactoryBot.create(:permission, :hbx_staff) }

    before :each do
      user_with_hbx_staff_role.person.hbx_staff_role.update!(permission_id: permission.id)
      sign_in(user_with_hbx_staff_role)
    end

    context "should transition consumer to resident" do
      let(:consumer_person) {FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role)}
      let(:consumer_family) { FactoryBot.create(:family, :with_primary_family_member, person: consumer_person) }
      let(:qle) {FactoryBot.create(:qualifying_life_event_kind, title: "Not eligible for marketplace coverage due to citizenship or immigration status", reason: "eligibility_failed_or_documents_not_received_by_due_date ")}

      let(:consumer_params) do
        {
          "transition_effective_date_#{consumer_person.id}" => TimeKeeper.date_of_record.to_s,
          "transition_user_#{consumer_person.id}" => consumer_person.id,
          "transition_market_kind_#{consumer_person.id}" => "resident",
          "transition_reason_#{consumer_person.id}" => "eligibility_failed_or_documents_not_received_by_due_date",
          "family_actions_id" => "family_actions_#{consumer_family.id}",
          "family" => consumer_family.id,
          "qle_id" => qle.id
        }
      end

      it "should transition people" do
        post :transition_family_members_update, params: consumer_params, format: :js, xhr: true
        expect(response).to have_http_status(:success)
      end

      it "should transition people from consumer market to resident market" do
        expect(consumer_person.is_consumer_role_active?).to be_truthy
        post :transition_family_members_update, params: consumer_params, format: :js, xhr: true
        consumer_person.reload
        expect(consumer_person.is_resident_role_active?).to be_truthy
        expect(consumer_person.is_consumer_role_active?).to be_falsey
      end
    end

    context "should transition resident to consumer" do
      let(:resident_person) {FactoryBot.create(:person, :with_resident_role)}
      let(:resident_family) { FactoryBot.create(:family, :with_primary_family_member, person: resident_person) }
      let!(:individual_market_transition) { FactoryBot.create(:individual_market_transition, :resident, person: resident_person) }
      let(:qle) {FactoryBot.create(:qualifying_life_event_kind, title: "Provided documents proving eligibility", reason: "eligibility_documents_provided ")}
      let(:resident_params) do
        {
          "transition_effective_date_#{resident_person.id}" => TimeKeeper.date_of_record.to_s,
          "transition_user_#{resident_person.id}" => resident_person.id,
          "transition_market_kind_#{resident_person.id}" => "consumer",
          "transition_reason_#{resident_person.id}" => "eligibility_documents_provided",
          "family_actions_id" => "family_actions_#{resident_family.id}",
          "family" => resident_family.id,
          "qle_id" => qle.id
        }
      end

      it "should transition people" do
        post :transition_family_members_update, params: resident_params, format: :js, xhr: true
        expect(response).to have_http_status(:success)
      end

      it "should transition people from resident market to consumer market" do
        expect(resident_person.is_resident_role_active?).to be_truthy
        post :transition_family_members_update, params: resident_params, format: :js, xhr: true
        resident_person.reload
        expect(resident_person.is_consumer_role_active?).to be_truthy
        expect(resident_person.is_resident_role_active?).to be_falsey
      end

      it "should trigger_cdc_to_ivl_transition_notice in queue" do
        ActiveJob::Base.queue_adapter = :test
        ActiveJob::Base.queue_adapter.enqueued_jobs = []
        post :transition_family_members_update, params: resident_params, format: :js, xhr: true
        queued_job = ActiveJob::Base.queue_adapter.enqueued_jobs.find do |job_info|
          job_info[:job] == IvlNoticesNotifierJob
        end
        expect(queued_job[:args]).not_to be_empty
        expect(queued_job[:args].include?(resident_person.id.to_s)).to be_truthy
        expect(queued_job[:args].include?('coverall_to_ivl_transition_notice')).to be_truthy
      end
    end
  end

  describe "logged in user has no roles" do
    shared_examples_for "logged in user has no authorization roles for families controller" do |action|
      it "redirects to root with flash message" do
        person = FactoryBot.create(:person, :with_family)
        unauthorized_user = FactoryBot.create(:user, :person => person)
        sign_in(unauthorized_user)

        get action
        expect(response).to redirect_to(root_path)
        expect(flash[:error]).to eq("Access not allowed for family_policy.#{action}?, (Pundit policy)")
      end
    end

    it_behaves_like 'logged in user has no authorization roles for families controller', :home
    it_behaves_like 'logged in user has no authorization roles for families controller', :enrollment_history
    it_behaves_like 'logged in user has no authorization roles for families controller', :manage_family
    it_behaves_like 'logged in user has no authorization roles for families controller', :brokers
    it_behaves_like 'logged in user has no authorization roles for families controller', :find_sep
    it_behaves_like 'logged in user has no authorization roles for families controller', :personal
    it_behaves_like 'logged in user has no authorization roles for families controller', :inbox
    it_behaves_like 'logged in user has no authorization roles for families controller', :healthcare_for_childcare_program
    it_behaves_like 'logged in user has no authorization roles for families controller', :verification
    it_behaves_like 'logged in user has no authorization roles for families controller', :upload_application
    it_behaves_like 'logged in user has no authorization roles for families controller', :check_qle_date
    it_behaves_like 'logged in user has no authorization roles for families controller', :sep_zip_compare
    it_behaves_like 'logged in user has no authorization roles for families controller', :purchase
    it_behaves_like 'logged in user has no authorization roles for families controller', :upload_notice
    it_behaves_like 'logged in user has no authorization roles for families controller', :upload_notice_form
    it_behaves_like 'logged in user has no authorization roles for families controller', :transition_family_members
  end
end

RSpec.describe Insured::FamiliesController, dbclean: :after_each do
  describe "GET purchase" do
    include_context "setup benefit market with market catalogs and product packages"
    include_context "setup initial benefit application"

    let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
    let(:person) { FactoryBot.create(:person, :with_employee_role) }
    let(:user) { FactoryBot.create(:user, person: person) }
    let!(:spon_cal) { double('HbxEnrollmentSponsoredCostCalculator') }
    let(:ivl_person)       { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role) }
    let(:ivl_family)       { FactoryBot.create(:family, :with_primary_family_member, person: ivl_person) }
    let(:current_effective_date) { TimeKeeper.date_of_record.beginning_of_year }
    let(:ivl_user) { FactoryBot.create(:user, person: ivl_person) }
    let(:product) {FactoryBot.create(:benefit_markets_products_health_products_health_product, benefit_market_kind: :aca_individual, kind: :health, csr_variant_id: '01')}
    let!(:hbx_enrollment_member) { FactoryBot.build(:hbx_enrollment_member, applicant_id: family.primary_applicant.id) }
    let!(:ivl_hbx_enrollment_member) { FactoryBot.build(:hbx_enrollment_member, applicant_id: ivl_family.primary_applicant.id) }
    let(:hbx_enrollment) do
      FactoryBot.create(:hbx_enrollment, :with_enrollment_members, :with_product,
                        household: family.active_household,
                        family: family,
                        aasm_state: "coverage_enrolled",
                        effective_on: initial_application.start_on,
                        rating_area_id: initial_application.recorded_rating_area_id,
                        sponsored_benefit_id: initial_application.benefit_packages.first.health_sponsored_benefit.id,
                        sponsored_benefit_package_id: initial_application.benefit_packages.first.id,
                        benefit_sponsorship_id: initial_application.benefit_sponsorship.id,
                        hbx_enrollment_members: [hbx_enrollment_member])
    end

    let(:ivl_enrollment) do
      FactoryBot.create(:hbx_enrollment,
                        family: ivl_family,
                        household: ivl_family.latest_household,
                        coverage_kind: "health",
                        enrollment_kind: "open_enrollment",
                        kind: "individual",
                        product: product,
                        aasm_state: "coverage_selected",
                        hbx_enrollment_members: [ivl_hbx_enrollment_member])
    end

    context "for shop" do
      before :each do
        allow(::HbxEnrollmentSponsoredCostCalculator).to receive(:new).with(hbx_enrollment).and_return(spon_cal)
        allow(spon_cal).to receive(:groups_for_products).with([hbx_enrollment.product]).and_return('')
        allow(person).to receive(:primary_family).and_return(family)
        allow(hbx_enrollment).to receive(:reset_dates_on_previously_covered_members).and_return(true)
        sign_in(user)
        get :purchase, params: { id: family.id,
                                 hbx_enrollment_id: hbx_enrollment.id,
                                 terminate: 'terminate',
                                 "terminate_date_#{hbx_enrollment.hbx_id}": TimeKeeper.date_of_record.to_s}
      end

      it "should get hbx_enrollment" do
        expect(assigns(:enrollment)).to eq hbx_enrollment
      end

      it "should get terminate" do
        expect(assigns(:terminate)).to eq 'terminate'
      end

      it 'should assign terminate_date same as params terminate_date' do
        expect(assigns(:terminate_date)).to eq(TimeKeeper.date_of_record)
      end

      it "should get plan" do
        expect(assigns(:plan)).to be_kind_of(BenefitMarkets::Products::Product)
      end
    end

    context "for individual" do
      before do
        ivl_person.consumer_role.move_identity_documents_to_verified
        allow(ivl_person).to receive(:primary_family).and_return(ivl_family)
        allow(ivl_enrollment).to receive(:reset_dates_on_previously_covered_members).and_return(true)
        sign_in(ivl_user)
      end

      context 'with valid mime type' do
        before :each do
          get :purchase, params: {id: ivl_family.id, hbx_enrollment_id: ivl_enrollment.id, terminate: 'terminate'}
        end

        it "should get hbx_enrollment" do
          expect(assigns(:enrollment)).to eq ivl_enrollment
        end

        it "should get terminate" do
          expect(assigns(:terminate)).to eq 'terminate'
        end

        it "should get plan" do
          expect(assigns(:plan)).to be_kind_of(UnassistedPlanCostDecorator)
        end
      end

      context 'with invalid mime type' do
        it "js should return an error" do
          get :purchase, params: {id: ivl_family.id, hbx_enrollment_id: ivl_enrollment.id, terminate: 'terminate'}, format: :js
          expect(response).to have_http_status(:not_acceptable)
        end

        it "json should return an error" do
          get :purchase, params: {id: ivl_family.id, hbx_enrollment_id: ivl_enrollment.id, terminate: 'terminate'}, format: :json
          expect(response).to have_http_status(:not_acceptable)
        end

        it "xml should return an error" do
          get :purchase, params: {id: ivl_family.id, hbx_enrollment_id: ivl_enrollment.id, terminate: 'terminate'}, format: :xml
          expect(response).to have_http_status(:not_acceptable)
        end
      end
    end

    context 'when a user does not have access' do
      let(:other_person) { FactoryBot.create(:person, :with_family)}
      let(:other_user) { FactoryBot.create(:user, person: other_person) }

      before :each do
        allow(::HbxEnrollmentSponsoredCostCalculator).to receive(:new).with(hbx_enrollment).and_return(spon_cal)
        allow(spon_cal).to receive(:groups_for_products).with([hbx_enrollment.product]).and_return('')
        allow(person).to receive(:primary_family).and_return(family)
        allow(hbx_enrollment).to receive(:reset_dates_on_previously_covered_members).and_return(true)
        sign_in(other_user)
        get :purchase, params: { id: family.id,
                                 hbx_enrollment_id: hbx_enrollment.id,
                                 terminate: 'terminate',
                                 "terminate_date_#{hbx_enrollment.hbx_id}": TimeKeeper.date_of_record.to_s}
      end

      it 'should redirect to root path' do
        expect(response).to redirect_to("/")
        expect(flash["error"]).to eq("Access not allowed for family_policy.purchase?, (Pundit policy)")
      end
    end
  end
end

RSpec.describe Insured::FamiliesController, dbclean: :after_each do
  describe "testing controller without doubles" do
    include_context "setup benefit market with market catalogs and product packages"
    include_context "setup initial benefit application"
    let(:family) { FactoryBot.create(:family, :with_primary_family_member) }
    let!(:spon_cal) { double('HbxEnrollmentSponsoredCostCalculator') }
    let(:ivl_person)       { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role) }
    let(:ivl_family)       { FactoryBot.create(:family, :with_primary_family_member, person: ivl_person) }
    let(:user) { FactoryBot.create(:user, person: person, identity_final_decision_code: "acc") }
    let(:ivl_user) { FactoryBot.create(:user, person: ivl_person, identity_final_decision_code: "acc") }
    let(:product) {FactoryBot.create(:benefit_markets_products_health_products_health_product, benefit_market_kind: :aca_individual, kind: :health, csr_variant_id: '01')}
    let!(:ivl_hbx_enrollment_member) { FactoryBot.build(:hbx_enrollment_member, applicant_id: ivl_family.primary_applicant.id) }
    let!(:ivl_enrollment) do
      FactoryBot.create(:hbx_enrollment,
                        family: ivl_family,
                        household: ivl_family.latest_household,
                        coverage_kind: "health",
                        enrollment_kind: "open_enrollment",
                        kind: "individual",
                        product: product,
                        aasm_state: "coverage_selected",
                        effective_on: TimeKeeper.date_of_record.beginning_of_year,
                        hbx_enrollment_members: [ivl_hbx_enrollment_member])
    end

    let!(:previous_year_ivl) do
      FactoryBot.create(:hbx_enrollment, :older_effective_date, :terminated,
                        family: ivl_family,
                        household: ivl_family.latest_household,
                        coverage_kind: "health",
                        enrollment_kind: "open_enrollment",
                        kind: "individual",
                        product: product,
                        aasm_state: "coverage_selected",
                        is_active: false,
                        effective_on: TimeKeeper.date_of_record - 2.years,
                        hbx_enrollment_members: [ivl_hbx_enrollment_member])
    end

    let!(:this_year_cancelled) do
      FactoryBot.create(:hbx_enrollment, :older_effective_date, :terminated,
                        family: ivl_family,
                        household: ivl_family.latest_household,
                        coverage_kind: "health",
                        enrollment_kind: "open_enrollment",
                        kind: "individual",
                        product: product,
                        aasm_state: "coverage_canceled",
                        terminate_reason: "non_payment",
                        is_active: false,
                        effective_on: TimeKeeper.date_of_record,
                        hbx_enrollment_members: [ivl_hbx_enrollment_member])
    end


    before :each do
      allow(EnrollRegistry).to receive(:feature_enabled?).with(:location_residency_verification_type).and_call_original
      allow(EnrollRegistry).to receive(:feature_enabled?).with(:indian_alaskan_tribe_details).and_call_original
      allow(EnrollRegistry).to receive(:feature_enabled?).with(:include_faa_outstanding_verifications).and_call_original
      allow(EnrollRegistry).to receive(:feature_enabled?).with(:crm_update_family_save).and_call_original
      allow(EnrollRegistry).to receive(:feature_enabled?).with(:validate_quadrant).and_call_original
      allow(EnrollRegistry).to receive(:feature_enabled?).with(:display_county).and_call_original
      allow(EnrollRegistry).to receive(:feature_enabled?).with(:financial_assistance).and_call_original
      allow(EnrollRegistry).to receive(:feature_enabled?).with(:crm_publish_primary_subscriber).and_call_original
      allow(EnrollRegistry).to receive(:feature_enabled?).with(:fehb_market).and_call_original
      allow(EnrollRegistry).to receive(:feature_enabled?).with(:aca_shop_market).and_call_original
      allow(EnrollRegistry).to receive(:feature_enabled?).with(:aca_individual_market).and_call_original
      allow(EnrollRegistry).to receive(:feature_enabled?).with(:include_external_enrollment_in_display_all_enrollments).and_call_original
      allow(EnrollRegistry).to receive(:feature_enabled?).with(:show_non_pay_enrollments).and_call_original
      allow(EnrollRegistry).to receive(:feature_enabled?).with(:home_tiles_current_and_future_only).and_call_original
      allow(EnrollRegistry).to receive(:feature_enabled?).with(:show_non_pay_enrollments).and_call_original
      allow(EnrollRegistry).to receive(:feature_enabled?).with(:show_non_pay_enrollments)
      allow(EnrollRegistry).to receive(:feature_enabled?).with(:validate_ssn).and_return(false)
      allow(EnrollRegistry).to receive(:feature_enabled?).with(:check_for_crm_updates).and_return(true)
      allow(EnrollRegistry).to receive(:feature_enabled?).with(:prevent_concurrent_sessions).and_return(false)
      allow(EnrollRegistry).to receive(:feature_enabled?).with(:alive_status).and_return(false)
      allow(EnrollRegistry).to receive(:feature_enabled?).with(:preferred_user_access).and_return(false)
      ivl_person.consumer_role.move_identity_documents_to_verified
      sign_in(ivl_user)
    end

    context "without any FF " do
      it "should previous year and this year" do
        get :home, params: {:family => ivl_family.id.to_s}
        expect(assigns(:hbx_enrollments)).to eq([previous_year_ivl, ivl_enrollment])
      end
    end

    context "ivl with 'current and future only' FF " do
      before :each do
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:home_tiles_current_and_future_only).and_return(true)
        get :home, params: {:family => ivl_family.id.to_s}
      end

      it "should only return this year enrollment" do
        expect(assigns(:hbx_enrollments)).to eq([ivl_enrollment])
      end

      it "admin should see all enrollments for this year" do
        expect(assigns(:all_hbx_enrollments_for_admin)).to eq([this_year_cancelled, ivl_enrollment])
      end
    end

    context "ivl with 'show non pay enrollments' FF " do
      before :each do
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:show_non_pay_enrollments).and_return(true)
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:validate_ssn).and_return(false)
        get :home, params: {:family => ivl_family.id.to_s}
      end

      it "should only return this year enrollment" do
        expect(assigns(:hbx_enrollments)).to eq([this_year_cancelled, ivl_enrollment, previous_year_ivl])
      end
    end
  end
end
