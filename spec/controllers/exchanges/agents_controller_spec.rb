require 'rails_helper'

RSpec.describe Exchanges::AgentsController do
  describe 'Agent Controller behavior' do
    render_views
    let(:person_user){Person.new(first_name: 'fred', last_name: 'flintstone')}
    let(:current_user){FactoryGirl.create(:user)}
    let(:signed_in?){ true }
   
     before :each do
       allow(current_user).to receive(:person).and_return(person_user)
     end

    it 'renders home for CAC' do
      current_user.roles=['csr']
      current_user.person = person_user
      person_user.csr_role = FactoryGirl.build(:csr_role, cac: true)
      sign_in current_user
      get :home
      expect(response).to have_http_status(:success)
      expect(response).to render_template("exchanges/agents/home")
      expect(response.body).to match(/Certified Applicant Counselor/)
    end

    it 'renders home for CSR' do
      current_user.roles=['csr']
      current_user.person = person_user
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
end
