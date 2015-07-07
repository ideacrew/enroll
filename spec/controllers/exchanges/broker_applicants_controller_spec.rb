require 'rails_helper'

RSpec.describe Exchanges::BrokerApplicantsController do

  describe ".index" do
    let(:user) { instance_double("User", :has_hbx_staff_role? => true) }

    before :each do
      sign_in(user)
      xhr :get, :index, format: :js
    end

    it "should render index" do
      expect(assigns(:broker_applicants))
      expect(response).to have_http_status(:success)
      expect(response).to render_template("exchanges/broker_applicants/index")
    end

    context 'when hbx staff role missing' do
      let(:user) { instance_double("User", :has_hbx_staff_role? => false) }

      it 'should redirect when hbx staff role missing' do 
        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to('/exchanges/hbx_profiles')
      end
    end
  end

  describe ".edit" do
    let(:user) { instance_double("User", :has_hbx_staff_role? => true) }
    let(:broker_role) {FactoryGirl.create(:broker_role)}

    before :each do
      sign_in(user)
      xhr :get, :edit, id: broker_role.person.id, format: :js
    end

    it "should render edit" do
      expect(assigns(:broker_applicant))
      expect(response).to have_http_status(:success)
      expect(response).to render_template("exchanges/broker_applicants/edit")
    end
  end
end