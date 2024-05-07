# frozen_string_literal: true

require 'rails_helper'
# spec for BenefitSponsors::Profiles::BrokerAgencies::BrokerAgencyStaffRolesController
module BenefitSponsors # rubocop:disable Metrics/ModuleLength
  RSpec.describe Profiles::BrokerAgencies::BrokerAgencyStaffRolesController, type: :controller, dbclean: :after_each do

    routes { BenefitSponsors::Engine.routes }

    before do
      DatabaseCleaner.clean
    end

    # Brokers/Agents
    let(:new_person_for_staff1)           { FactoryBot.create(:person) }
    let(:new_person_for_staff2)           { FactoryBot.create(:person) }
    let(:user)                            { FactoryBot.create(:user, person: new_person_for_staff1) }
    let(:agent_user)                      { FactoryBot.create(:user, person: new_person_for_staff2) }

    # Organizations
    let!(:site)                           { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
    let!(:organization)                   { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_broker_agency_profile, site: site) }
    let(:organization_with_hbx_profile)   { site.owner_organization }
    let!(:broker_agency_profile)          { organization.broker_agency_profile }
    let(:bap_id)                          { broker_agency_profile.id }

    let!(:second_organization)            { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_broker_agency_profile, site: site) }
    let!(:second_broker_agency_profile)   { second_organization.broker_agency_profile }

    # Roles
    let!(:broker_role)                    { FactoryBot.create(:broker_role, aasm_state: 'active', benefit_sponsors_broker_agency_profile_id: bap_id, person: new_person_for_staff1) }
    let!(:broker_agency_staff_role1)      { FactoryBot.create(:broker_agency_staff_role, benefit_sponsors_broker_agency_profile_id: bap_id, person: new_person_for_staff1) }
    let!(:broker_agency_staff_role2)      { FactoryBot.create(:broker_agency_staff_role, benefit_sponsors_broker_agency_profile_id: bap_id, person: new_person_for_staff2) }

    let(:staff_class)                     { BenefitSponsors::Organizations::OrganizationForms::StaffRoleForm }

    describe "GET new" do
      before do
        allow(controller).to receive(:set_ie_flash_by_announcement).and_return true
      end

      context 'for a broker in the agency' do
        before do
          sign_in user
          # for brokers/staff adding staff to their agency, there is always a profile_id present in the params when calling #new
          # no profile_id will throw an error
          get :new, params: { profile_id: bap_id }, format: :js, xhr: true
        end

        it "should render new template" do
          # refers to components/benefit_sponsors/app/views/benefit_sponsors/profiles/broker_agencies/broker_agency_staff_roles/new.js.erb
          expect(response).to render_template("new")
        end

        it "should initialize a staff form" do
          expect(assigns(:staff).class).to eq staff_class
        end

        it "should return http success" do
          expect(response).to have_http_status(:success)
        end
      end

      context 'for broker agency staff' do
        before do
          sign_in agent_user
          # for brokers/staff adding staff to their agency, there is always a profile_id present in the params when calling #new
          # no profile_id will throw an error
          get :new, params: { profile_id: bap_id }, format: :js, xhr: true
        end

        it "should render new template" do
          # refers to components/benefit_sponsors/app/views/benefit_sponsors/profiles/broker_agencies/broker_agency_staff_roles/new.js.erb
          expect(response).to render_template("new")
        end

        it "should initialize a staff form" do
          expect(assigns(:staff).class).to eq staff_class
        end

        it "should return http success" do
          expect(response).to have_http_status(:success)
        end
      end

      context 'for a broker in a different agency' do
        before do
          broker_role.update_attributes(benefit_sponsors_broker_agency_profile_id: second_broker_agency_profile.id)
          broker_agency_staff_role1.update_attributes(benefit_sponsors_broker_agency_profile_id: second_broker_agency_profile.id)
          sign_in user
        end

        context 'with a real profile_id' do
          before do
            get :new, params: { profile_id: bap_id }, format: :js, xhr: true
          end

          it "should not initialize a staff form" do
            expect(assigns(:staff).class).to eq NilClass
          end

          it "should return a 403" do
            expect(response.status).to eq(403)
          end
        end

        context 'with a fake profile_id' do
          let(:fake_id) { '65f70eb2eadf941f19eaa862' }

          before do
            get :new, params: { profile_id: fake_id }, format: :js, xhr: true
          end

          it "should not initialize a staff form" do
            expect(assigns(:staff).class).to eq NilClass
          end

          it "should return a 403" do
            expect(response.status).to eq(403)
          end

          it "should return a flash message error" do
            expect(flash[:error]).to eq("Access not allowed for Pundit::NotDefinedError, (Pundit policy)")
          end
        end
      end

      context 'for a non-user applying for an existing broker agency using the new registrations view' do
        before do
          # for prospective brokers applying to be staff to an existing agency,
          # the broker_agency_staff param needs to be present
          get :new, params: { profile_type: 'broker_agency_staff' }
        end

        it "should render new template" do
          # refers to components/benefit_sponsors/app/views/benefit_sponsors/profiles/broker_agencies/broker_agency_staff_roles/new.html.slim
          expect(response).to render_template("new")
        end

        it "should initialize a staff form" do
          expect(assigns(:staff).class).to eq BenefitSponsors::Organizations::OrganizationForms::StaffRoleForm
        end

        it "should return success" do
          expect(response).to have_http_status(:success)
        end
      end

      context 'for a non-user applying for an existing broker agency using the broker agency profile view' do
        before do
          # for prospective brokers applying to be staff to an existing agency,
          # the broker_agency_staff param needs to be present
          get :new, params: { profile_id: bap_id }, format: :js, xhr: true
        end

        it "should not initialize a staff form" do
          expect(assigns(:staff).class).to eq NilClass
        end

        it "should return a 403" do
          expect(response.status).to eq(403)
        end
      end
    end

    describe "POST create" do
      let!(:previous_total_staff_roles) { Person.staff_for_broker_including_pending(broker_agency_profile).size }

      context "creating staff role with existing person params" do
        let(:new_person_for_staff3) { FactoryBot.create(:person) }

        let(:staff_params) do
          {
            profile_type: "broker_agency_staff",
            broker_registration_page: "true",
            :staff => {:first_name => new_person_for_staff3.first_name, :last_name => new_person_for_staff3.last_name, :dob => '10/10/1998', email: "howdy@hello.com",  :profile_id => bap_id}
          }
        end

        before do
          sign_in user

          post :create, params: staff_params, format: :js, xhr: true
        end

        it "should initialize staff" do
          expect(assigns(:staff).class).to eq staff_class
        end

        it "should render js template" do
          expect(response.content_type).to eq "text/javascript; charset=utf-8"
        end

        it "should be a success" do
          expect(response).to have_http_status(:success)
        end

        it 'should create a new staff role' do
          new_total_staff_roles = Person.staff_for_broker_including_pending(broker_agency_profile).size

          expect(previous_total_staff_roles).not_to eq(new_total_staff_roles)
        end
      end

      context 'person is already assigned as a staff to broker' do
        let!(:staff_params) do
          {
            profile_type: 'broker_agency_staff',
            broker_registration_page: 'true',
            :staff => {:first_name => new_person_for_staff2.first_name, :last_name => new_person_for_staff2.last_name, :dob => new_person_for_staff2.dob, email: "hello@hello.com",  :profile_id => bap_id}
          }
        end

        before :each do
          sign_in user
          post :create, params: staff_params, format: :js, xhr: true
        end

        it 'should render js template' do
          expect(response.content_type).to eq "text/javascript; charset=utf-8"
        end

        it 'should not create a new staff role' do
          new_total_staff_roles = Person.staff_for_broker_including_pending(broker_agency_profile).size

          expect(previous_total_staff_roles).to eq(new_total_staff_roles)
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

          it 'should return a 200' do
            expect(response.status).to eq(200)
          end

          it 'should create a new staff role' do
            new_total_staff_roles = Person.staff_for_broker_including_pending(broker_agency_profile).size

            expect(previous_total_staff_roles).not_to eq(new_total_staff_roles)
          end
        end

        context 'as agency staff' do
          before :each do
            sign_in agent_user
            post :create, params: staff_params, format: :js, xhr: true
          end

          it 'should return success' do
            expect(response).to have_http_status(200)
          end

          it 'should create a new staff role' do
            new_total_staff_roles = Person.staff_for_broker_including_pending(broker_agency_profile).size

            expect(previous_total_staff_roles).not_to eq(new_total_staff_roles)
          end
        end

        # Even unauthorized users are allowed to access this endpoint by design
        context 'a non-user' do
          before :each do
            post :create, params: staff_params, format: :js, xhr: true
          end

          it 'should return 200' do
            expect(response.status).to eq(200)
          end

          it 'should create a new staff role' do
            new_total_staff_roles = Person.staff_for_broker_including_pending(broker_agency_profile).size

            expect(previous_total_staff_roles).not_to eq(new_total_staff_roles)
          end
        end
      end
    end

    describe "GET approve" do
      context "approve applicant staff role" do
        let!(:staff_params) do
          {
            :id => bap_id, :person_id => new_person_for_staff2.id, :profile_id => bap_id
          }
        end

        context 'as a broker in the agency' do
          before :each do
            broker_agency_staff_role2.update_attributes(aasm_state: 'broker_agency_pending')

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
            expect(flash[:notice]).to eq 'Role approved successfully'
          end

          it "should update broker_agency_staff_role2 aasm_state to active" do
            broker_agency_staff_role2.reload
            expect(broker_agency_staff_role2.aasm_state).to eq "active"
          end
        end

        context 'as agency staff' do
          # initialize new role => agency staff can't approve their own role
          let(:pending_agent)                  { FactoryBot.create(:user, person: new_person_for_staff3) }
          let!(:new_person_for_staff3)         { FactoryBot.create(:person) }
          let!(:broker_agency_staff_role3)     { FactoryBot.create(:broker_agency_staff_role, benefit_sponsors_broker_agency_profile_id: bap_id, person: new_person_for_staff3, aasm_state: 'broker_agency_pending') }

          before :each do
            staff_params[:person_id] = new_person_for_staff3.id
            sign_in agent_user
            get :approve, params: staff_params
          end

          it "should initialize staff" do
            expect(assigns(:staff).class).to eq staff_class
          end

          it "should redirect" do
            expect(response).to have_http_status(:redirect)
          end

          it "should get an notice" do
            expect(flash[:notice]).to eq 'Role approved successfully'
          end

          it "should update broker_agency_staff_role3 aasm_state to active" do
            broker_agency_staff_role3.reload
            expect(broker_agency_staff_role3.aasm_state).to eq "active"
          end
        end

        context 'as a broker from another agency' do
          before :each do
            broker_agency_staff_role2.update_attributes(aasm_state: 'broker_agency_pending')
            broker_role.update_attributes(benefit_sponsors_broker_agency_profile_id: second_broker_agency_profile.id)
            broker_agency_staff_role1.update_attributes(benefit_sponsors_broker_agency_profile_id: second_broker_agency_profile.id)

            sign_in user
            get :approve, params: staff_params
          end

          it 'should display a flash error message' do
            expect(flash[:error]).to eq 'Access not allowed for approve?, (Pundit policy)'
          end

          it "should not update broker_agency_staff_role2 aasm_state to active" do
            broker_agency_staff_role2.reload
            expect(broker_agency_staff_role2.aasm_state).to eq "broker_agency_pending"
          end
        end
      end

      context "approving invalid staff role" do
        let!(:staff_params) do
          {
            :id => bap_id, :person_id => new_person_for_staff2.id, :profile_id => bap_id
          }
        end

        before :each do
          sign_in user
          broker_agency_staff_role2.update_attributes(aasm_state: 'active')
          get :approve, params: staff_params
        end

        it "should redirect" do
          expect(response).to have_http_status(:redirect)
        end

        it "should display a flash error" do
          expect(flash[:error]).to include('Please contact HBX Admin to report this error')
        end
      end
    end

    describe "DELETE destroy" do
      context "should deactivate staff role" do
        before do
          broker_agency_staff_role2.update_attributes(aasm_state: 'active')
        end

        context 'as a broker' do
          let!(:staff_params) do
            { :id => bap_id, :person_id => new_person_for_staff2.id, :profile_id => bap_id }
          end

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
            expect(flash[:notice]).to eq 'Role removed successfully'
          end

          it "should update broker_staff_role aasm_state to broker_agency_terminated" do
            broker_agency_staff_role2.reload
            expect(broker_agency_staff_role2.aasm_state).to eq "broker_agency_terminated"
          end
        end

        context 'as a broker from another agency' do
          let!(:staff_params) do
            { :id => bap_id, :person_id => new_person_for_staff2.id, :profile_id => bap_id }
          end

          before :each do
            broker_role.update_attributes(benefit_sponsors_broker_agency_profile_id: second_broker_agency_profile.id)
            broker_agency_staff_role1.update_attributes(benefit_sponsors_broker_agency_profile_id: second_broker_agency_profile.id)
            sign_in user
            delete :destroy, params: staff_params
          end

          it "should redirect" do
            expect(response).to have_http_status(:redirect)
          end

          it 'should display a flash error message' do
            expect(flash[:error]).to eq 'Access not allowed for destroy?, (Pundit policy)'
          end

          it "should not update broker_staff_role aasm_state to broker_agency_terminated" do
            broker_agency_staff_role2.reload
            expect(broker_agency_staff_role2.aasm_state).to eq "active"
          end
        end
      end

      context "should not be able to delete their own role" do
        let(:staff_params) do
          { :id => bap_id, :person_id => new_person_for_staff2.id, :profile_id => bap_id }
        end

        before :each do
          broker_agency_staff_role2.update_attributes(benefit_sponsors_broker_agency_profile_id: bap_id, aasm_state: 'active')
          sign_in agent_user
          delete :destroy, params: staff_params
        end

        it "should redirect" do
          expect(response).to have_http_status(:redirect)
        end

        it "should display a flash error" do
          expect(flash[:error]).to eq 'Access not allowed for destroy?, (Pundit policy)'
        end

        it "should not update broker_staff_role aasm_state to broker_agency_terminated" do
          broker_agency_staff_role2.reload
          expect(broker_agency_staff_role2.aasm_state).to eq "active"
        end
      end

      context "as a broker in one agency and staff in another should have the same permissions as other agency staff in the latter" do
        let(:bap_id2) { second_broker_agency_profile.id }

        context 'cannot delete themselves' do
          let(:staff_params) do
            { :id => bap_id2, :person_id => new_person_for_staff1.id, :profile_id => bap_id2 }
          end

          before :each do
            sign_in user

            delete :destroy, params: staff_params
          end

          it "should display a flash error" do
            expect(flash[:error]).to eq 'Access not allowed for destroy?, (Pundit policy)'
          end

          it "should not update broker_staff_role aasm_state to broker_agency_terminated" do
            broker_agency_staff_role1.reload
            expect(broker_agency_staff_role1.aasm_state).to eq "active"
          end
        end

        context 'cannot delete the primary_broker staff_role' do
          let(:primary_broker_role) { second_broker_agency_profile.primary_broker_role }
          let(:primary_broker_person) { primary_broker_role.person }
          let(:staff_params) do
            { :id => bap_id2, :person_id => primary_broker_person.id, :profile_id => bap_id2 }
          end

          before :each do
            sign_in user

            delete :destroy, params: staff_params
          end

          it "should display a flash error" do
            expect(flash[:error]).to eq 'Access not allowed for destroy?, (Pundit policy)'
          end

          it "should not update primary_broker_role aasm_state to broker_agency_terminated" do
            broker_agency_staff_role1.reload
            expect(broker_agency_staff_role1.aasm_state).to_not eq "broker_agency_terminated"
          end
        end
      end
    end

    context 'for admins' do
      let!(:user_with_hbx_staff_role) { FactoryBot.create(:user, :with_hbx_staff_role) }
      let!(:hbx_person)               { FactoryBot.create(:person, user: user_with_hbx_staff_role) }

      context 'with super_admin permissions' do
        let!(:permission)               { FactoryBot.create(:permission, :super_admin) }

        before do
          user_with_hbx_staff_role.person.build_hbx_staff_role(hbx_profile_id: organization_with_hbx_profile.hbx_profile.id, permission_id: permission.id)
          user_with_hbx_staff_role.person.hbx_staff_role.save!

          sign_in user_with_hbx_staff_role
        end

        context "GET new" do
          before do
            allow(controller).to receive(:set_ie_flash_by_announcement).and_return true

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
              :id => bap_id, :person_id => new_person_for_staff2.id, :profile_id => bap_id
            }
          end

          before :each do
            broker_agency_staff_role2.update_attributes(aasm_state: 'broker_agency_pending')
            get :approve, params: staff_params
          end

          it "should initialize staff" do
            expect(assigns(:staff).class).to eq staff_class
          end

          it "should redirect" do
            expect(response).to have_http_status(:redirect)
          end

          it "should get a notice" do
            expect(flash[:notice]).to eq 'Role approved successfully'
          end

          it "should update broker_agency_staff_role2 aasm_state to active" do
            broker_agency_staff_role2.reload
            expect(broker_agency_staff_role2.aasm_state).to eq "active"
          end
        end

        context 'DELETE destroy' do
          let!(:staff_params) do
            {
              :id => bap_id, :person_id => new_person_for_staff2.id, :profile_id => bap_id
            }
          end

          before :each do
            broker_agency_staff_role2.update_attributes(aasm_state: 'active')
            delete :destroy, params: staff_params
          end

          it "should initialize staff" do
            expect(assigns(:staff).class).to eq staff_class
          end

          it "should redirect" do
            expect(response).to have_http_status(:redirect)
          end

          it "should get an notice" do
            expect(flash[:notice]).to eq 'Role removed successfully'
          end

          it "should update broker_staff_role aasm_state to broker_agency_terminated" do
            broker_agency_staff_role2.reload
            expect(broker_agency_staff_role2.aasm_state).to eq "broker_agency_terminated"
          end
        end
      end

      # permissions for broker agency access waiver and are frequently subject to change
      # specs built out for both kinds of hbx_staff_role in case of (another) permissions update
      context 'with insufficient permissions' do
        let!(:permission)           { FactoryBot.create(:permission, :hbx_read_only) }

        before do
          user_with_hbx_staff_role.person.build_hbx_staff_role(hbx_profile_id: organization_with_hbx_profile.hbx_profile.id, permission_id: permission.id)
          user_with_hbx_staff_role.person.hbx_staff_role.save!

          sign_in user_with_hbx_staff_role
        end

        context "GET new" do
          before do
            allow(controller).to receive(:set_ie_flash_by_announcement).and_return true
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
              :id => bap_id, :person_id => new_person_for_staff2.id, :profile_id => bap_id
            }
          end

          before :each do
            broker_agency_staff_role2.update_attributes(aasm_state: 'broker_agency_pending')
            get :approve, params: staff_params
          end

          it "should initialize staff" do
            expect(assigns(:staff).class).to eq staff_class
          end

          it "should redirect" do
            expect(response).to have_http_status(:redirect)
          end

          it "should get a notice" do
            expect(flash[:notice]).to eq 'Role approved successfully'
          end

          it "should update broker_agency_staff_role2 aasm_state to active" do
            broker_agency_staff_role2.reload
            expect(broker_agency_staff_role2.aasm_state).to eq "active"
          end
        end

        context 'DELETE destroy' do
          let!(:staff_params) do
            {
              :id => bap_id, :person_id => new_person_for_staff2.id, :profile_id => bap_id
            }
          end

          before :each do
            broker_agency_staff_role2.update_attributes(aasm_state: 'active')
            delete :destroy, params: staff_params
          end

          it "should initialize staff" do
            expect(assigns(:staff).class).to eq staff_class
          end

          it "should redirect" do
            expect(response).to have_http_status(:redirect)
          end

          it "should get an notice" do
            expect(flash[:notice]).to eq 'Role removed successfully'
          end

          it "should update broker_staff_role aasm_state to broker_agency_terminated" do
            broker_agency_staff_role2.reload
            expect(broker_agency_staff_role2.aasm_state).to eq "broker_agency_terminated"
          end
        end
      end
    end
  end
end
