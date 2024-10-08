require 'rails_helper'

describe UsersController, dbclean: :after_each do
  let(:admin) { instance_double(User, person: staff_person) }
  let(:user) { instance_double(User, :email => user_email, :person => person) }
  let(:staff_person) { double('Person', hbx_staff_role: hbx_staff_role) }
  let(:person) { double('Person', hbx_staff_role: nil) }
  let(:hbx_staff_role) { double('HbxStaffRole', permission: permission)}
  let(:permission) { double('Permission')}
  let(:user_id) { "23432532423424" }
  let(:user_email) { "some_email@some_domain.com" }

  after :all do
    DatabaseCleaner.clean
  end

  before :each do
    allow(User).to receive(:find).with(user_id).and_return(user)
  end

  describe ".change_username_and_email" do
    let(:user) { build(:user, id: '1', oim_id: user_email, person: person) }
    before do
      allow(permission).to receive(:can_change_username_and_email).and_return(true)
    end

    context "An admin is allowed to access the change username action" do
      before do
        sign_in(admin)
      end
      it "renders the change username form" do
        get :change_username_and_email, params: { id: user_id, format: :js }
        expect(response).to render_template('change_username_and_email')
      end
    end

    context "An admin is not allowed to access the change username action" do
      before do
        allow(permission).to receive(:can_change_username_and_email).and_return(false)
        sign_in(admin)
      end
      it "doesn't render the change username form" do
        get :change_username_and_email, params: { id: user_id, format: :js }
        expect(flash[:error]).to be_present
        expect(flash[:error]).to include('Access not allowed for hbx_profile_policy.change_username_and_email?, (Pundit policy)')
      end
    end
  end

  describe ".confirm_change_username_and_email", dbclean: :after_each do
    let(:person) { FactoryBot.create(:person) }
    let(:user) { FactoryBot.create(:user, :person => person) }
    let(:hbx_staff_role) { FactoryBot.create(:hbx_staff_role, person: person)}
    let(:permission) { double('Permission')}
    let(:hbx_profile) { FactoryBot.create(:hbx_profile)}
    let(:invalid_username) { "ggg" }
    let(:valid_username) { "gariksubaric" }
    let(:invalid_email) { "email@" }
    let(:valid_email) { "email@email.com" }

    before do
      allow(hbx_staff_role).to receive(:permission).and_return permission
      allow(permission).to receive(:can_change_username_and_email).and_return(true)
      allow(user).to receive(:has_hbx_staff_role?).and_return(true)
      sign_in(user)
    end

    context "email format wrong" do
      it "doesn't update credentials" do
        params = {id: user_id, new_email: invalid_email, format: :js}
        put :confirm_change_username_and_email, params: params
        expect(response).to render_template('change_username_and_email')
      end
    end
    context "username format wrong" do
      it "doesn't update credentials" do
        params = {id: user_id, new_email: invalid_username, format: :js}
        put :confirm_change_username_and_email, params: params
        expect(response).to render_template('change_username_and_email')
      end
    end
    context "valid credentials format" do
      it "updates credentials" do
        params = {id: user_id, new_email: valid_email, new_oim_id: valid_username, format: :js}
        put :confirm_change_username_and_email, params: params
        expect(response).to render_template('username_email_result')
      end
    end
  end

  describe '#unsupportive_browser' do
    it 'should be succesful' do
      get :unsupported_browser
      expect(response).to be_successful
    end
  end
end
