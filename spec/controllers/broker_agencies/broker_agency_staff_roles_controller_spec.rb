require 'rails_helper'

RSpec.describe BrokerAgencies::BrokerAgencyStaffRolesController do

  let!(:user) {FactoryGirl.create(:user, person: person)}
  let!(:person) {FactoryGirl.create(:person, first_name: 'hello', last_name: 'world', dob: Date.new(1988,3,10))}
  let!(:new_person) {FactoryGirl.create(:person, first_name: 'new', last_name: 'person', dob: Date.new(1988,3,10))}
  let!(:broker_agency_profile) {FactoryGirl.create(:broker_agency_profile)}
  let!(:broker_agency_staff_role) {FactoryGirl.build(:broker_agency_staff_role, broker_agency_profile_id: broker_agency_profile.id )}

  before :all do
    DatabaseCleaner.clean
  end

  describe 'GET new', dbclean: :after_each do
    let(:params) { {id: broker_agency_profile.id}}
    before do
      person.broker_agency_staff_roles << broker_agency_staff_role
      sign_in user
      xhr :get, :new, params, format: :js
    end


    it 'should render new template' do
      expect(response).to render_template('new')
    end

    it 'should return http success' do
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST create', dbclean: :after_each do

    context 'Person exists on an exchange' do
      let(:params) { {id: broker_agency_profile.id, email: 'hello@gmail.com',  :person => {first_name: new_person.first_name, last_name: new_person.last_name, dob: new_person.dob} }}

      before do
        person.broker_agency_staff_roles << broker_agency_staff_role
        sign_in user
        post :create, params
      end

      it 'should successfully add broker agency staff role in active state' do
        new_person.reload
        expect(new_person.broker_agency_staff_roles.count). to eq 1
        expect(new_person.broker_agency_staff_roles[0].aasm_state). to eq 'active'
      end

      it 'should render a flash success message' do
        expect(flash[:notice]).to eq 'Role added successfully'
      end

      it 'should redirect to profiles page' do
        expect(response).to redirect_to(broker_agencies_profile_path(id: broker_agency_profile.id))
      end
    end

    context 'Person does not exist on an exchange' do
      let(:params) { {id: broker_agency_profile.id, email: 'hello@gmail.com',  :person => {first_name: Forgery('name').first_name, last_name: Forgery('name').last_name, dob: Date.new(1988,3,10)} }}

      before do
        person.broker_agency_staff_roles << broker_agency_staff_role
        sign_in user
        post :create, params
      end

      it 'should render a flash error message' do
        expect(flash[:error]).to eq 'Role was not added because Person does not exist on the Exchange'
      end

      it 'should redirect to profiles page' do
        expect(response).to redirect_to(broker_agencies_profile_path(id: broker_agency_profile.id))
      end
    end

    context 'Multiple people with first name last name and dob exists on an exchange' do
      before(:each) do
        2.times { FactoryGirl.create(:person, first_name: 'john', last_name: 'smith', dob: Date.new(1988,3,10)) }
      end
      let(:params) { {id: broker_agency_profile.id, email: 'hello@gmail.com',  :person => {first_name: 'john', last_name: 'smith', dob: Date.new(1988,3,10)} }}

      before do
        person.broker_agency_staff_roles << broker_agency_staff_role
        sign_in user
        post :create, params
      end

      it 'should render a flash error message' do
        expect(flash[:error]).to eq 'Role was not added because Person count too high, please contact HBX Admin'
      end

      it 'should redirect to profiles page' do
        expect(response).to redirect_to(broker_agencies_profile_path(id: broker_agency_profile.id))
      end
    end

    context 'person with staff role already assigned to broker agency on an exchange' do
      let!(:person) {FactoryGirl.create(:person, first_name: 'hello')}
      let!(:broker_agency_staff_role) {FactoryGirl.build(:broker_agency_staff_role, broker_agency_profile_id: broker_agency_profile.id, aasm_state: 'active')}
      let!(:params) { {id: broker_agency_profile.id, email: 'hello@gmail.com',  :person => {first_name: person.first_name, last_name: person.last_name, dob: person.dob} }}

      before do
        sign_in user
      end

      it 'should not add broker agency staff role in active state' do
        person.broker_agency_staff_roles << broker_agency_staff_role
        post :create, params
        person.reload
        expect(person.broker_agency_staff_roles.count). to eq 1
      end

      it 'should render a flash error message' do
        person.broker_agency_staff_roles << broker_agency_staff_role
        post :create, params
        expect(flash[:error]).to eq 'Role was not added because Person already has a staff role for this broker agency'
      end

      it 'should redirect to profiles page' do
        person.broker_agency_staff_roles << broker_agency_staff_role
        post :create, params
        expect(response).to redirect_to(broker_agencies_profile_path(id: broker_agency_profile.id))
      end
    end

  end

  describe '.approve', dbclean: :after_each do
    let!(:person) {FactoryGirl.create(:person, first_name: 'hello')}
    let!(:broker_agency_staff_role) {FactoryGirl.build(:broker_agency_staff_role, broker_agency_profile_id: broker_agency_profile.id, aasm_state: 'broker_agency_pending')}
    let!(:params) { {id: broker_agency_profile.id, staff_id: person.id}}

    before do
      sign_in user
    end

    context 'broker staff in pending state' do
      it 'should approve broker agency staff role in pending state' do
        person.broker_agency_staff_roles << broker_agency_staff_role
        expect(person.broker_agency_staff_roles[0].aasm_state). to eq 'broker_agency_pending'
        post :approve, params
        person.reload
        expect(person.broker_agency_staff_roles[0].aasm_state). to eq 'active'
      end

      it 'should render a flash success message' do
        person.broker_agency_staff_roles << broker_agency_staff_role
        post :approve, params
        expect(flash[:success]).to eq 'Role is approved'
      end

      it 'should redirect to profiles page' do
        person.broker_agency_staff_roles << broker_agency_staff_role
        post :approve, params
        expect(response).to redirect_to(broker_agencies_profile_path(id: broker_agency_profile.id))
      end
    end

    context 'broker staff in active state' do

      before do
        broker_agency_staff_role.update_attributes(aasm_state: 'active')
      end

      it 'should approve broker agency staff role in pending state' do
        person.broker_agency_staff_roles << broker_agency_staff_role
        expect(person.broker_agency_staff_roles[0].aasm_state). to eq 'active'
        post :approve, params
        person.reload
        expect(person.broker_agency_staff_roles[0].aasm_state). to eq 'active'
      end

      it 'should render a flash success message' do
        person.broker_agency_staff_roles << broker_agency_staff_role
        post :approve, params
        expect(flash[:error]).to eq 'Please contact HBX Admin to report this error'
      end

      it 'should redirect to profiles page' do
        person.broker_agency_staff_roles << broker_agency_staff_role
        post :approve, params
        expect(response).to redirect_to(broker_agencies_profile_path(id: broker_agency_profile.id))
      end
    end
  end

  describe '.destroy', dbclean: :after_each do
    let!(:broker_agency_staff_role) {FactoryGirl.build(:broker_agency_staff_role, broker_agency_profile_id: broker_agency_profile.id, aasm_state: 'active')}
    let!(:params) { {id: broker_agency_profile.id, staff_id: person.id}}

    before do
      sign_in user
    end

    context 'only one broker staff present to broker agency' do

      before do
        person.broker_agency_staff_roles = []
        person.broker_agency_staff_roles << broker_agency_staff_role
      end

      it 'should not destroy broker staff' do
        expect(person.broker_agency_staff_roles[0].aasm_state). to eq 'active'
        delete :destroy, params
        person.reload
        expect(person.broker_agency_staff_roles[0].aasm_state). to eq 'active'
      end

      it 'should render a flash success message' do
        delete :destroy, params
        expect(flash[:error]).to eq 'Please add another staff role before deleting this role'
      end

      it 'should redirect to profiles page' do
        delete :destroy, params
        expect(response).to redirect_to(broker_agencies_profile_path(id: broker_agency_profile.id))
      end

    end

    context 'Multiple broker staff present to broker agency' do

      let!(:person2) {FactoryGirl.create(:person, first_name: 'person2')}

      before do
        person.broker_agency_staff_roles = []
        person2.broker_agency_staff_roles = []
        person.broker_agency_staff_roles << broker_agency_staff_role
        person2.broker_agency_staff_roles << broker_agency_staff_role
      end

      it 'should destroy broker staff' do
        expect(person.broker_agency_staff_roles[0].aasm_state). to eq 'active'
        expect(person2.broker_agency_staff_roles[0].aasm_state). to eq 'active'
        delete :destroy, params
        person.reload
        expect(person.broker_agency_staff_roles[0].aasm_state). to eq 'broker_agency_terminated'
        expect(person2.broker_agency_staff_roles[0].aasm_state). to eq 'active'
      end

      it 'should render a flash success message' do
        delete :destroy, params
        expect(flash[:notice]).to eq 'Staff role was deleted'
      end

      it 'should redirect to profiles page' do
        delete :destroy, params
        expect(response).to redirect_to(broker_agencies_profile_path(id: broker_agency_profile.id))
      end
    end

    context 'Trying to terminate already terminated broker staff' do

      before do
        broker_agency_staff_role.update_attributes(aasm_state: 'broker_agency_terminated')
        person.broker_agency_staff_roles = []
        person.broker_agency_staff_roles << broker_agency_staff_role
      end

      it 'should not destroy broker staff' do
        expect(person.broker_agency_staff_roles[0].aasm_state). to eq 'broker_agency_terminated'
        delete :destroy, params
        person.reload
        expect(person.broker_agency_staff_roles[0].aasm_state). to eq 'broker_agency_terminated'
      end

      it 'should render a flash success message' do
        delete :destroy, params
        expect(flash[:error]).to eq 'Role was not deactivated because No matching Broker Agency Staff role'
      end

      it 'should redirect to profiles page' do
        delete :destroy, params
        expect(response).to redirect_to(broker_agencies_profile_path(id: broker_agency_profile.id))
      end

    end

    context 'Person record does not exist in enroll' do

      let!(:params) { {id: broker_agency_profile.id, staff_id: '843567876345' }}

      it 'should render a flash success message' do
        person.broker_agency_staff_roles << broker_agency_staff_role
        delete :destroy, params
        expect(flash[:error]).to eq 'Role was not deactivated because Person not found'
      end
    end
  end

end