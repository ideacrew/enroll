require 'rails_helper'

RSpec.describe Employers::BrokerAgencyController do

  before(:all) do
    @employer_profile = FactoryBot.create(:employer_profile)

    @broker_role =  FactoryBot.create(:broker_role, aasm_state: 'active')
    @org1 = FactoryBot.create(:broker_agency, legal_name: "agencyone")
    @org1.broker_agency_profile.update_attributes(primary_broker_role: @broker_role)
    @broker_role.update_attributes(broker_agency_profile_id: @org1.broker_agency_profile.id)
    @org1.broker_agency_profile.approve!

    @broker_role2 = FactoryBot.create(:broker_role, aasm_state: 'active')
    @org2 = FactoryBot.create(:broker_agency, legal_name: "agencytwo")
    @org2.broker_agency_profile.update_attributes(primary_broker_role: @broker_role2)
    @broker_role2.update_attributes(broker_agency_profile_id: @org2.broker_agency_profile.id)
    @org2.broker_agency_profile.approve!

    @user = FactoryBot.create(:user)
    p=FactoryBot.create(:person, user: @user)
    @hbx_staff_role = FactoryBot.create(:hbx_staff_role, person: p)
  end

  after :all do
    DatabaseCleaner.clean
  end

  describe ".index" do

    before do
      Person.create_indexes
    end

    it "should render js template" do
      sign_in(@user)
      get :index, params: {employer_profile_id: @employer_profile.id, q: @org2.broker_agency_profile.legal_name}, xhr: true
      expect(response.content_type).to eq "text/javascript"
    end

    context 'with out search string' do
      before(:each) do
        sign_in(@user)
        get :index, params: {employer_profile_id: @employer_profile.id}, format: :js, xhr: true
      end

      it "should be a success" do
        expect(response).to have_http_status(:success)
      end

      it "should render the new template" do
        expect(response).to render_template("index")
      end

      it "should assign variables" do
        expect(assigns(:broker_agency_profiles).count).to eq 2
        expect(assigns(:broker_agency_profiles)).to include(@org1.broker_agency_profile)
      end
    end

    context 'with search string' do
      before :each do
        sign_in(@user)
        get :index, params: {employer_profile_id: @employer_profile.id, q: @org2.broker_agency_profile.legal_name}, format: :js, xhr: true
      end

      it 'should return matching agency' do
        expect(assigns(:broker_agency_profiles)).to eq([@org2.broker_agency_profile])
      end
    end

    context 'with search string and pagination' do
      before :each do
        sign_in(@user)
        get :index, params: {employer_profile_id: @employer_profile.id, q: @org2.broker_agency_profile.legal_name, organization_page: 1}, format: :js, xhr: true
      end

      it 'should return matching agency' do
        expect(assigns(:broker_agency_profiles)).to eq([@org2.broker_agency_profile])
      end
    end

    context 'with page label and pagination' do
      before :each do
        sign_in(@user)
        get :index, params: {employer_profile_id: @employer_profile.id, page: @org2.broker_agency_profile.legal_name[0].upcase, organization_page: 1}, format: :js, xhr: true
      end

      it 'should return matching agency' do
        expect(assigns(:broker_agency_profiles).count).to eq 2
        expect(assigns(:broker_agency_profiles)).to eq([@org1.broker_agency_profile,@org2.broker_agency_profile])
      end
    end

    context 'with page label and invalid pagination number' do
      before :each do
        sign_in(@user)
        get :index, params: {employer_profile_id: @employer_profile.id, page: @org2.broker_agency_profile.legal_name[0].upcase, organization_page: 120}, format: :js, xhr: true
      end
      it 'should return matching agency' do
        expect(assigns(:broker_agency_profiles).count).to eq 0
        expect(assigns(:broker_agency_profiles)).to eq([])
      end
    end

  end

  describe ".create" do

    context 'with out search string - with modify_employer permission' do
      before(:each) do
        allow(@hbx_staff_role).to receive(:permission).and_return(double('Permission', modify_employer: true))
        allow(SponsoredBenefits::Organizations::BrokerAgencyProfile).to receive(:assign_employer).and_return(true)
        sign_in(@user)
        post :create, params: {employer_profile_id: @employer_profile.id, broker_role_id: @broker_role2.id, broker_agency_id: @org2.broker_agency_profile.id}
      end

      it "should be a success" do
        expect(flash[:notice]).to eq("Your broker has been notified of your selection and should contact you shortly. You can always call or email them directly. If this is not the broker you want to use, select 'Change Broker'.")
        expect(response).to redirect_to(employers_employer_profile_path(@employer_profile, tab:'brokers'))
      end
    end

    context 'post create' do
      before(:each) do
        allow(@hbx_staff_role).to receive(:permission).and_return(double('Permission', modify_employer: true))
        sign_in(@user)
      end
    end


    context 'with out search string - WITHOUT modify_employer permission' do
      before(:each) do
        allow(@hbx_staff_role).to receive(:permission).and_return(double('Permission', modify_employer: false))
        sign_in(@user)
        post :create, params: {employer_profile_id: @employer_profile.id, broker_role_id: @broker_role2.id, broker_agency_id: @org2.broker_agency_profile.id}
      end

      it "should be a success" do
        expect(flash[:error]).to match(/Access not allowed/)
      end
    end

  end

  describe ".active_broker" do

    context 'with out search string' do
      before(:each) do
        sign_in(@user)
        get :active_broker, params: {employer_profile_id: @employer_profile.id}, format: :js, xhr: true
      end

      it "should be a success" do
        expect(response).to have_http_status(:success)
      end

      it "should render the new template" do
        expect(response).to render_template("active_broker")
      end

      it "should assign employer broker accounts" do
        expect(assigns(:broker_agency_account).broker_agency_profile).to eq(@org2.broker_agency_profile)
      end
    end
  end

  describe ".terminate" do

    context 'with out search string' do
      before(:each) do
        allow(@hbx_staff_role).to receive(:permission).and_return(double('Permission', modify_employer: true))
        sign_in(@user)
        get :terminate, params: {employer_profile_id: @employer_profile.id, broker_agency_id: @org2.broker_agency_profile.id}
      end

      it "should be a success" do
        expect(flash[:notice]).to eq("Broker terminated successfully.")
        expect(response).to redirect_to(employers_employer_profile_path(@employer_profile))
        expect(@employer_profile.broker_agency_accounts).to eq([])
      end
    end

    context 'when direct terminate' do
      before(:each) do
        allow(@hbx_staff_role).to receive_message_chain('permission.modify_employer').and_return(true)
        sign_in(@user)
      end

      it "should terminate broker and redirect to my_account with broker tab actived" do
        get :terminate, params: {employer_profile_id: @employer_profile.id, broker_agency_id: @org2.broker_agency_profile.id, direct_terminate: true, termination_date: TimeKeeper.date_of_record}
        expect(flash[:notice]).to eq("Broker terminated successfully.")
        expect(response).to redirect_to(employers_employer_profile_path(@employer_profile, tab: "brokers"))
      end
    end

    context 'when hbx permission is modify_employer not allowed' do
      before(:each) do
        allow(@hbx_staff_role).to receive(:permission).and_return(double('Permission', modify_employer: false))
        sign_in(@user)
      end

      it "should terminate broker and redirect to my_account with broker tab actived" do
        get :terminate, params: {employer_profile_id: @employer_profile.id, broker_agency_id: @org2.broker_agency_profile.id, direct_terminate: true, termination_date: TimeKeeper.date_of_record}

        expect(flash[:error]).to match(/Access not allowed/)

      end
    end
  end

  describe ".create for invalid plan year" do
    let(:general_agency_profile) { FactoryBot.create(:general_agency_profile) }
    before (:each) do
          allow(@hbx_staff_role).to receive_message_chain('permission.modify_employer').and_return(true)
          allow(SponsoredBenefits::Organizations::BrokerAgencyProfile).to receive(:assign_employer).and_return(true)
          sign_in(@user)
          @employer_profile.plan_years=[]
          invalid_plan=FactoryBot.build(:plan_year, open_enrollment_end_on: Date.today)
          @employer_profile.plan_years << invalid_plan
          @employer_profile.save!(validate:false)
    end

    it "should be a success" do
      post :create, params: {employer_profile_id: @employer_profile.id, broker_role_id: @broker_role2.id, broker_agency_id: @org2.broker_agency_profile.id}
      expect(assigns(:employer_profile).broker_role_id).to eq(@broker_role2.id.to_s)
    end

    it "should call send_general_agency_assign_msg" do
      @org2.broker_agency_profile.default_general_agency_profile = general_agency_profile
      @org2.broker_agency_profile.save
      expect(controller).to receive(:send_general_agency_assign_msg)
      post :create, params: {employer_profile_id: @employer_profile.id, broker_role_id: @broker_role2.id, broker_agency_id: @org2.broker_agency_profile.id}
    end

    context "send_broker_assigned_msg" do

      before do
        @controller.send(:send_broker_assigned_msg, @employer_profile, @org2.broker_agency_profile)
      end

      it "adds a message to person inbox" do
        expect(@employer_profile.inbox.messages.count).to eq (2)
      end
    end
  end
end
