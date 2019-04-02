require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "change_email_of_user")
describe ChangeEmailOfUser, dbclean: :after_each do
  let(:given_task_name) { "change_email_of_user" }
  let(:user) { FactoryBot.create(:user) }

  subject { ChangeEmailOfUser.new(given_task_name, double(:current_scope => nil)) }
  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end
  describe "change the email of a user" do

    it "should change the email of the user" do
      ClimateControl.modify user_oimid: user.oim_id, new_email: "newemail@gmail.com" do 
        email=user.email
        expect(user.email).to eq email
        subject.migrate
        user.reload
        expect(user.email).to eq "newemail@gmail.com"
      end
    end
  end
  describe "not change the email if the user not found" do
    it "should change the email of the user" do
      with_modified_env user_oimid: "", new_email: "newemail@gmail.com" do 
        email=user.email
        expect(user.email).to eq email
        subject.migrate
        user.reload
        expect(user.email).to eq email
      end
    end
  end

  def with_modified_env(options, &block)
    ClimateControl.modify(options, &block)
  end
end
