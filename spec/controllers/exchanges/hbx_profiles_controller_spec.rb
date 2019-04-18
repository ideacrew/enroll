require 'rails_helper'

RSpec.describe Exchanges::HbxProfilesController, dbclean: :after_each do

  describe "various index" do
    let(:user) { double("user", :has_hbx_staff_role? => true, :has_employer_staff_role? => false)}
    let(:person) { double("person")}
    let(:hbx_staff_role) { double("hbx_staff_role")}
    let(:hbx_profile) { double("HbxProfile")}

    before :each do
      allow(user).to receive(:has_role?).with(:hbx_staff).and_return true
      allow(user).to receive(:person).and_return(person)
      allow(person).to receive(:hbx_staff_role).and_return(hbx_staff_role)
      allow(hbx_staff_role).to receive(:hbx_profile).and_return(hbx_profile)
      sign_in(user)
    end

    it "renders index" do
      get :index
      expect(response).to have_http_status(:success)
      expect(response).to render_template("exchanges/hbx_profiles/index")
    end

    it "renders broker_agency_index" do
      xhr :get, :broker_agency_index
      expect(response).to have_http_status(:success)
      expect(response).to render_template("exchanges/hbx_profiles/broker_agency_index")
    end

    it "renders issuer_index" do
      xhr :get, :issuer_index
      expect(response).to have_http_status(:success)
      expect(response).to render_template("exchanges/hbx_profiles/issuer_index")
    end

    it "renders issuer_index" do
      xhr :get, :product_index
      expect(response).to have_http_status(:success)
      expect(response).to render_template("exchanges/hbx_profiles/product_index")
    end
  end

  describe "binder methods" do
    let(:user) { double("user")}
    let(:person) { double("person")}
    let(:hbx_profile) { double("HbxProfile") }
    let(:hbx_staff_role) { double("hbx_staff_role", permission: FactoryGirl.create(:permission))}
    let(:employer_profile){ FactoryGirl.create(:employer_profile, aasm_state: "enrolling") }

    before(:each) do
      allow(user).to receive(:has_role?).with(:hbx_staff).and_return true
      allow(user).to receive(:person).and_return(person)
      allow(user).to receive(:has_hbx_staff_role?).and_return(true)
      allow(person).to receive(:hbx_staff_role).and_return(hbx_staff_role)
      allow(hbx_staff_role).to receive(:hbx_profile).and_return(hbx_profile)
      sign_in(user)
    end

    it "renders binder_index" do
      xhr :get, :binder_index
      expect(response).to have_http_status(:success)
      expect(response).to render_template("exchanges/hbx_profiles/binder_index")
    end

    it "should render json template" do
      get :binder_index_datatable, {format: :json}
      expect(response).to render_template("exchanges/hbx_profiles/binder_index_datatable")
    end

  end

  describe "new" do
    let(:user) { double("User")}
    let(:person) { double("Person")}

    it "renders new" do
      allow(user).to receive(:has_role?).with(:hbx_staff).and_return true
      allow(user).to receive(:has_hbx_staff_role?).and_return(true)
      sign_in(user)
      get :new
      expect(response).to have_http_status(:success)
    end
  end

  describe "inbox" do
    let(:user) { double("User")}
    let(:person) { double("Person")}
    let(:hbx_staff_role) { double("hbx_staff_role")}
    let(:hbx_profile) { double("HbxProfile", id: double("id"))}

    it "renders inbox" do
      allow(user).to receive(:person).and_return(person)
      allow(user).to receive(:has_role?).with(:hbx_staff).and_return true
      allow(user).to receive(:has_hbx_staff_role?).and_return(true)
      allow(person).to receive(:hbx_staff_role).and_return(hbx_staff_role)
      allow(hbx_staff_role).to receive(:hbx_profile).and_return(hbx_profile)
      sign_in(user)
      xhr :get, :inbox, id: hbx_profile.id
      expect(response).to have_http_status(:success)
    end

  end

  describe "employer_invoice" do
    let(:user) { double("User")}
    let(:person) { double("Person")}
    let(:hbx_staff_role) { double("hbx_staff_role")}
    let(:hbx_profile) { double("HbxProfile", id: double("id"))}
    let(:search_params){{"value"=>""}}

    before :each do
      allow(user).to receive(:person).and_return(person)
      allow(user).to receive(:has_role?).with(:hbx_staff).and_return true
      allow(user).to receive(:has_hbx_staff_role?).and_return(true)
      allow(person).to receive(:hbx_staff_role).and_return(hbx_staff_role)
      allow(hbx_staff_role).to receive(:hbx_profile).and_return(hbx_profile)
      sign_in(user)
    end

    it "renders employer_invoice datatable" do
      xhr :get, :employer_invoice
      expect(response).to have_http_status(:success)
    end

    it "renders employer_invoice datatable payload" do
      xhr :post, :employer_invoice_datatable, :search => search_params
      expect(response).to have_http_status(:success)
    end

  end

  describe "#create" do
    let(:user) { double("User")}
    let(:person) { double("Person")}
    let(:hbx_staff_role) { double("hbx_staff_role")}
    let(:hbx_profile) { double("HbxProfile", id: double("id"))}
    let(:organization){ Organization.new }
    let(:organization_params) { {hbx_profile: {organization: organization.attributes}}}

    before :each do
      sign_in(user)
      allow(user).to receive(:has_role?).with(:hbx_staff).and_return true
      allow(user).to receive(:has_hbx_staff_role?).and_return(true)
      allow(Organization).to receive(:new).and_return(organization)
      allow(organization).to receive(:build_hbx_profile).and_return(hbx_profile)
    end

    it "create new organization if params valid" do
      allow(hbx_profile).to receive(:save).and_return(true)
      post :create, organization_params
      expect(response).to have_http_status(:redirect)
    end

    it "renders new if params invalid" do
      allow(hbx_profile).to receive(:save).and_return(false)
      post :create, organization_params
      expect(response).to render_template("exchanges/hbx_profiles/new")
    end
  end

  describe "#update" do
    let(:user) { FactoryGirl.create(:user, :hbx_staff) }
    let(:person) { double }
    let(:new_hbx_profile){ HbxProfile.new }
    let(:hbx_profile) { FactoryGirl.create(:hbx_profile) }
    let(:hbx_profile_params) { {hbx_profile: new_hbx_profile.attributes, id: hbx_profile.id }}
    let(:hbx_staff_role) {double}

    before :each do
      allow(user).to receive(:has_hbx_staff_role?).and_return(true)
      allow(user).to receive(:person).and_return person
      allow(user).to receive(:has_role?).with(:hbx_staff).and_return true
      allow(HbxProfile).to receive(:find).and_return(hbx_profile)
      allow(person).to receive(:hbx_staff_role).and_return hbx_staff_role
      allow(hbx_staff_role).to receive(:hbx_profile).and_return hbx_profile
      sign_in(user)
    end

    it "updates profile" do
      allow(hbx_profile).to receive(:update).and_return(true)
      put :update, hbx_profile_params
      expect(response).to have_http_status(:redirect)
    end

    it "renders edit if params not valid" do
      allow(hbx_profile).to receive(:update).and_return(false)
      put :update, hbx_profile_params
      expect(response).to render_template("edit")
    end
  end

  describe "#destroy" do
    let(:user){ double("User") }
    let(:person){ double("Person") }
    let(:hbx_profile) { FactoryGirl.create(:hbx_profile) }
    let(:hbx_staff_role) {double}

    it "destroys hbx_profile" do
      allow(user).to receive(:has_hbx_staff_role?).and_return(true)
      allow(user).to receive(:has_role?).with(:hbx_staff).and_return true
      allow(user).to receive(:person).and_return person
      allow(person).to receive(:hbx_staff_role).and_return hbx_staff_role
      allow(hbx_staff_role).to receive(:hbx_profile).and_return hbx_profile
      allow(HbxProfile).to receive(:find).and_return(hbx_profile)
      allow(hbx_profile).to receive(:destroy).and_return(true)
      sign_in(user)
      delete :destroy, id: hbx_profile.id
      expect(response).to have_http_status(:redirect)
    end

  end

  describe "#check_hbx_staff_role" do
    let(:user) { double("user")}
    let(:person) { double("person")}

    it "should render the new template" do
      allow(user).to receive(:has_hbx_staff_role?).and_return(false)
      allow(user).to receive(:has_role?).with(:hbx_staff).and_return true
      sign_in(user)
      get :new
      expect(response).to have_http_status(:redirect)
    end
  end


  describe "Show" do
    let(:user) { double("user", :has_hbx_staff_role? => true, :has_employer_staff_role? => false, :has_csr_role? => false)}
    let(:person) { double("person")}
    let(:hbx_staff_role) { double("hbx_staff_role")}
    let(:hbx_profile) { double("hbx_profile", inbox: double("inbox", unread_messages: double("test")))}

    before :each do
      allow(user).to receive(:has_hbx_staff_role?).and_return(true)
      allow(user).to receive(:has_role?).with(:hbx_staff).and_return true
      allow(user).to receive(:person).and_return(person)
      allow(person).to receive(:hbx_staff_role).and_return(hbx_staff_role)
      allow(hbx_staff_role).to receive(:hbx_profile).and_return(hbx_profile)
      session[:dismiss_announcements] = 'hello'
      sign_in(user)
    end

    it "renders 'show' " do
      get :show
      expect(response).to have_http_status(:success)
      expect(response).to render_template("exchanges/hbx_profiles/show")
    end

    it "should clear session for dismiss_announcements" do
      get :show
      expect(session[:dismiss_announcements]).to eq nil
    end
  end

  describe "#generate_invoice" do
    let(:user) { double("user", :has_hbx_staff_role? => true)}
    let(:employer_profile) { double("EmployerProfile", id: double("id"))}
    let(:organization){ Organization.new }
    let(:hbx_enrollment) { FactoryGirl.build_stubbed :hbx_enrollment }

    before :each do
      sign_in(user)
      allow(organization).to receive(:employer_profile?).and_return(employer_profile)
      allow(employer_profile).to receive(:enrollments_for_billing).and_return([hbx_enrollment])
    end

    it "create new organization if params valid" do
      xhr :get, :generate_invoice, {"employerId"=>[organization.id], ids: [organization.id]} ,  format: :js
      expect(response).to have_http_status(:success)
      # expect(organization.invoices.size).to eq 1
    end
  end

  describe "GET edit_force_publish" do
    context "of an hbx super admin clicks Force Publish" do
      let!(:organization){ FactoryGirl.create(:organization) }
      let!(:employer_profile) { FactoryGirl.create(:employer_profile, organization: organization)}
      let!(:draft_plan_year) { FactoryGirl.create(:future_plan_year, aasm_state: 'draft', employer_profile: employer_profile) }
      let(:user) { FactoryGirl.create(:user, person: person) }
      let(:person) do
        FactoryGirl.create(:person, :with_hbx_staff_role).tap do |person|
          FactoryGirl.create(:permission, :super_admin).tap do |permission|
            person.hbx_staff_role.update_attributes(permission_id: permission.id)
            person
          end
        end
      end

      it "renders edit_force_publish" do
        sign_in(user)
        xhr :get, :edit_force_publish, row_actions_id: "family_actions_#{organization.id.to_s}"
        expect(response).to render_template('edit_force_publish')
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "POST force_publish" do
    context "of an hbx super admin clicks Submit in Force Publish window" do
      let!(:organization) { FactoryGirl.create(:organization) }
      let!(:employer_profile) { FactoryGirl.create(:employer_profile, organization: organization) }
      let!(:draft_plan_year) { FactoryGirl.create(:next_month_plan_year, :with_benefit_group, aasm_state: 'draft', employer_profile: employer_profile) }
      let(:user) { FactoryGirl.create(:user, person: person) }
      let(:person) do
        FactoryGirl.create(:person, :with_hbx_staff_role).tap do |person|
          FactoryGirl.create(:permission, :super_admin).tap do |permission|
            person.hbx_staff_role.update_attributes(permission_id: permission.id)
            person
          end
        end
      end
      let(:params) { { row_actions_id: "family_actions_#{organization.id.to_s}", publish_with_warnings: 'true' } }

      before :each do
        sign_in(user)
        allow(draft_plan_year).to receive(:is_application_invalid?).and_return(false)
        xhr :post, :force_publish, params
        draft_plan_year.reload
      end

      it 'should render template' do
        expect(response).to render_template('force_publish')
      end

      it 'should return success' do
        expect(response).to have_http_status(:success)
      end

      it 'should update plan year' do
        expect(draft_plan_year.aasm_state).to eq 'enrolling'
      end
    end
  end

  describe 'force publish with eligibility warnings & publish_with_warnings param' do
    context 'with only eligibility warnings' do
      let!(:organization) { FactoryGirl.create(:organization) }
      let!(:employer_profile) { FactoryGirl.create(:employer_profile, organization: organization) }
      let!(:draft_plan_year) { FactoryGirl.create(:next_month_plan_year, :with_benefit_group, aasm_state: 'draft', employer_profile: employer_profile) }
      let(:user) { FactoryGirl.create(:user, person: person) }
      let(:person) do
        FactoryGirl.create(:person, :with_hbx_staff_role).tap do |person|
          FactoryGirl.create(:permission, :super_admin).tap do |permission|
            person.hbx_staff_role.update_attributes(permission_id: permission.id)
            person
          end
        end
      end
      let(:params) { { row_actions_id: "family_actions_#{organization.id.to_s}" } }
      let(:params1) { { row_actions_id: "family_actions_#{organization.id.to_s}", publish_with_warnings: 'true' } }

      before :each do
        sign_in(user)
      end

      it 'should not update plan year aasm state' do
        organization.office_locations.first.address.update_attributes!(state: 'CT')
        xhr :post, :force_publish, params
        draft_plan_year.reload
        expect(draft_plan_year.aasm_state).to eq 'draft'
      end

      it 'should not force publish and still in draft' do
        organization.office_locations.first.address.update_attributes!(state: 'CT')
        xhr :post, :force_publish, params
        draft_plan_year.reload
        expect(draft_plan_year.aasm_state).to eq 'draft'
      end

      context 'with publish_with_warnings true & eligibility warnings' do
        it 'should force publish and update plan year to enrolling' do
          organization.office_locations.first.address.update_attributes!(state: 'CT')
          xhr :post, :force_publish, params1
          draft_plan_year.reload
          expect(draft_plan_year.aasm_state).to eq 'publish_pending'
        end
      end

      context 'with publish_with_warnings true & no eligibility warnings' do
        it 'should force publish and update plan year to enrolling' do
          xhr :post, :force_publish, params1
          draft_plan_year.reload
          expect(draft_plan_year.aasm_state).to eq 'enrolling'
        end
      end
    end
  end

  describe "CSR redirection from Show" do
    let(:user) { double("user", :has_hbx_staff_role? => false, :has_employer_staff_role? => false, :has_csr_role? => true)}
    let(:person) { double("person")}
    let(:hbx_staff_role) { double("hbx_staff_role")}
    let(:hbx_profile) { double("hbx_profile", inbox: double("inbox", unread_messages: double("test")))}

    before :each do
      allow(user).to receive(:has_csr_role?).and_return(true)
      allow(user).to receive(:has_role?).with(:csr).and_return true
      allow(user).to receive(:has_role?).with(:hbx_staff).and_return false
      allow(user).to receive(:person).and_return(person)
      sign_in(user)
      get :show
    end

    it "redirects to agents/home " do
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "#disable_ssn_requirement" do
    subject   {xhr :post, :disable_ssn_requirement, {ids: [organization.id]} ,  format: :js}
    let(:user) { double("user", :has_hbx_staff_role? => true)}
    let(:employer_profile) { FactoryGirl.create(:employer_profile, organization: organization)}
    let(:organization){  FactoryGirl.create(:organization) }
    let(:hbx_enrollment) { FactoryGirl.build_stubbed :hbx_enrollment }
    let(:date) { TimeKeeper.datetime_of_record }

    before :each do
      sign_in(user)
    end

    it "renders the 'employer index' template with updated attributes" do
      expect(employer_profile.no_ssn).to be_falsy
      expect(employer_profile.disable_ssn_date).to be_nil
      expect(subject).to redirect_to employer_invoice_exchanges_hbx_profiles_path
      expect(employer_profile.reload.no_ssn).to be_truthy
      expect(employer_profile.disable_ssn_date.to_time).to be_within(5.seconds).of(date)
    end
  end

  describe "GET employer index" do
    let(:user) { double("user", :has_hbx_staff_role? => true, :has_employer_staff_role? => false)}
    let(:person) { double("person")}
    let(:hbx_staff_role) { double("hbx_staff_role")}
    let(:hbx_profile) { double("hbx_profile")}

    before :each do
      expect(controller).to receive(:find_hbx_profile)
      allow(user).to receive(:has_role?).with(:hbx_staff).and_return true
      allow(user).to receive(:has_hbx_staff_role?).and_return(true)
      allow(user).to receive(:person).and_return(person)
      allow(person).to receive(:hbx_staff_role).and_return(hbx_staff_role)
      allow(hbx_staff_role).to receive(:hbx_profile).and_return(hbx_profile)
      sign_in(user)
      get :employer_index
    end

    it "renders the 'employer index' template" do
      expect(response).to have_http_status(:success)
      expect(response).to render_template("employers/employer_profiles/index")
    end
  end

  describe "GET family index" do
    let(:user) { double("User")}
    let(:person) { double("Person")}
    let(:hbx_staff_role) { double("hbx_staff_role")}
    let(:hbx_profile) { double("hbx_profile")}
    let(:csr_role) { double("csr_role", cac: false)}
    before :each do
      allow(person).to receive(:csr_role).and_return(double("csr_role", cac: false))
      allow(user).to receive(:person).and_return(person)
      sign_in(user)
    end

    it "renders the 'families index' template for hbx_staff" do
      allow(user).to receive(:has_hbx_staff_role?).and_return(true)
      get :family_index
      expect(response).to have_http_status(:success)
      expect(response).to render_template("insured/families/index")
    end

    it "renders the 'families index' template for csr" do
      allow(user).to receive(:has_hbx_staff_role?).and_return(false)
      get :family_index
      expect(response).to have_http_status(:success)
      expect(response).to render_template("insured/families/index")
    end

    it "redirects if not csr or hbx_staff 'families index' template for hbx_staff" do
      allow(user).to receive(:has_hbx_staff_role?).and_return(false)
      allow(person).to receive(:csr_role).and_return(false)
      get :family_index
      expect(response).to redirect_to(root_url)
    end

    it "redirects if not csr or hbx_staff 'families index' template for hbx_staff" do
      allow(user).to receive(:has_hbx_staff_role?).and_return(false)
      allow(person).to receive(:csr_role).and_return(double("csr_role", cac: true))
      get :family_index
      expect(response).to redirect_to(root_url)
    end
  end

  describe "GET configuration index" do
    let(:user) { double("user", :has_hbx_staff_role? => true, :has_employer_staff_role? => false)}
    let(:person) { double("person")}
    let(:hbx_staff_role) { double("hbx_staff_role")}
    let(:hbx_profile) { double("hbx_profile")}

    before :each do
      expect(controller).to receive(:find_hbx_profile)
      allow(user).to receive(:has_hbx_staff_role?).and_return(true)
      allow(user).to receive(:has_role?).with(:hbx_staff).and_return true
      allow(user).to receive(:person).and_return(person)
      allow(person).to receive(:hbx_staff_role).and_return(hbx_staff_role)
      allow(hbx_staff_role).to receive(:hbx_profile).and_return(hbx_profile)
      sign_in(user)
      get :configuration
    end

    it "should render the configuration partial" do
      expect(response).to have_http_status(:success)
      expect(response).to render_template(:partial => 'exchanges/hbx_profiles/_configuration_index')
    end
  end

  describe "GET verifications_index_datatable" do

    let(:user) { double("User", :has_hbx_staff_role? => true)}

    before :each do
      sign_in(user)
    end
  end

  describe "POST" do
    let(:user) { FactoryGirl.create(:user)}
    let(:person) { FactoryGirl.create(:person, user: user) }
    let(:hbx_staff_role) { FactoryGirl.create(:hbx_staff_role, person: person) }
    let(:time_keeper_form) { instance_double(Forms::TimeKeeper) }

    before :each do
      allow(user).to receive(:has_hbx_staff_role?).and_return(true)
      allow(user).to receive(:has_role?).with(:hbx_staff).and_return true
      allow(hbx_staff_role).to receive(:permission).and_return(double('Permission', modify_admin_tabs: true))
      sign_in(user)
    end

    it "sends timekeeper a date" do
      timekeeper_form_params = { :date_of_record =>  TimeKeeper.date_of_record.next_day.strftime('%Y-%m-%d') }
      allow(hbx_staff_role).to receive(:permission).and_return(double('Permission', modify_admin_tabs: true))
      allow(Forms::TimeKeeper).to receive(:new).with(timekeeper_form_params).and_return(time_keeper_form)
      allow(time_keeper_form).to receive(:forms_date_of_record).and_return(TimeKeeper.date_of_record.next_day.strftime('%Y-%m-%d'))
      expect(time_keeper_form).to receive(:set_date_of_record).with(TimeKeeper.date_of_record.next_day.strftime('%Y-%m-%d'))
      sign_in(user)
      post :set_date, :forms_time_keeper => { :date_of_record =>  TimeKeeper.date_of_record.next_day.strftime('%Y-%m-%d') }
      expect(response).to have_http_status(:redirect)
    end

    it "sends timekeeper a date and fails because not updateable" do
      allow(hbx_staff_role).to receive(:permission).and_return(double('Permission', modify_admin_tabs: false))
      sign_in(user)
      expect(TimeKeeper).not_to receive(:set_date_of_record).with( TimeKeeper.date_of_record.next_day.strftime('%Y-%m-%d'))
      post :set_date, :forms_time_keeper => { :date_of_record =>  TimeKeeper.date_of_record.next_day.strftime('%Y-%m-%d') }
      expect(response).to have_http_status(:redirect)
      expect(flash[:error]).to match(/Access not allowed/)
    end

    it "update setting" do
      Setting.individual_market_monthly_enrollment_due_on
      allow(hbx_staff_role).to receive(:permission).and_return(double('Permission', modify_admin_tabs: true))
      sign_in(user)

      post :update_setting, :setting => {'name' => 'individual_market_monthly_enrollment_due_on', 'value' => 15}
      expect(response).to have_http_status(:redirect)
      expect(Setting.individual_market_monthly_enrollment_due_on).to eq 15
    end

    it "update setting fails because not updateable" do
      allow(hbx_staff_role).to receive(:permission).and_return(double('Permission', modify_admin_tabs: false))
      sign_in(user)
      post :update_setting, :setting => {'name' => 'individual_market_monthly_enrollment_due_on', 'value' => 19}
      expect(response).to have_http_status(:redirect)
      expect(flash[:error]).to match(/Access not allowed/)
    end
  end

  describe "GET edit_dob_ssn" do

    let(:person) { FactoryGirl.create(:person, :with_consumer_role, :with_employee_role) }
    let(:user) { double("user", :person => person, :has_hbx_staff_role? => true) }
    let(:hbx_staff_role) { FactoryGirl.create(:hbx_staff_role, person: person)}
    let(:hbx_profile) { FactoryGirl.create(:hbx_profile)}
    let(:permission_yes) { FactoryGirl.create(:permission, :can_update_ssn => true)}
    let(:permission_no) { FactoryGirl.create(:permission, :can_update_ssn => false)}

    it "should return authorization error for Non-Admin users" do
      allow(hbx_staff_role).to receive(:permission).and_return permission_yes
      sign_in(user)
      @params = {:id => person.id, :format => 'js'}
      xhr :get, :edit_dob_ssn, @params
      expect(response).to have_http_status(:success)
    end

    it "should render the edit_dob_ssn partial for logged in users with an admin role" do
      allow(hbx_staff_role).to receive(:permission).and_return permission_yes
      sign_in(user)
      @params = {:id => person.id, :format => 'js'}
      xhr :get, :edit_dob_ssn, @params
      expect(response).to have_http_status(:success)
    end

  end

  describe 'GET new_eligibility' do
    let(:person) { FactoryGirl.create(:person, :with_family) }
    let(:user) { double("user", person: person, :has_hbx_staff_role? => true) }
    let(:hbx_staff_role) { FactoryGirl.create(:hbx_staff_role, person: person) }
    let(:hbx_profile) { FactoryGirl.create(:hbx_profile) }
    let(:permission_yes) { FactoryGirl.create(:permission, can_add_pdc: true) }
    let(:params) do
      { person_id: person.id,
         family_actions_id: "family_actions_#{person.primary_family.id.to_s}",
         format: 'js'
       }
    end

    it "should render the new_eligibility partial" do
      allow(hbx_staff_role).to receive(:permission).and_return permission_yes
      sign_in(user)
      xhr :get, :new_eligibility, params

      expect(response).to have_http_status(:success)
      expect(response).to render_template('new_eligibility')
    end

    context 'when can_add_pdc permission is not given' do
      it "should not render the new_eligibility partial" do
        sign_in(user)
        xhr :get, :new_eligibility, params

        expect(response).not_to render_template('new_eligibility')
      end
    end
  end

  describe 'POST create_eligibility' do
    let(:person) { FactoryGirl.create(:person, :with_family) }
    let(:user) { double("user", person: person, :has_hbx_staff_role? => true) }
    let!(:hbx_profile) { FactoryGirl.create(:hbx_profile) }
    let(:max_aptc) { 12 }
    let(:csr) { 100 }
    let(:reason) { 'Test reason' }
    let(:params) do
      { person: {
          person_id: person.id,
          family_actions_id: "family_actions_#{person.primary_family.id.to_s}",
          max_aptc: max_aptc,
          csr: csr,
          effective_date: "2018-04-13",
          family_members: {
            "#{person.primary_family.active_family_members.first.person.hbx_id}" => {
              pdc_type: "is_medicaid_chip_eligible",
              reason: reason
            }
          },
          "jq_datepicker_ignore_person" => { "effective_date" => "04/13/2018" },
          format: 'js'
        }
      }
    end

    it "should render create_eligibility if save successful" do
      sign_in(user)
      xhr :get, :create_eligibility, params
      active_household = person.primary_family.active_household
      latest_active_thh = active_household.reload.latest_active_thh
      eligibility_deter = latest_active_thh.eligibility_determinations.first
      tax_household_member = latest_active_thh.tax_household_members.first

      expect(response).to have_http_status(:success)
      expect(eligibility_deter.max_aptc).to eq(max_aptc.to_f)
      expect(eligibility_deter.csr_percent_as_integer).to eq(csr)
      expect(tax_household_member.is_medicaid_chip_eligible).to be_truthy
      expect(tax_household_member.is_ia_eligible).to be_falsy
      expect(tax_household_member.reason).to eq(reason)
    end
  end


  describe "POST update_dob_ssn" do

    let(:person) { FactoryGirl.create(:person, :with_consumer_role, :with_employee_role) }
    let!(:person1) { FactoryGirl.create(:person, :with_consumer_role) }
    let(:user) { double("user", :person => person, :has_hbx_staff_role? => true) }
    let(:hbx_staff_role) { FactoryGirl.create(:hbx_staff_role, person: person)}
    let(:hbx_profile) { FactoryGirl.create(:hbx_profile)}
    let(:permission_yes) { FactoryGirl.create(:permission, :can_update_ssn => true)}
    let(:permission_no) { FactoryGirl.create(:permission, :can_update_ssn => false)}
    let(:invalid_ssn) { "234-45-839" }
    let(:valid_ssn) { "234-45-8390" }
    let(:valid_dob) { "03/17/1987" }

    it "should render back to edit_enrollment if there is a validation error on save" do
      allow(hbx_staff_role).to receive(:permission).and_return permission_yes
      sign_in(user)
      @params = {:person=>{:pid => person1.id, :ssn => invalid_ssn, :dob => valid_dob},:jq_datepicker_ignore_person=>{:dob=> valid_dob}, :format => 'js'}
      xhr :get, :update_dob_ssn, @params
      expect(response).to render_template('edit_enrollment')
    end

    it "should render update_enrollment if the save is successful" do
      allow(hbx_staff_role).to receive(:permission).and_return permission_yes
      sign_in(user)
      expect(response).to have_http_status(:success)
      @params = {:person=>{:pid => person.id, :ssn => valid_ssn, :dob => valid_dob },:jq_datepicker_ignore_person=>{:dob=> valid_dob}, :format => 'js'}
      xhr :get, :update_dob_ssn, @params
      expect(response).to render_template('update_enrollment')
    end

    it "should set instance variable info changed if consumer role exists" do
      allow(hbx_staff_role).to receive(:permission).and_return permission_yes
      sign_in(user)
      expect(response).to have_http_status(:success)
      @params = {:person=>{:pid => person.id, :ssn => valid_ssn, :dob => valid_dob },:jq_datepicker_ignore_person=>{:dob=> valid_dob}, :format => 'js'}
      xhr :get, :update_dob_ssn, @params
      expect(assigns(:info_changed)). to eq true
    end

    it "should set instance variable dc_status if consumer role exists" do
      allow(hbx_staff_role).to receive(:permission).and_return permission_yes
      sign_in(user)
      expect(response).to have_http_status(:success)
      @params = {:person=>{:pid => person.id, :ssn => valid_ssn, :dob => valid_dob },:jq_datepicker_ignore_person=>{:dob=> valid_dob}, :format => 'js'}
      xhr :get, :update_dob_ssn, @params
      expect(assigns(:dc_status)). to eq false
    end

    it "should render update enrollment if the save is successful" do
      allow(hbx_staff_role).to receive(:permission).and_return permission_yes
      sign_in(user)
      expect(response).to have_http_status(:success)
      @params = {:person=>{:pid => person1.id, :ssn => "" , :dob => valid_dob },:jq_datepicker_ignore_person=>{:dob=> valid_dob}, :format => 'js'}
      xhr :get, :update_dob_ssn, @params
      expect(response).to render_template('update_enrollment')
    end

    it "should return authorization error for Non-Admin users" do
      allow(user).to receive(:has_hbx_staff_role?).and_return false
      sign_in(user)
      xhr :get, :update_dob_ssn
      expect(response).not_to have_http_status(:success)
    end

  end

  describe "GET general_agency_index" do
    let(:user) { FactoryGirl.create(:user, roles: ["hbx_staff"]) }
    before :each do
      allow(user).to receive(:has_hbx_staff_role?).and_return(true)
      sign_in user
    end

    it "should returns http success" do
      xhr :get, :general_agency_index, format: :js
      expect(response).to have_http_status(:success)
    end

    it "should get general_agencies" do
      xhr :get, :general_agency_index, format: :js
      expect(assigns(:general_agency_profiles)).to eq Kaminari.paginate_array(GeneralAgencyProfile.filter_by())
    end
  end

  describe "POST reinstate_enrollment" do
    let(:user) { FactoryGirl.create(:user, roles: ["hbx_staff"]) }

    before :each do
      allow(user).to receive(:has_hbx_staff_role?).and_return(true)
      sign_in user
    end

    it "should redirect to root path" do
      xhr :post, :reinstate_enrollment, enrollment_id: '', format: :js
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(exchanges_hbx_profiles_root_path)
    end
  end

  describe "GET get_user_info" do
    let(:user) { double("User", :has_hbx_staff_role? => true)}
    let(:person) { double("Person", id: double)}
    let(:family_id) { double("Family_ID")}
    let(:employer_id) { double("Employer_ID") }
    let(:organization) { double("Organization")}
    
    before do
      sign_in user
      allow(Person).to receive(:find).with("#{person.id}").and_return person
    end

    context "when action called through families datatable" do

      before do
        xhr :get, :get_user_info, family_actions_id: family_id, person_id: person.id
      end

      it "should populate the person instance variable" do
        expect(assigns(:person)).to eq person
      end

      it "should populate the row id to instance variable" do
        expect(assigns(:element_to_replace_id)).to eq "#{family_id}"
      end
    end

    context "when action called through employers datatable" do

      before do
        allow(Organization).to receive(:find).and_return organization
        xhr :get, :get_user_info, employers_action_id: employer_id, people_id: [person.id]
      end

      it "should not populate the person instance variable" do
        expect(assigns(:person)).to eq nil
      end

      it "should populate the people instance variable" do
        expect(assigns(:people).class).to eq Mongoid::Criteria
      end

      it "should populate the employer_actions instance variable" do
        expect(assigns(:employer_actions)).to eq true
      end

      it "should populate the row id to instance variable" do
        expect(assigns(:element_to_replace_id)).to eq "#{employer_id}"
      end
    end
  end

  describe "POST view_enrollment_to_update_end_date" do
    let(:user) { FactoryGirl.create(:user, roles: ["hbx_staff"]) }
    let!(:person) { FactoryGirl.create(:person)}
    let!(:family) { FactoryGirl.create(:family, :with_primary_family_member, person: person)}
    let!(:household) { FactoryGirl.create(:household, family: family) }
    let!(:enrollment) {
      FactoryGirl.create(:hbx_enrollment,
                         household: family.active_household,
                         coverage_kind: "health",
                         effective_on: TimeKeeper.date_of_record.last_month.beginning_of_month,
                         aasm_state: 'coverage_termination_pending'
      )}

    before :each do
      allow(user).to receive(:has_hbx_staff_role?).and_return(true)
      sign_in user
    end

    it "should render template" do
      xhr :post, :view_enrollment_to_update_end_date, person_id: person.id.to_s, family_actions_id: family.id, format: :js
      expect(response).to have_http_status(:success)
      expect(response).to render_template("view_enrollment_to_update_end_date")
    end
  end

  describe "POST update_enrollment_termianted_on_date" do
    let(:user) { FactoryGirl.create(:user, roles: ["hbx_staff"]) }
    let!(:person) { FactoryGirl.create(:person)}
    let!(:family) { FactoryGirl.create(:family, :with_primary_family_member, person: person)}
    let!(:household) { FactoryGirl.create(:household, family: family) }
    let!(:enrollment) {
      FactoryGirl.create(:hbx_enrollment,
                         household: family.active_household,
                         coverage_kind: "health",
                         kind: 'employer_sponsored',
                         effective_on: TimeKeeper.date_of_record.last_month.beginning_of_month,
                         terminated_on: TimeKeeper.date_of_record.end_of_month,
                         aasm_state: 'coverage_termination_pending'
      )}
    let!(:glue_event_queue_name) { "#{Rails.application.config.acapi.hbx_id}.#{Rails.application.config.acapi.environment_name}.q.glue.enrollment_event_batch_handler" }


    before :each do
      allow(user).to receive(:has_hbx_staff_role?).and_return(true)
      sign_in user
    end

    context "shop enrollment" do
      context "with valid params" do

        it "should render template " do
          xhr :post, :update_enrollment_termianted_on_date, enrollment_id: enrollment.id.to_s, family_actions_id: family.id, new_termination_date: TimeKeeper.date_of_record.to_s, format: :js
          expect(response).to have_http_status(:redirect)
          expect(response).to redirect_to(exchanges_hbx_profiles_root_path)
        end

        context "enrollment that already terminated with past date" do
          context "with new past or current termination date" do
            it "should update enrollment with new end date and notify enrollment" do
              expect_any_instance_of(HbxEnrollment).to receive(:notify).with("acapi.info.events.hbx_enrollment.terminated", {:reply_to=>glue_event_queue_name, "hbx_enrollment_id" => enrollment.hbx_id, "enrollment_action_uri" => "urn:openhbx:terms:v1:enrollment#terminate_enrollment", "is_trading_partner_publishable" => false})
              xhr :post, :update_enrollment_termianted_on_date, enrollment_id: enrollment.id.to_s, family_actions_id: family.id, new_termination_date: TimeKeeper.date_of_record.to_s, format: :js
              enrollment.reload
              expect(enrollment.aasm_state).to eq "coverage_terminated"
              expect(enrollment.terminated_on).to eq TimeKeeper.date_of_record
            end
          end

        end

        context "enrollment that already terminated with future date" do
          context "with new future termination date" do
            it "should update enrollment with new end date and notify enrollment" do
              expect_any_instance_of(HbxEnrollment).to receive(:notify).with("acapi.info.events.hbx_enrollment.terminated", {:reply_to=>glue_event_queue_name, "hbx_enrollment_id" => enrollment.hbx_id, "enrollment_action_uri" => "urn:openhbx:terms:v1:enrollment#terminate_enrollment", "is_trading_partner_publishable" => false})
              xhr :post, :update_enrollment_termianted_on_date, enrollment_id: enrollment.id.to_s, family_actions_id: family.id, new_termination_date: (TimeKeeper.date_of_record + 1.day).to_s, format: :js
              enrollment.reload
              expect(enrollment.aasm_state).to eq "coverage_termination_pending"
              expect(enrollment.terminated_on).to eq TimeKeeper.date_of_record + 1.day
            end
          end
        end
      end
    end

    context "IVL enrollment" do

      before do
        enrollment.kind = "individual"
        enrollment.save
      end

      context "with valid params" do

        it "should render template " do
          xhr :post, :update_enrollment_termianted_on_date, enrollment_id: enrollment.id.to_s, family_actions_id: family.id, new_termination_date: TimeKeeper.date_of_record.to_s, format: :js
          expect(response).to have_http_status(:redirect)
          expect(response).to redirect_to(exchanges_hbx_profiles_root_path)
        end

        context "enrollment that already terminated with past date" do
          context "with new past or current termination date" do
            it "should update enrollment with new end date and notify enrollment" do
              expect_any_instance_of(HbxEnrollment).to receive(:notify).with("acapi.info.events.hbx_enrollment.terminated", {:reply_to=>glue_event_queue_name, "hbx_enrollment_id" => enrollment.hbx_id, "enrollment_action_uri" => "urn:openhbx:terms:v1:enrollment#terminate_enrollment", "is_trading_partner_publishable" => false})
              xhr :post, :update_enrollment_termianted_on_date, enrollment_id: enrollment.id.to_s, family_actions_id: family.id, new_termination_date: TimeKeeper.date_of_record.to_s, format: :js
              enrollment.reload
              expect(enrollment.aasm_state).to eq "coverage_terminated"
              expect(enrollment.terminated_on).to eq TimeKeeper.date_of_record
            end
          end

        end

        context "enrollment that already terminated with future date" do
          context "with new future termination date" do
            it "should update enrollment with new end date and notify enrollment" do
              expect_any_instance_of(HbxEnrollment).to receive(:notify).with("acapi.info.events.hbx_enrollment.terminated", {:reply_to=>glue_event_queue_name, "hbx_enrollment_id" => enrollment.hbx_id, "enrollment_action_uri" => "urn:openhbx:terms:v1:enrollment#terminate_enrollment", "is_trading_partner_publishable" => false})
              xhr :post, :update_enrollment_termianted_on_date, enrollment_id: enrollment.id.to_s, family_actions_id: family.id, new_termination_date: (TimeKeeper.date_of_record + 1.day).to_s, format: :js
              enrollment.reload
              expect(enrollment.aasm_state).to eq "coverage_terminated"
              expect(enrollment.terminated_on).to eq TimeKeeper.date_of_record + 1.day
            end
          end
        end
      end
    end

    context "with invalid params" do
      it "should redirect to root path" do
        xhr :post, :update_enrollment_termianted_on_date, enrollment_id: '', family_actions_id:'', new_termination_date: '', format: :js
        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(exchanges_hbx_profiles_root_path)
      end
    end

  end
end
