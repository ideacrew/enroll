require 'rails_helper'

describe UsersController do

  describe '.change_password' do
    let(:user) { build(:user, id: '1', password: 'Complex!@#$') }
    let(:original_password) { 'Complex!@#$' }
    before do
      allow(User).to receive(:find).with('1').and_return(user)
      sign_in(user)
      post :change_password, { id: '1', user: { password: original_password, new_password: 'S0methingElse!@#$', password_confirmation: 'S0methingElse!@#$'} }
    end

    context "with a matching current password" do
      it 'changes the password' do
        expect(user.valid_password? 'S0methingElse!@#$').to be_truthy
      end
    end

    context "with an invalid current password" do
      let(:original_password) { 'Potato' }
      it 'does not change the password' do
        expect(user.valid_password? 'Complex!@#$').to be_truthy
      end
    end
  end

  let(:permission_yes) { FactoryGirl.create(:permission, can_lock_unlock: true, can_reset_password: true) }
  let(:permission_no) { FactoryGirl.create(:permission, can_lock_unlock: false, can_reset_password: false) }
  let(:admin) { FactoryGirl.create(:user, :with_family, :hbx_staff) }
  let(:hbx_staff_role) { FactoryGirl.create(:hbx_staff_role, person: admin.person) }
  let(:hbx_profile) { FactoryGirl.create(:hbx_profile) }

  describe ".confirm_lock" do
    let(:user) { FactoryGirl.create(:user, :with_consumer_role) }
    before do
      hbx_staff_role.permission_id = permission_no.id
      hbx_staff_role.save
      sign_in(admin)
      get :confirm_lock, id: user.id, format: :js
    end
    it { expect(assigns(:user)).to eq(user) }
    it { expect(response).to render_template('confirm_lock') }
  end

  describe ".lockable" do
    let(:admin) { instance_double(User) }
    let(:locked_at) { nil }
    let(:user) { build(:user, id: '1', locked_at: locked_at) }

    before do
      allow_any_instance_of(UsersController).to receive(:authorize).with(User, :lockable?).and_raise(Pundit::NotAuthorizedError)
      allow(User).to receive(:find).with('1').and_return(user)
      allow(user).to receive(:update_lockable).and_call_original
      allow(user).to receive(:lock_access!)
      allow(user).to receive(:unlock_access!)
    end

    context 'When admin is not authorized for lockable then User status can not be changed' do
      before do
        sign_in(admin)
        get :lockable, id: user.id
      end

      it "does not lock the user" do
        expect(user).to_not have_received(:lock_access!)
        expect(user).to_not have_received(:unlock_access!)
        expect(response).to redirect_to(user_account_index_exchanges_hbx_profiles_url)
      end
    end

    context 'When admin is authorized for lockable then User status can be locked' do
      before do
        allow_any_instance_of(UsersController).to receive(:authorize).with(User, :lockable?).and_return(true)
        sign_in(admin)
        get :lockable, id: user.id
      end
      it "locks the user" do
        expect(user).to have_received(:lock_access!)
        expect(response).to redirect_to(user_account_index_exchanges_hbx_profiles_url)
      end
    end

    context 'When admin is authorized and User status is locked then it should be unlocked' do
      let(:locked_at) { Date.today }

      before do
        allow_any_instance_of(UsersController).to receive(:authorize).with(User, :lockable?).and_return(true)
        sign_in(admin)
        get :lockable, id: user.id
      end

      it "unlocks the user" do
        expect(user).to have_received(:unlock_access!)
        expect(response).to redirect_to(user_account_index_exchanges_hbx_profiles_url)
      end
    end
  end

  describe '.edit' do
    let(:user) { FactoryGirl.build(:user, :with_consumer_role) }
    before do
      sign_in(admin)
      allow(User).to receive(:find).with(user.id).and_return(user)
      get :edit, id: user.id, format: 'js'
    end
    it { expect(assigns(:user)).to eq(user) }
    it { expect(response).to render_template('edit') }
  end

  describe '.update' do
    let(:user) { FactoryGirl.build(:user, :with_consumer_role) }
    before do
      sign_in(admin)
    end

    context 'When email is not uniq then' do
      let(:user_params) { { email: '' } }
      before do
        sign_in(admin)
        allow(User).to receive(:find).with(user.id).and_return(user)
        allow(user).to receive(:update_attributes).with(user_params).and_return(false)
        allow(user).to receive(:errors).and_return({email: 'Email is already taken'})
        put :update, id: user.id, user: user_params, format: 'js'
      end
      it { expect(assigns(:user)).to eq(user) }
      it { expect(user.errors[:email]).to eq('Email is already taken') }
      it { expect(response).to render_template('update') }
    end

    context 'When email is uniq then' do
      let(:user_params) { { email: 'test@user.com' } }
      before do
        sign_in(admin)
        allow(User).to receive(:find).with(user.id).and_return(user)
        allow(user).to receive(:update_attributes).with(user_params).and_return(true)
        allow(user).to receive(:errors).and_return({email: ''})
        put :update, id: user.id, user: user_params, format: 'js'
      end
      it { expect(assigns(:user)).to eq(user) }
      it { expect(user.errors[:email]).to eq('') }
      it { expect(response).to render_template('update') }
    end
  end

end
