require 'rails_helper'

describe UsersController, dbclean: :after_each do
  let(:admin) { instance_double(User) }
  let(:user_policy) { instance_double(UserPolicy) }
  let(:user) { instance_double(User, :email => user_email) }
  let(:user_id) { "23432532423424" }
  let(:user_email) { "some_email@some_domain.com" }

  after :all do
    DatabaseCleaner.clean
  end

  describe '.change_password' do
    let(:user) { build(:user, id: '1', password: 'Complex!@#$') }
    let(:original_password) { 'Complex!@#$' }
    before do
      allow(User).to receive(:find).with('1').and_return(user)
      sign_in(user)
      post :change_password, params: { id: '1', user: { password: original_password, new_password: 'S0methingElse!@#$', password_confirmation: 'S0methingElse!@#$'} }
    end

    context "with a matching current password" do
      xit 'changes the password' do
        expect(user.valid_password? 'S0methingElse!@#$').to be_truthy
      end
    end

    context "with an invalid current password" do
      let(:original_password) { 'Potato' }
      xit 'does not change the password' do
        expect(user.valid_password? 'Complex!@#$').to be_truthy
      end
    end
  end


  before :each do
    allow(UserPolicy).to receive(:new).with(admin, User).and_return(user_policy)
    allow(User).to receive(:find).with(user_id).and_return(user)
  end

  describe ".change_username_and_email" do
    let(:user) { build(:user, id: '1', oim_id: user_email) }
    before do
      allow(user_policy).to receive(:change_username_and_email?).and_return(true)
    end

    context "An admin is allowed to access the change username action" do
      before do
        sign_in(admin)
      end
      it "renders the change username form" do
        get :change_username_and_email, params: { id: user_id }, format: :js
        expect(response).to render_template('change_username_and_email')
      end
    end

    context "An admin is not allowed to access the change username action" do
      before do
        allow(user_policy).to receive(:change_username_and_email?).and_return(false)
        sign_in(admin)
      end
      it "doesn't render the change username form" do
        get :change_username_and_email, params: { id: user_id }, format: :js
        expect(flash[:alert]).to be_present
        expect(flash[:alert]).to include('You are not authorized for this action.')
      end
    end
  end

  describe ".confirm_change_username_and_email", dbclean: :after_each do
    let(:person) { FactoryBot.create(:person) }
    let(:user) { FactoryBot.create(:user, :person => person) }
    let(:hbx_staff_role) { FactoryBot.create(:hbx_staff_role, person: person)}
    let(:hbx_profile) { FactoryBot.create(:hbx_profile)}
    let(:invalid_username) { "ggg" }
    let(:valid_username) { "gariksubaric" }
    let(:invalid_email) { "email@" }
    let(:valid_email) { "email@email.com" }

    before do
      allow(UserPolicy).to receive(:new).with(user, User).and_return(user_policy)
      allow(user_policy).to receive(:change_username_and_email?).and_return(true)
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

  describe ".confirm_lock, with a user allowed to perform locking" do
    before do
      allow(user_policy).to receive(:lockable?).and_return(true)
      sign_in(admin)
      get :confirm_lock, params:  {id: user_id, format: :js}
    end
    it { expect(response).to render_template('confirm_lock') }
  end

  describe ".lockable" do
    before do
      allow(user_policy).to receive(:lockable?).and_return(can_lock)
      allow(user).to receive(:lockable_notice).and_return("locked/unlocked")
    end

    context 'When admin is not authorized for lockable then User status can not be changed' do
      let(:can_lock) { false }
      before do
        allow(admin).to receive(:person).and_return nil
        sign_in(admin)
      end
      it "does not toggle the lock status" do
        expect(user).not_to receive(:lock!)
        get :lockable, params: {id: user_id}
      end
      it do
        get :lockable, params: {id: user_id}
        expect(response).to redirect_to(user_account_index_exchanges_hbx_profiles_url)
      end
    end

    context 'When admin is authorized for lockable then User status can be locked' do
      let(:can_lock) { true }
      before do
        sign_in(admin)
        allow(user).to receive(:lock!)
      end

      it "toggles the user lock" do
        expect(user).to receive(:lock!)
        get :lockable, params: {id: user_id}
      end
      it do
        get :lockable, params: {id: user_id}
        expect(flash[:notice]).to be_present
      end
    end

    context 'When admin is authorized and User status is locked then it should be unlocked' do
      let(:can_lock) { true }
      before do
        sign_in(admin)
        allow(user).to receive(:lock!)
      end

      it "toggles the user lock" do
        expect(user).to receive(:lock!)
        get :lockable, params: {id: user_id}
      end
    end
  end

  describe '.reset_password' do
    before do
      allow(user_policy).to receive(:reset_password?).and_return(can_reset_password)
    end

    context 'When admin is not authorized for reset password then' do
      let(:can_reset_password) { false }
      before do
        sign_in(admin)
      end
      it "does not send password reset information" do
        expect(User).not_to receive(:send_reset_password_instructions)
        get :reset_password, params: {id: user_id, format: :js}
      end
      it do
        get :reset_password, params:{id: user_id, format: :js}
        expect(flash[:alert]).to be_present
        expect(flash[:alert]).to include('You are not authorized for this action.')
      end
    end

    context 'When admin is authorized for reset password then' do
      let(:can_reset_password) { true }
      before do
        sign_in(admin)
        get :reset_password, params: {id: user_id, format: :js}
      end
      it do
        expect(response.status).to equal(200)
      end
    end
  end

  describe '#unsupportive_browser' do
    it 'should be succesful' do
      get :unsupported_browser
      expect(response).to be_success
    end
  end

  describe '.confirm_reset_password' do
    let(:can_reset_password) { false }

    before do
      allow(user_policy).to receive(:reset_password?).and_return(can_reset_password)
    end

    context 'When admin is not authorized for reset password then' do
      let(:can_reset_password) { false }
      before do
        sign_in(admin)
        put :confirm_reset_password, params: {id: user_id, format: :js}
      end
      it { expect(user).not_to receive(:send_reset_password_instructions) }
      it { expect(assigns(:user)).to eq(user) }
      it { expect(response).to redirect_to(user_account_index_exchanges_hbx_profiles_url) }
    end

    context 'When user email not present then' do
      let(:can_reset_password) { true }
      before do
        sign_in(admin)
      end
      it "does not reset the password" do
        expect(User).not_to receive(:send_reset_password_instructions)
        put :confirm_reset_password, params: {id: user_id, user: { email: '' }, format: :js}
      end
      it do
        put :confirm_reset_password, params: {id: user_id, user: { email: '' }, format: :js}
        expect(assigns(:error)).to eq('Please enter a valid email')
      end
      it do
        put :confirm_reset_password, params: {id: user_id, user: { email: '' }, format: :js}
        expect(response).to render_template('users/reset_password.js.erb')
      end
    end

  describe '.edit' do
    let(:user) { FactoryBot.build(:user, :with_consumer_role) }
    before do
      sign_in(admin)
      allow(User).to receive(:find).with(user.id).and_return(user)
      get :edit, params: {id: user.id, format: 'js'}
    end
    it { expect(assigns(:user)).to eq(user) }
    it { expect(response).to render_template('edit') }
  end

    context 'When user information is not valid' do
      let(:can_reset_password) { true }
      let(:params) {{ email: user_email } }
      let(:strong_params){ActionController::Parameters.new(params).permit(:email)}

      before do
        allow(user).to receive(:errors).and_return(double(:full_messages => ["error message"]))
        allow(user).to receive(:update_attributes).with(strong_params).and_return(false)
        sign_in(admin)
      end

      it "does not reset the password" do
        put :confirm_reset_password, params:  {id: user_id, user: { email: user_email }, format: :js}
      end
      it do
        put :confirm_reset_password, params:  {id: user_id, user: { email: user_email }, format: :js}
        expect(assigns(:error)).to include("error message")
      end
      it do
        put :confirm_reset_password, params:  {id: user_id, user: { email: user_email }, format: :js}
        expect(response).to render_template('users/reset_password.js.erb')
      end
    end

    context 'When admin is authorized for reset password then' do
      let(:can_reset_password) { true }
      before do
        sign_in(admin)
        allow(User).to receive(:send_reset_password_instructions).with({email: user_email})
      end

      it "sends the password reset email" do
        expect(User).to receive(:send_reset_password_instructions).with({email: user_email})
        put :confirm_reset_password, params: {id: user_id, format: :js}
      end

      it do
        put :confirm_reset_password, params: {id: user_id, format: :js}
        expect(response).to redirect_to(user_account_index_exchanges_hbx_profiles_url)
      end
    end
  end

end
