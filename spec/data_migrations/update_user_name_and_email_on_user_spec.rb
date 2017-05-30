require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "update_user_name_and_email_on_user")

describe UpdateUserNameAndEmailOnUser do
  
  let(:given_task_name) { "update_user_name_and_email_on_user" }
  subject { UpdateUserNameAndEmailOnUser.new(given_task_name, double(:current_scope => nil)) }
  
  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "update username & email on user and also destroying headless user", dbclean: :after_each do
    
    let(:user) { FactoryGirl.create(:user, :with_family)}    
    before do
      allow(ENV).to receive(:[]).with('action').and_return ""
      allow(ENV).to receive(:[]).with('user_email').and_return user.email
      allow(ENV).to receive(:[]).with('user_name').and_return user.oim_id
      allow(ENV).to receive(:[]).with('headless_user').and_return ""
      allow(ENV).to receive(:[]).with('find_user_by').and_return "email"
    end
    
    it "should update the username on the user" do
      allow(ENV).to receive(:[]).with('action').and_return "update_UserName"
      allow(ENV).to receive(:[]).with('user_name').and_return "UpdatE@This"
      subject.migrate
      user.reload
      expect(user.oim_id).to eq "UpdatE@This"
    end

    it "should update the email on the user" do
      allow(ENV).to receive(:[]).with('find_user_by').and_return "user_name"
      allow(ENV).to receive(:[]).with('user_email').and_return "updatingemail@gmail.com"
      allow(ENV).to receive(:[]).with('action').and_return "update_Email"
      subject.migrate
      user.reload
      expect(user.email).to eq "updatingemail@gmail.com"
    end

    it "should not destroy user record if it's not headless" do
      allow(ENV).to receive(:[]).with('find_user_by').and_return "user_name"
      allow(ENV).to receive(:[]).with('headless_user').and_return "yes"
      subject.migrate
      expect(User.where(email: user.email).present?).to eq true
    end

    it "should destroy the headless user" do
      allow(ENV).to receive(:[]).with('find_user_by').and_return "user_name"
      allow(ENV).to receive(:[]).with('headless_user').and_return "yes"
      user.person.destroy!
      subject.migrate
      expect(User.where(email: user.email).present?).to eq false
    end
  end
end