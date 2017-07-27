require 'rails_helper'

describe UsersController do

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
        user.update_lockable
        sign_in(admin)
        get :lockable, id: user.id
      end

      subject(:result) { User.find(user.id) }
      it { expect(result.locked_at).to be_nil }
      it { expect(response).to redirect_to(user_account_index_exchanges_hbx_profiles_url) }
    end
  end

  describe '.reset_password' do
    let(:user) { FactoryGirl.create(:user, :with_consumer_role) }
    context 'When admin is not authorized for reset password then' do
      before do
        hbx_staff_role.permission_id = permission_no.id
        hbx_staff_role.save
        sign_in(admin)
        get :reset_password, id: user.id, format: :js
      end
      it { expect(assigns(:user)).to eq(user) }
      it { expect(response).to redirect_to(user_account_index_exchanges_hbx_profiles_url) }
    end

    context 'When admin is authorized for reset password then' do
      before do
        hbx_staff_role.permission_id = permission_yes.id
        hbx_staff_role.save
        sign_in(admin)
        get :reset_password, id: user.id, format: :js
      end
      it { expect(assigns(:user)).to eq(user) }
      it { expect(response).to render_template('reset_password') }
    end
  end

  describe '.confirm_reset_password' do

    context 'When admin is not authorized for reset password then' do
      let(:user) { FactoryGirl.create(:user, :with_consumer_role) }
      before do
        hbx_staff_role.permission_id = permission_no.id
        hbx_staff_role.save
        sign_in(admin)
        put :confirm_reset_password, id: user.id, format: :js
      end
      it { expect(assigns(:user)).to eq(user) }
      it { expect(user.reset_password_token).to be_nil }
      it { expect(user.reset_password_sent_at).to be_nil }
      it { expect(response).to redirect_to(user_account_index_exchanges_hbx_profiles_url) }
    end

    context 'When user email not present then' do
      let!(:user) { FactoryGirl.create(:user, :without_email, :with_family) }
      before do
        hbx_staff_role.permission_id = permission_yes.id
        hbx_staff_role.save
        sign_in(admin)
        put :confirm_reset_password, id: user.id, user: { email: '' }, format: :js
        user.reload
      end
      it { expect(assigns(:user)).to eq(user) }
      it { expect(assigns(:error)).to eq('Please enter a valid email') }
      it { expect(user.reset_password_token).to be_nil }
      it { expect(user.reset_password_sent_at).to be_nil }
      it { expect(response).to render_template('users/reset_password.js.erb') }
    end

    context 'When user email is not valid then' do
      let!(:user) { FactoryGirl.create(:user, :without_email, :with_family) }
      before do
        hbx_staff_role.permission_id = permission_yes.id
        hbx_staff_role.save
        sign_in(admin)
        put :confirm_reset_password, id: user.id, user: { email: 'hello' }, format: :js
        user.reload
      end
      it { expect(assigns(:user)).to eq(user) }
      it { expect(assigns(:error)).to eq('Email is invalid') }
      it { expect(user.reset_password_token).to be_nil }
      it { expect(user.reset_password_sent_at).to be_nil }
      it { expect(response).to render_template('users/reset_password.js.erb') }
    end

    context 'When user email is not unique then' do
      let(:user1) { FactoryGirl.create(:user, :with_consumer_role) }
      let!(:user) { FactoryGirl.create(:user, :without_email, :with_family) }
      before do
        hbx_staff_role.permission_id = permission_yes.id
        hbx_staff_role.save
        sign_in(admin)
        put :confirm_reset_password, id: user.id, user: { email: user1.email }, format: :js
        user.reload
      end
      it { expect(assigns(:user)).to eq(user) }
      it { expect(assigns(:error)).to eq('Email is already taken') }
      it { expect(user.reset_password_token).to be_nil }
      it { expect(user.reset_password_sent_at).to be_nil }
      it { expect(response).to render_template('users/reset_password.js.erb') }
    end

    context 'When admin is authorized for reset password then' do
      let!(:user) { FactoryGirl.create(:user, :with_consumer_role) }
      before do
        hbx_staff_role.permission_id = permission_yes.id
        hbx_staff_role.save
        sign_in(admin)
        put :confirm_reset_password, id: user.id, format: :js
        user.reload
      end
      it { expect(assigns(:user)).to eq(user) }
      it { expect(assigns(:error)).to be_nil }
      it { expect(user.reset_password_token).not_to be_nil }
      it { expect(user.reset_password_sent_at).not_to be_nil }
      it { expect(response).to redirect_to(user_account_index_exchanges_hbx_profiles_url) }
    end

  end
end
