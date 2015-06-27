require 'rails_helper'

RSpec.describe ConsumerProfilesController do
  let(:user) { instance_double("User", :primary_family => family, :person => person) }
  let(:family) { double }
  let(:person) { double(:employee_roles => []) }
  let(:employee_role_id) { "2343" }

  describe "GET check_qle_date" do

    before(:each) do
      sign_in(user)
    end

    it "renders the 'check_qle_date' template" do
      xhr :get, 'check_qle_date', :date_val => "06/06/2015", :qle_type => "I've married", :format => 'js'
      expect(response).to have_http_status(:success)
    end

    describe "with valid params" do
      it "returns qualified_date as true" do
        xhr :get, 'check_qle_date', :date_val => "06/06/2015", :qle_type => "I've married", :format => 'js'
        expect(response).to have_http_status(:success)
        expect(assigns['qualified_date']).to eq(true)
      end
    end

    describe "with invalid params" do
      it "returns qualified_date as false" do
        xhr :get, 'check_qle_date', {:date_val => "06/06/2016", :qle_type => "I've married", :format => 'js'}
        expect(assigns['qualified_date']).to eq(false)
      end
    end
  end
end