require 'rails_helper'

RSpec.describe Employers::BrokerAgencyController do

  describe ".active_broker" do
    
    before(:all) do
      @employer_profile = FactoryGirl.create(:employer_profile)

      @broker_role =  FactoryGirl.create(:broker_role, aasm_state: 'active')
      @org1 = FactoryGirl.create(:organization, legal_name: "Singhal")
      @org1.broker_agency_profile.update_attributes(primary_broker_role: @broker_role)
      @broker_role.update_attributes(broker_agency_profile_id: @org1.broker_agency_profile.id)

      @broker_role2 = FactoryGirl.create(:broker_role, aasm_state: 'active')
      @org2 = FactoryGirl.create(:organization, legal_name: "Kaiser")
      @org2.broker_agency_profile.update_attributes(primary_broker_role: @broker_role2)
      @broker_role2.update_attributes(broker_agency_profile_id: @org2.broker_agency_profile.id)

      @user = FactoryGirl.create(:user)
    end

    context 'with out search string' do
      before(:each) do
        sign_in(@user)
        xhr :get, :active_broker, employer_profile_id: @employer_profile.id, format: :js
      end

      it "should be a success" do
        expect(response).to have_http_status(:success)
      end

      it "should render the new template" do
        expect(response).to render_template("active_broker")
      end

      it "should assign variables" do
        expect(assigns(:broker_agency_profiles).count).to eq 2
        expect(assigns(:broker_agency_profiles)).to include(@org1.broker_agency_profile)
        expect(assigns(:broker_agency_accounts)).to eq([])
      end
    end

    context 'with search string' do
      before :each do
        sign_in(@user)
        xhr :get, :active_broker, employer_profile_id: @employer_profile.id, q: @org1.broker_agency_profile.legal_name, format: :js
      end

      it 'should return matching agency' do
        expect(assigns(:broker_agency_profiles)).to eq([@org1.broker_agency_profile])
      end
    end
  end
end