require 'rails_helper'
require File.join(Rails.root, 'app', 'data_migrations', 'change_username')

describe ChangeUsername, dbclean: :after_each do
  let(:given_task_name) { "change_username" }
  subject { ChangeUsername.new(given_task_name, double(:current_scope => nil)) }
  let(:user) { FactoryBot.create(:user) }
  let(:new_user) { FactoryBot.create(:user) }
  describe 'given a task name' do
    it 'has the given task name' do
      expect(subject.name).to eql given_task_name
    end
  end
  
  describe 'change the username of a user' do
    it 'should change the username of the user' do
    with_modified_env old_user_oimid: user.oim_id, new_user_oimid: 'NewUsername' do 
        username=user.oim_id
        expect(user.oim_id).to eq username
        subject.migrate
        user.reload
        expect(user.oim_id).to eq 'NewUsername'
      end
    end
  end
  
  describe 'not change the username if the user not found' do
    it 'should not change the username of the user' do
      with_modified_env old_user_oimid: '', new_user_oimid: 'NewUsername' do 
        username=user.oim_id
        expect(user.oim_id).to eq username
        subject.migrate
        user.reload
        expect(user.oim_id).to eq username
      end
    end
  end

  describe 'if new user already present in Enroll System' do
    it 'should not change the new username of the user' do
      with_modified_env old_user_oimid: user.oim_id, new_user_oimid: new_user.oim_id do 
        username=user.oim_id
        expect(user.oim_id).to eq username
        subject.migrate
        user.reload
        expect(user.oim_id).not_to eq new_user.oim_id
      end
    end
  end

  def with_modified_env(options, &block)
    ClimateControl.modify(options, &block)
  end
end
