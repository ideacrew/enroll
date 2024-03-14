# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Exchanges::AgentsController do
  render_views
  let(:person_user) { FactoryBot.create(:person, user: current_user)}
  let(:current_user){FactoryBot.create(:user)}
  describe 'Agent Controller behavior' do
    let(:signed_in?){ true }
    before :each do
      allow(current_user).to receive(:person).and_return(person_user)
      allow(current_user).to receive(:roles).and_return ['csr']
    end
    context '#home' do
      context 'csr role' do
        it 'renders home for CAC' do
          person_user.csr_role = FactoryBot.build(:csr_role, cac: true)
          sign_in current_user
          get :home
          expect(response).to have_http_status(:success)
          expect(response).to render_template("exchanges/agents/home")
          expect(response.body).to match(/Certified Applicant Counselor/)
        end

        it 'renders home for CSR' do
          person_user.csr_role = FactoryBot.build(:csr_role, cac: false)
          sign_in current_user
          get :home
          expect(response).to have_http_status(:success)
          expect(response).to render_template("exchanges/agents/home")
        end
      end

      context 'assister role' do
        it 'renders home for assister' do
          person_user.assister_role = FactoryBot.build(:assister_role)
          sign_in current_user
          get :home
          expect(response).to have_http_status(:success)
          expect(response).to render_template("exchanges/agents/home")
        end
      end

      it 'not render home for non CSR or non assister' do
        get :home
        expect(response).not_to have_http_status(:success)
        expect(response).not_to render_template("exchanges/agents/home")
      end
    end

    context '#inbox' do
      before :each do
        person_user.inbox = Inbox.new
      end
      context 'csr role' do
        it 'renders inbox for CSR' do
          person_user.csr_role = FactoryBot.build(:csr_role, cac: false)
          sign_in current_user
          get :inbox, params: {id: person_user.id}, format: :js
          expect(response).to have_http_status(:success)
        end
      end

      context 'assister role' do
        it 'renders inbox for assister' do
          person_user.assister_role = FactoryBot.build(:assister_role)
          sign_in current_user
          get :inbox, params: {id: person_user.id}, format: :js
          expect(response).to have_http_status(:success)
        end
      end

      it 'not render inbox for non CSR or non assister' do
        get :inbox, params: {id: person_user.id}, format: :js
        expect(response).not_to have_http_status(:success)
      end
    end

    it 'begins enrollment' do
      sign_in current_user
      get :begin_employee_enrollment
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "resume enrollment method behavior", dbclean: :after_each do
    let!(:individual_market_transition) { FactoryBot.create(:individual_market_transition, :person => person_user)}
    let!(:consumer_role) { FactoryBot.create(:consumer_role, bookmark_url: nil, person: person_user) }

    before(:each) do
      allow(current_user).to receive(:roles).and_return ['consumer']
      controller.class.skip_before_action :check_agent_role, raise: false
    end
    context "actions when not passed Ridp" do
      it 'should redirect to family account path' do
        sign_in current_user
        get :resume_enrollment, params: {person_id: person_user.id}
        expect(response).to redirect_to family_account_path
      end

      it 'should redirect to consumer role bookmark url' do
        consumer_role.update_attributes(bookmark_url: '/')
        sign_in current_user
        get :resume_enrollment, params: {person_id: person_user.id}
        expect(response).to redirect_to person_user.consumer_role.bookmark_url
      end
    end

    context "when admin submitted paper application" do

      before do
        consumer_role.update_attributes(bookmark_url: '/')
        sign_in current_user
      end

      it "should not redirect to family account path if not paper application" do
        get :resume_enrollment,params: {person_id: person_user.id, original_application_type: "not_paper"}
        expect(response).not_to redirect_to family_account_path
      end

      it "should redirect to family account path if admin submitted paper application" do
        get :resume_enrollment, params: {person_id: person_user.id, original_application_type: "paper"}
        expect(response).to redirect_to family_account_path
      end
    end
  end
end
