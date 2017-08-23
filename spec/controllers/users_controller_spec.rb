require 'rails_helper'

describe UsersController do

  let(:admin) { FactoryGirl.create(:user, :with_family, :hbx_staff) }
  let(:hbx_staff_role) { FactoryGirl.create(:hbx_staff_role, person: admin.person) }
  let(:hbx_profile) { FactoryGirl.create(:hbx_profile) }

  after :all do
    DatabaseCleaner.clean
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
    let(:permission_yes) { FactoryGirl.create(:permission, can_lock_unlock: true) }
    let(:permission_no) { FactoryGirl.create(:permission, can_lock_unlock: false) }

    context 'When admin is not authorized for lockable then User status can not be changed' do
      let(:user) { FactoryGirl.create(:user, :with_consumer_role) }
      before do
        hbx_staff_role.permission_id = permission_no.id
        hbx_staff_role.save
        sign_in(admin)
        get :lockable, id: user.id
      end
      it { expect(user.locked_at).to be_nil }
      it { expect(response).to redirect_to(user_account_index_exchanges_hbx_profiles_url) }
    end

    context 'When admin is authorized for lockable then User status can be locked' do
      let(:user) { FactoryGirl.create(:user, :with_consumer_role) }
      before do
        hbx_staff_role.permission_id = permission_yes.id
        hbx_staff_role.save
        sign_in(admin)
        get :lockable, id: user.id
      end

      subject(:result) { User.find(user.id) }
      it { expect(result.locked_at).not_to be_nil }
      it { expect(response).to redirect_to(user_account_index_exchanges_hbx_profiles_url) }
    end

    context 'When admin is authorized and User status is locked then it should be unlocked' do
      let(:user) { FactoryGirl.create(:user, :with_consumer_role) }
      before do
        hbx_staff_role.permission_id = permission_yes.id
        hbx_staff_role.save
        user.lock!
        sign_in(admin)
        get :lockable, id: user.id
      end

      subject(:result) { User.find(user.id) }
      it { expect(result.locked_at).to be_nil }
      it { expect(response).to redirect_to(user_account_index_exchanges_hbx_profiles_url) }
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
