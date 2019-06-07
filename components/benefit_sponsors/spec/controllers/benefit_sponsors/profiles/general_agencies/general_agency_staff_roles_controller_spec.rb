require 'rails_helper'

module BenefitSponsors
  RSpec.describe Profiles::GeneralAgencies::GeneralAgencyStaffRolesController, type: :controller, dbclean: :after_each do

    routes { BenefitSponsors::Engine.routes }

    let!(:site)                          { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
    let(:organization_with_hbx_profile)  { site.owner_organization }
    let!(:organization)                  { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_general_agency_profile, site: site) }
    let!(:general_agency_profile1) { organization.general_agency_profile }

    let!(:second_organization)                  { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_general_agency_profile, site: site) }
    let!(:second_general_agency_profile) { second_organization.general_agency_profile }

    let(:gap_id) { organization.general_agency_profile.id }
    let(:user) { FactoryBot.create(:user)}
    let!(:new_person_for_staff) { FactoryBot.create(:person) }
    let!(:new_person_for_staff1) { FactoryBot.create(:person, user: user) }
    let!(:general_agency_staff_role) { FactoryBot.create(:general_agency_staff_role, benefit_sponsors_general_agency_profile_id: gap_id, person: new_person_for_staff1) }
    let!(:general_agency_staff_role1) { FactoryBot.create(:general_agency_staff_role, benefit_sponsors_general_agency_profile_id: gap_id, person: new_person_for_staff) }

    let(:staff_class) { BenefitSponsors::Organizations::OrganizationForms::StaffRoleForm }

    describe "GET new" do

      before do
        get :new, params: { profile_type: "general_agency_staff" }
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

    describe "POST create", dbclean: :after_each do

      context "creating staff role with existing person params" do

        let!(:staff_params) do
          {
            profile_type: "general_agency_staff",
            general_agency_registration_page: "true",
            :staff => {:first_name => new_person_for_staff.first_name, :last_name => new_person_for_staff.last_name, :dob => new_person_for_staff.dob, email: "hello@hello.com",  :profile_id => gap_id}
          }
        end

        before :each do
          post :create, params: staff_params, format: :js, xhr: true
        end

        it "should initialize staff" do
          expect(assigns(:staff).class).to eq staff_class
        end

        it "should render js template" do
          expect(response.content_type).to eq Mime[:js]
        end

        it "should be a success" do
          expect(response).to have_http_status(:success)
        end

        it 'should get javascript content' do
          expect(response.headers['Content-Type']).to eq 'text/javascript; charset=utf-8'
        end
      end

      context 'person is already assigned as a staff to general agency' do

        let!(:staff_params) do
          {
            profile_type: 'general_agency_staff',
            general_registration_page: 'true',
            :staff => {:first_name => new_person_for_staff1.first_name, :last_name => new_person_for_staff1.last_name, :dob => new_person_for_staff1.dob, email: "hello@hello.com",  :profile_id => gap_id}
          }
        end

        before :each do
          post :create, params: staff_params, format: :js, xhr: true
        end

        it 'should render js template' do
          expect(response.content_type).to eq Mime[:js]
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
            :staff => {:first_name => "hello", :last_name => "world", :dob => "10/10/1998", email: "hello@hello.com",  :profile_id => gap_id}
          }
        end

        before :each do
          post :create, params: staff_params, format: :js, xhr: true
        end

        it 'should render js template' do
          expect(response.content_type).to eq Mime[:js]
        end

        it 'should get javascript content' do
          expect(response.headers['Content-Type']).to eq 'text/javascript; charset=utf-8'
        end
      end
    end

    describe "GET search_general_agency" do

      before do
        general_agency_staff_role.update_attributes!(is_primary: true)
        general_agency_profile1.approve!
        organization.reload
        get :search_general_agency, params: params, format: :js, xhr: true
      end

      context "return result if general agency is present" do

        let!(:params) do
          {
            q: general_agency_profile1.legal_name,
            general_agency_registration_page: "true"
          }
        end

        it 'should be a success' do
          expect(response).to have_http_status(:success)
        end

        it 'should render the new template' do
          expect(response).to render_template('search_general_agency')
        end

        it 'should assign general_agency_profiles variable' do
          expect(assigns(:general_agency_profiles)).to include(general_agency_profile1)
        end
      end

      context "should not return result" do

        let!(:params) do
          {
            q: "hello world",
            general_agency_registration_page: "true"
          }
        end

        it 'should be a success' do
          expect(response).to have_http_status(:success)
        end

        it 'should render the new template' do
          expect(response).to render_template('search_general_agency')
        end

        it 'should assign general_agency_profiles variable' do
          expect(assigns(:general_agency_profiles)).not_to include(general_agency_profile1)
        end
      end
    end

  end
end
