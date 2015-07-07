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
      xhr :get, 'check_qle_date', :date_val => (TimeKeeper.date_of_record - 10.days).strftime("%m/%d/%Y"), :qle_type => "I've married", :format => 'js'
      expect(response).to have_http_status(:success)
    end

    describe "with valid params" do
      it "returns qualified_date as true" do
        xhr :get, 'check_qle_date', :date_val => (TimeKeeper.date_of_record - 10.days).strftime("%m/%d/%Y"), :qle_type => "I've married", :format => 'js'
        expect(response).to have_http_status(:success)
        expect(assigns['qualified_date']).to eq(true)
      end
    end

    describe "with invalid params" do

      context "I've married" do
      it "returns qualified_date as false for invalid future date" do
        xhr :get, 'check_qle_date', {:date_val => (TimeKeeper.date_of_record + 31.days).strftime("%m/%d/%Y"), :qle_type => "I've married", :format => 'js'}
        expect(assigns['qualified_date']).to eq(false)
      end

      it "returns qualified_date as false for invalid past date" do
        xhr :get, 'check_qle_date', {:date_val => (TimeKeeper.date_of_record - 31.days).strftime("%m/%d/%Y"), :qle_type => "I've married", :format => 'js'}
        expect(assigns['qualified_date']).to eq(false)
      end
      end

      context "Death" do
        it "returns qualified_date as false for invalid future date" do
          xhr :get, 'check_qle_date', {:date_val => (TimeKeeper.date_of_record + 1.days).strftime("%m/%d/%Y"), :qle_type => "Death", :format => 'js'}
          expect(assigns['qualified_date']).to eq(false)
        end

        it "returns qualified_date as false for invalid past date" do
          xhr :get, 'check_qle_date', {:date_val => (TimeKeeper.date_of_record - 31.days).strftime("%m/%d/%Y"), :qle_type => "Death", :format => 'js'}
          expect(assigns['qualified_date']).to eq(false)
        end
      end
    end
  end
end