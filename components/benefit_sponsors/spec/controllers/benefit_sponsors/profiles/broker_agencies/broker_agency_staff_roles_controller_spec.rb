require 'rails_helper'

module BenefitSponsors
  RSpec.describe Profiles::BrokerAgencies::BrokerAgencyStaffRolesController, type: :controller, dbclean: :after_each do

    routes { BenefitSponsors::Engine.routes }

    before do
      DatabaseCleaner.clean
    end

    # Brokers/Agents
    let(:user)                           { FactoryBot.create(:user, person: new_person_for_staff) }
    let(:agent_user)                     { FactoryBot.create(:user, person: new_person_for_staff1) }
    let!(:new_person_for_staff)          { FactoryBot.create(:person) }
    let!(:new_person_for_staff1)         { FactoryBot.create(:person) }

    # Organizations
    let!(:site)                          { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
    let!(:organization)                  { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_broker_agency_profile, site: site) }
    let(:organization_with_hbx_profile)  { site.owner_organization }
    let!(:broker_agency_profile)         { organization.broker_agency_profile }
    let(:bap_id)                         { broker_agency_profile.id }

    let!(:second_organization)           { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_broker_agency_profile, site: site) }
    let!(:second_broker_agency_profile)  { second_organization.broker_agency_profile }

    # Roles
    let!(:broker_role)                   { FactoryBot.create(:broker_role, aasm_state: 'active', benefit_sponsors_broker_agency_profile_id: bap_id, person: new_person_for_staff) }
    let!(:broker_agency_staff_role)      { FactoryBot.create(:broker_agency_staff_role, benefit_sponsors_broker_agency_profile_id: bap_id, person: new_person_for_staff1) }
    let!(:broker_agency_staff_role1)     { FactoryBot.create(:broker_agency_staff_role, benefit_sponsors_broker_agency_profile_id: bap_id, person: new_person_for_staff) }

    let(:staff_class) { BenefitSponsors::Organizations::OrganizationForms::StaffRoleForm }

    describe "GET new" do
      before do
        allow(controller).to receive(:set_ie_flash_by_announcement).and_return true
      end

      context 'for a broker in the agency' do
        before do
          sign_in user
          # there is always a profile_id present in the params when calling #new, no profile_id will throw an error in the view
          get :new, params: { profile_id: bap_id }, format: :js, xhr: true
        end

        it "should render new template" do
          expect(response).to render_template("new")
        end

        it "should initialize staff" do
          expect(assigns(:staff).class).to eq staff_class
        end

        it "should return http success" do
          expect(response).to have_http_status(:success)
        end
      end

      context 'for broker agency staff' do
        before do
          sign_in agent_user
          # there is always a profile_id present in the params when calling #new, no profile_id will throw an error in the view
          get :new, params: { profile_id: bap_id }, format: :js, xhr: true
        end

        it "should get a flash error" do
          expect(flash[:error]).to eq 'Access not allowed for can_manage_broker_agency?, (Pundit policy)'
        end

        it "should not initialize staff" do
          expect(assigns(:staff).class).to eq NilClass
        end

        it "should return a 403" do
          expect(response.status).to eq(403)
        end
      end

      context 'for a broker in a different agency' do
        before do
          broker_role.update_attributes(benefit_sponsors_broker_agency_profile_id: second_broker_agency_profile.id)
          sign_in user
          # there is always a profile_id present in the params when calling #new, no profile_id will throw an error in the view
          get :new, params: { profile_id: bap_id }
        end


        it "should not render new template" do
          expect(response).not_to render_template("new")
        end

        it "should not initialize staff" do
          expect(assigns(:staff).class).to eq NilClass
        end

        it "should return http redirect" do
          expect(response).to have_http_status(:redirect)
        end
      end
    end

    describe "POST create" do

      context "creating staff role with existing person params" do

        let!(:staff_params) do
          {
            profile_type: "broker_agency_staff",
            broker_registration_page: "true",
            :staff => {:first_name => new_person_for_staff.first_name, :last_name => new_person_for_staff.last_name, :dob => new_person_for_staff.dob, email: "hello@hello.com",  :profile_id => bap_id}
          }
        end

        before :each do
          sign_in user
          post :create, params: staff_params, format: :js, xhr: true
        end

        it "should initialize staff" do
          expect(assigns(:staff).class).to eq staff_class
        end

        it "should render js template" do
          expect(response.status).to eq(200)
        end

        it "should be a success" do
          expect(response).to have_http_status(:success)
        end

        it 'should get javascript content' do
          expect(response.headers['Content-Type']).to eq 'text/javascript; charset=utf-8'
        end
      end

      context 'person is already assigned as a staff to broker' do

        let!(:staff_params) do
          {
            profile_type: 'broker_agency_staff',
            broker_registration_page: 'true',
            :staff => {:first_name => new_person_for_staff1.first_name, :last_name => new_person_for_staff1.last_name, :dob => new_person_for_staff1.dob, email: "hello@hello.com",  :profile_id => bap_id}
          }
        end

        before :each do
          sign_in user
          post :create, params: staff_params, format: :js, xhr: true
        end

        it 'should render js template' do
          expect(response.status).to eq(200)
        end


        it 'should get javascript content' do
          expect(response.headers['Content-Type']).to eq 'text/javascript; charset=utf-8'
        end
      end

      context 'creating staff role with new person params' do
        let!(:staff_params) do
          {
            profile_type: 'broker_agency_staff',
            broker_registration_page: 'true',
            :staff => {:first_name => "hello", :last_name => "world", :dob => "10/10/1998", email: "hello@hello.com",  :profile_id => bap_id}
          }
        end

        context 'as a broker in the agency' do
          before :each do
            sign_in user
            post :create, params: staff_params, format: :js, xhr: true
          end

          it 'should render js template' do
            expect(response.status).to eq(200)
          end

          it 'should get javascript content' do
            expect(response.headers['Content-Type']).to eq 'text/javascript; charset=utf-8'
          end
        end

        context 'as agency staff' do
          before :each do
            sign_in agent_user
            post :create, params: staff_params, format: :js, xhr: true
          end

          it 'should return a 403' do
            expect(response.status).to eq(403)
          end

          it 'should display a flash error message' do
            expect(flash[:error]).to eq 'Access not allowed for can_manage_broker_agency?, (Pundit policy)'
          end
        end

        context 'as a broker from another agency' do
          before :each do
            broker_role.update_attributes(benefit_sponsors_broker_agency_profile_id: second_broker_agency_profile.id)
            sign_in user
            post :create, params: staff_params, format: :js, xhr: true
          end

          it 'should return a 403' do
            expect(response.status).to eq(403)
          end

          it 'should display a flash error message' do
            expect(flash[:error]).to eq 'Access not allowed for can_manage_broker_agency?, (Pundit policy)'
          end
        end
      end
    end

    describe "GET approve" do
      context "approve applicant staff role" do
        let!(:staff_params) do
          {
            :id => bap_id, :person_id => new_person_for_staff1.id, :profile_id => bap_id
          }
        end

        before do
          broker_agency_staff_role.update_attributes(aasm_state: 'broker_agency_pending')
        end

        context 'as a broker in the agency' do
          before :each do
            sign_in user
            get :approve, params: staff_params
          end

          it "should initialize staff" do
            expect(assigns(:staff).class).to eq staff_class
          end

          it "should redirect" do
            expect(response).to have_http_status(:redirect)
          end

          it "should get an notice" do
            expect(flash[:notice]).to match 'Role approved successfully'
          end

          it "should update broker_agency_staff_role aasm_state to active" do
            broker_agency_staff_role.reload
            expect(broker_agency_staff_role.aasm_state).to eq "active"
          end
        end

        context 'as agency staff' do
          before :each do
            sign_in agent_user
            get :approve, params: staff_params
          end

          it "should initialize staff" do
            expect(assigns(:staff).class).to eq NilClass
          end

          it 'should display a flash error message' do
            expect(flash[:error]).to eq 'Access not allowed for can_manage_broker_agency?, (Pundit policy)'
          end

          it "should not update broker_agency_staff_role aasm_state to active" do
            broker_agency_staff_role.reload
            expect(broker_agency_staff_role.aasm_state).to eq "broker_agency_pending"
          end
        end

        context 'as a broker from another agency' do
          before :each do
            broker_role.update_attributes(benefit_sponsors_broker_agency_profile_id: second_broker_agency_profile.id)
            sign_in agent_user
            get :approve, params: staff_params
          end

          it "should initialize staff" do
            expect(assigns(:staff).class).to eq NilClass
          end

          it 'should display a flash error message' do
            expect(flash[:error]).to eq 'Access not allowed for can_manage_broker_agency?, (Pundit policy)'
          end

          it "should not update broker_agency_staff_role aasm_state to active" do
            broker_agency_staff_role.reload
            expect(broker_agency_staff_role.aasm_state).to eq "broker_agency_pending"
          end
        end
      end

      context "approving invalid staff role" do

        let!(:staff_params) do
          {
            :id => bap_id, :person_id => new_person_for_staff1.id, :profile_id => bap_id
          }
        end

        before :each do
          sign_in user
          broker_agency_staff_role.update_attributes(aasm_state: 'active')
          get :approve, params: staff_params
        end

        it "should redirect" do
          expect(response).to have_http_status(:redirect)
        end

        it "should display a flash error" do
          expect(flash[:error]).to match 'Please contact HBX Admin to report this error'
        end
      end
    end

    describe "DELETE destroy" do
      context "should deactivate staff role" do

        let!(:staff_params) do
          {
            :id => bap_id, :person_id => new_person_for_staff1.id, :profile_id => bap_id
          }
        end
        
        before do
          broker_agency_staff_role.update_attributes(aasm_state: 'active')
        end

        context 'as a broker' do
          before :each do
            sign_in user
            delete :destroy, params: staff_params
          end

          it "should initialize staff" do
            expect(assigns(:staff).class).to eq staff_class
          end

          it "should redirect" do
            expect(response).to have_http_status(:redirect)
          end

          it "should get an notice" do
            expect(flash[:notice]).to match 'Role removed successfully'
          end

          it "should update broker_staff_role aasm_state to broker_agency_terminated" do
            broker_agency_staff_role.reload
            expect(broker_agency_staff_role.aasm_state).to eq "broker_agency_terminated"
          end
        end

        context 'as agency staff' do
          before :each do
            sign_in agent_user
            delete :destroy, params: staff_params
          end

          it "should initialize staff" do
            expect(assigns(:staff).class).to eq NilClass
          end

          it "should redirect" do
            expect(response).to have_http_status(:redirect)
          end

          it 'should display a flash error message' do
            expect(flash[:error]).to eq 'Access not allowed for can_manage_broker_agency?, (Pundit policy)'
          end

          it "should not update broker_staff_role aasm_state to broker_agency_terminated" do
            broker_agency_staff_role.reload
            expect(broker_agency_staff_role.aasm_state).to eq "active"
          end
        end

        context 'as a broker from another agency' do
          before :each do
            broker_role.update_attributes(benefit_sponsors_broker_agency_profile_id: second_broker_agency_profile.id)
            sign_in user
            delete :destroy, params: staff_params
          end

          it "should initialize staff" do
            expect(assigns(:staff).class).to eq NilClass
          end

          it "should redirect" do
            expect(response).to have_http_status(:redirect)
          end

          it 'should display a flash error message' do
            expect(flash[:error]).to eq 'Access not allowed for can_manage_broker_agency?, (Pundit policy)'
          end

          it "should not update broker_staff_role aasm_state to broker_agency_terminated" do
            broker_agency_staff_role.reload
            expect(broker_agency_staff_role.aasm_state).to eq "active"
          end
        end
      end

      context "should not be able to delete their own role" do

        let!(:staff_params) do
          {
            :id => bap_id, :person_id => new_person_for_staff1.id, :profile_id => bap_id
          }
        end

        before :each do
          broker_agency_staff_role.update_attributes(benefit_sponsors_broker_agency_profile_id: bap_id, aasm_state: 'active')
          sign_in agent_user
          delete :destroy, params: staff_params
        end

        it "should redirect" do
          expect(response).to have_http_status(:redirect)
        end

        it "should display a flash error" do
          expect(flash[:error]).to eq 'Access not allowed for can_manage_broker_agency?, (Pundit policy)'
        end
      end
    end

    describe "GET search_broker_agency" do

      before do
        broker_agency_profile.update_attributes!(primary_broker_role_id: broker_role.id)
        broker_agency_profile.approve!
        organization.reload
      end

      context "return result if broker agency is present" do
        let!(:params) do
          {
            q: broker_agency_profile.legal_name,
            broker_registration_page: "true"
          }
        end

        context 'as a broker of any agency' do
          before do
            sign_in user
            get :search_broker_agency, params: params, format: :js, xhr: true
          end

          it 'should be a success' do
            expect(response).to have_http_status(:success)
          end

          it 'should render the new template' do
            expect(response).to render_template('search_broker_agency')
          end

          it 'should assign broker_agency_profiles variable' do
            expect(assigns(:broker_agency_profiles)).to include(broker_agency_profile)
          end
        end

        context 'as staff of any agency' do
          before do
            sign_in agent_user
            get :search_broker_agency, params: params, format: :js, xhr: true
          end

          it 'should be a success' do
            expect(response).to have_http_status(:success)
          end

          it 'should render the new template' do
            expect(response).to render_template('search_broker_agency')
          end

          it 'should assign broker_agency_profiles variable' do
            expect(assigns(:broker_agency_profiles)).to include(broker_agency_profile)
          end
        end
      end

      context "should not return result" do
        let!(:params) do
          {
            q: "hello world",
            broker_registration_page: "true"
          }
        end

        before do
          sign_in user
          get :search_broker_agency, params: params, format: :js, xhr: true
        end

        it 'should be a success' do
          expect(response).to have_http_status(:success)
        end

        it 'should render the new template' do
          expect(response).to render_template('search_broker_agency')
        end

        it 'should assign broker_agency_profiles variable' do
          expect(assigns(:broker_agency_profiles)).not_to include(broker_agency_profile)
        end
      end
    end

    context 'for admins' do
      let!(:permission)               { FactoryBot.create(:permission, :hbx_staff, manage_agency_staff: true, view_agency_staff: true) }
      let!(:user_with_hbx_staff_role) { FactoryBot.create(:user, :with_hbx_staff_role) }
      let!(:hbx_person)               { FactoryBot.create(:person, user: user_with_hbx_staff_role )}

      before do
        user_with_hbx_staff_role.person.build_hbx_staff_role(hbx_profile_id: organization_with_hbx_profile.hbx_profile.id, permission_id: permission.id)
        user_with_hbx_staff_role.person.hbx_staff_role.save!

        sign_in user_with_hbx_staff_role
      end

      context 'with correct permissions' do
        context "GET new" do
          before do
            allow(controller).to receive(:set_ie_flash_by_announcement).and_return true

            get :new, params: { profile_id: bap_id, profile_type: "broker_agency_staff" }
          end

          it "should render new template" do
            expect(response).to render_template("new")
          end

          it "should initialize staff" do
            expect(assigns(:staff).class).to eq staff_class
          end

          it "should return http success" do
            expect(response).to have_http_status(:success)
          end
        end

        context "POST create" do
          let!(:staff_params) do
            {
              profile_type: 'broker_agency_staff',
              broker_registration_page: 'true',
              :staff => {:first_name => "hello", :last_name => "world", :dob => "10/10/1998", email: "hello@hello.com",  :profile_id => bap_id}
            }
          end
  
          before :each do
            post :create, params: staff_params, format: :js, xhr: true
          end

          it 'should render js template' do
            expect(response.status).to eq 200
          end

          it 'should get javascript content' do
            expect(response.headers['Content-Type']).to eq 'text/javascript; charset=utf-8'
          end
        end

        context "GET approve applicant staff role" do
          let!(:staff_params) do
            {
              :id => bap_id, :person_id => new_person_for_staff1.id, :profile_id => bap_id
            }
          end
  
          before :each do
            broker_agency_staff_role.update_attributes(aasm_state: 'broker_agency_pending')
            get :approve, params: staff_params
          end
  
          it "should initialize staff" do
            expect(assigns(:staff).class).to eq staff_class
          end
  
          it "should redirect" do
            expect(response).to have_http_status(:redirect)
          end
  
          it "should get a notice" do
            expect(flash[:notice]).to match 'Role approved successfully'
          end
  
          it "should update broker_agency_staff_role aasm_state to active" do
            broker_agency_staff_role.reload
            expect(broker_agency_staff_role.aasm_state).to eq "active"
          end
        end

        context 'DELETE destroy' do
          let!(:staff_params) do
            {
              :id => bap_id, :person_id => new_person_for_staff1.id, :profile_id => bap_id
            }
          end
  
          before :each do
            broker_agency_staff_role.update_attributes(aasm_state: 'active')
            delete :destroy, params: staff_params
          end
  
          it "should initialize staff" do
            expect(assigns(:staff).class).to eq staff_class
          end
  
          it "should redirect" do
            expect(response).to have_http_status(:redirect)
          end
  
          it "should get an notice" do
            expect(flash[:notice]).to match 'Role removed successfully'
          end
  
          it "should update broker_staff_role aasm_state to broker_agency_terminated" do
            broker_agency_staff_role.reload
            expect(broker_agency_staff_role.aasm_state).to eq "broker_agency_terminated"
          end
        end

        describe "GET search_broker_agency" do
          let!(:params) do
            {
              q: broker_agency_profile.legal_name,
              broker_registration_page: "true"
            }
          end

          before do
            broker_agency_profile.update_attributes!(primary_broker_role_id: broker_role.id)
            broker_agency_profile.approve!
            organization.reload

            get :search_broker_agency, params: params, format: :js, xhr: true
          end
    
          it 'should be a success' do
            expect(response).to have_http_status(:success)
          end
  
          it 'should render the new template' do
            expect(response).to render_template('search_broker_agency')
          end
  
          it 'should assign broker_agency_profiles variable' do
            expect(assigns(:broker_agency_profiles)).to include(broker_agency_profile)
          end
        end
      end

      context 'with insufficient permissions' do
        before do
          permission.update_attributes(manage_agency_staff: false, view_agency_staff: false)
          sign_in user_with_hbx_staff_role
        end

        context "GET new" do
          before do
            allow(controller).to receive(:set_ie_flash_by_announcement).and_return true
            get :new, params: { profile_id: bap_id, profile_type: "broker_agency_staff" }
          end

          it "should not render new template" do
            expect(response).not_to render_template("new")
          end
  
          it "should not initialize staff" do
            expect(assigns(:staff).class).to eq NilClass
          end
  
          it "should redirect" do
            expect(response).to have_http_status(:redirect)
          end
        end

        context "POST create with valid params" do
          let!(:staff_params) do
            {
              profile_type: 'broker_agency_staff',
              broker_registration_page: 'true',
              :staff => {:first_name => "hello", :last_name => "world", :dob => "10/10/1998", email: "hello@hello.com",  :profile_id => bap_id}
            }
          end
  
          before :each do
            post :create, params: staff_params, format: :js, xhr: true
          end

          it 'should return a 403' do
            expect(response.status).to eq 403
          end

          it "should display a flash error" do
            expect(flash[:error]).to eq 'Access not allowed for can_manage_broker_agency?, (Pundit policy)'
          end
        end

        context "GET approve applicant staff role" do
          let!(:staff_params) do
            {
              :id => bap_id, :person_id => new_person_for_staff1.id, :profile_id => bap_id
            }
          end
  
          before :each do
            broker_agency_staff_role.update_attributes(aasm_state: 'broker_agency_pending')
            get :approve, params: staff_params
          end
  
          it "should not initialize staff" do
            expect(assigns(:staff).class).to eq NilClass
          end
  
          it "should redirect" do
            expect(response).to have_http_status(:redirect)
          end
  
          it "should display a flash error" do
            expect(flash[:error]).to eq 'Access not allowed for can_manage_broker_agency?, (Pundit policy)'
          end
  
          it "should not update broker_agency_staff_role aasm_state to active" do
            broker_agency_staff_role.reload
            expect(broker_agency_staff_role.aasm_state).to eq "broker_agency_pending"
          end
        end

        context 'DELETE destroy' do
          let!(:staff_params) do
            {
              :id => bap_id, :person_id => new_person_for_staff1.id, :profile_id => bap_id
            }
          end
  
          before :each do
            broker_agency_staff_role.update_attributes(aasm_state: 'active')
            delete :destroy, params: staff_params
          end
  
          it "should not initialize staff" do
            expect(assigns(:staff).class).to eq NilClass
          end
  
          it "should redirect" do
            expect(response).to have_http_status(:redirect)
          end
  
          it "should display a flash error" do
            expect(flash[:error]).to eq 'Access not allowed for can_manage_broker_agency?, (Pundit policy)'
          end
  
          it "should not update broker_staff_role aasm_state to broker_agency_terminated, should be 'active'" do
            broker_agency_staff_role.reload
            expect(broker_agency_staff_role.aasm_state).to eq "active"
          end
        end

        context "GET search_broker_agency" do
          let!(:params) do
            {
              q: broker_agency_profile.legal_name,
              broker_registration_page: "true"
            }
          end

          before do
            broker_agency_profile.update_attributes!(primary_broker_role_id: broker_role.id)
            broker_agency_profile.approve!
            organization.reload
    
            get :search_broker_agency, params: params, format: :js, xhr: true
          end
    
          it "should return a 403" do
            expect(response.status).to eq(403)
          end
  
          it "should display a flash error" do
            expect(flash[:error]).to eq 'Access not allowed for can_search_broker_agencies?, (Pundit policy)'
          end
  
          it 'should assign broker_agency_profiles variable' do
            expect(assigns(:broker_agency_profiles)).to eq(nil)
          end
        end
      end
    end
  end
end
