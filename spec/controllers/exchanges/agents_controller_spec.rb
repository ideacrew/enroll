require 'rails_helper'

RSpec.describe Exchanges::AgentsController do
  render_views
  let(:person_user) { FactoryGirl.create(:person, user: current_user)}
  let(:current_user){FactoryGirl.create(:user)}
  describe 'Agent Controller behavior' do
    let(:signed_in?){ true }
     before :each do
       allow(current_user).to receive(:person).and_return(person_user)
       allow(current_user).to receive(:roles).and_return ['csr']
     end

    it 'renders home for CAC' do
      person_user.csr_role = FactoryGirl.build(:csr_role, cac: true)
      sign_in current_user
      get :home
      expect(response).to have_http_status(:success)
      expect(response).to render_template("exchanges/agents/home")
      expect(response.body).to match(/Certified Applicant Counselor/)
    end

    it 'renders home for CSR' do
      person_user.csr_role = FactoryGirl.build(:csr_role, cac: false)
      sign_in current_user
      get :home
      expect(response).to have_http_status(:success)
      expect(response).to render_template("exchanges/agents/home")
    end
    
    it 'begins enrollment' do
      sign_in current_user
      get :begin_employee_enrollment
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "resume enrollment method behavior", dbclean: :after_each do
    let!(:consumer_role) { FactoryGirl.create(:consumer_role, bookmark_url: nil, person: person_user) }

    before(:each) do
      allow(current_user).to receive(:roles).and_return ['consumer']
      controller.class.skip_before_filter :check_agent_role
    end
    context "actions when not passed Ridp" do
      it 'should redirect to family account path' do
        sign_in current_user
        get :resume_enrollment, person_id: person_user.id
        expect(response).to redirect_to family_account_path
      end

      it 'should redirect to consumer role bookmark url' do
        consumer_role.update_attributes(bookmark_url: '/')
        sign_in current_user
        get :resume_enrollment, person_id: person_user.id
        expect(response).to redirect_to person_user.consumer_role.bookmark_url
      end
    end


    context "When passed RIDP and having enrollment" do
      let!(:family) { FactoryGirl.create(:family, :with_primary_family_member, person: person_user) }
      let(:household) { FactoryGirl.create(:household, family: person_user.primary_family) }
      let(:enrollment) { FactoryGirl.create(:hbx_enrollment, household: person_user.primary_family.latest_household, kind: "individual", is_active: true)}

      before do
        allow(household).to receive(:hbx_enrollments).with(:first).and_return enrollment
        current_user.update_attributes(idp_verified: true, identity_final_decision_code: "acc")
        consumer_role.update_attributes(bookmark_url: '/')
      end
      it 'should redirect to consumer role bookmark url' do
        sign_in current_user
        get :resume_enrollment, person_id: person_user.id
        person_user.reload
        expect(person_user.consumer_role.bookmark_url).to eq '/families/home'
        expect(response).to redirect_to '/families/home'
      end
    end
  end
end
