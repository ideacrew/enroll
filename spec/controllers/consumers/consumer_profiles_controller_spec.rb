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
          xhr :get, 'check_qle_date', {:date_val => (TimeKeeper.date_of_record - 61.days).strftime("%m/%d/%Y"), :qle_type => "I've married", :format => 'js'}
          expect(assigns['qualified_date']).to eq(false)
        end
      end
    end

    context "GET check_qle_date" do
      context "normal qle event" do
        it "should return true" do
          date = TimeKeeper.date_of_record.strftime("%m/%d/%Y")
          xhr :get, :check_qle_date, date_val: date, qle_type: "normal qle event", format: :js
          expect(response).to have_http_status(:success)
          expect(assigns(:qualified_date)).to eq true
        end

        it "should return false" do
          sign_in user
          date = (TimeKeeper.date_of_record + 40.days).strftime("%m/%d/%Y")
          xhr :get, :check_qle_date, date_val: date, qle_type: "normal qle event", format: :js
          expect(response).to have_http_status(:success)
          expect(assigns(:qualified_date)).to eq false
        end
      end

      context "special qle events which can not have future date" do
        it "should return true" do
          sign_in user
          date = TimeKeeper.date_of_record.strftime("%m/%d/%Y")
          ["I've had a baby", "A family member has died", "I've married"].each do |qle_type|
            xhr :get, :check_qle_date, date_val: date, qle_type: qle_type, format: :js
            expect(response).to have_http_status(:success)
            expect(assigns(:qualified_date)).to eq true
          end
        end

        it "should return false" do
          sign_in user
          date = (TimeKeeper.date_of_record + 4.days).strftime("%m/%d/%Y")
          ["I've had a baby", "A family member has died", "I've married"].each do |qle_type|
            xhr :get, :check_qle_date, date_val: date, qle_type: qle_type, format: :js
            expect(response).to have_http_status(:success)
            expect(assigns(:qualified_date)).to eq false
          end
        end
      end

      context "special qle events which can have 120 days" do
        it "should return true" do
          sign_in user
          date = (TimeKeeper.date_of_record + 32.days).strftime("%m/%d/%Y")
          ["Myself or a family member has lost other coverage", "Mid-month loss of mec", "My employer failed to pay premiums on time", "I've moved into the district of columbia"].each do |qle_type|
            xhr :get, :check_qle_date, date_val: date, qle_type: qle_type, format: :js
            expect(response).to have_http_status(:success)
            expect(assigns(:qualified_date)).to eq true
          end
        end

        it "should return false" do
          sign_in user
          date = (TimeKeeper.date_of_record + 64.days).strftime("%m/%d/%Y")
          ["Myself or a family member has lost other coverage", "Mid-month loss of mec", "My employer failed to pay premiums on time", "I've moved into the district of columbia"].each do |qle_type|
            xhr :get, :check_qle_date, date_val: date, qle_type: qle_type, format: :js
            expect(response).to have_http_status(:success)
            expect(assigns(:qualified_date)).to eq false
          end
        end
      end
    end
  end
end
