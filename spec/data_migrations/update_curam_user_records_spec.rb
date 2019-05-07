require "rails_helper"
if ExchangeTestingConfigurationHelper.individual_market_is_enabled?
require File.join(Rails.root, "app", "data_migrations", "update_curam_user_records")

describe UpdateCuramUserRecords, dbclean: :after_each do

  let(:given_task_name) { "update_curam_user_records" }
  let(:curam_user) { FactoryBot.create(:curam_user, username: 'user!123')}
  subject { UpdateCuramUserRecords.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "update username & email of the curam user", dbclean: :after_each do
    it "should update the username of the user by finding user by username" do
      ClimateControl.modify :action => "update_UserName", :new_user_name => "UpdatE@This", :user_email => curam_user.email, :user_name => curam_user.username, :find_user_by => "email" do
        subject.migrate
        curam_user.reload
        expect(curam_user.username).to eq "UpdatE@This"
      end
    end

    it "should update the email of the user by finding user by username" do
      ClimateControl.modify :action => "update_Email", :new_user_email => "updatingemail@gmail.com", :find_user_by => "user_name", :user_email => curam_user.email, :user_name => curam_user.username do
        subject.migrate
        curam_user.reload
        expect(curam_user.email).to eq "updatingemail@gmail.com"
      end
    end

    it "should update the username of the user by finding user by email" do
      ClimateControl.modify :action => "update_username", :new_user_name => "user@321", :find_user_by => "email", :user_email => curam_user.email, :user_name => curam_user.username do
        subject.migrate
        curam_user.reload
        expect(curam_user.username).to eq "user@321"
      end
    end

    it "should update the email of the user by finding user by email" do
      ClimateControl.modify :action => "update_Email", :new_user_email => "updatingemail@gmail.com", :find_user_by => "email", :user_email => curam_user.email, :user_name => curam_user.username do
        subject.migrate
        curam_user.reload
        expect(curam_user.email).to eq "updatingemail@gmail.com"
      end
    end

    it "should update the dob of the user by finding user by email" do
      ClimateControl.modify :action => "update_dob", :new_dob => "04/04/1990", :find_user_by => "email", :user_email => curam_user.email, :user_name => curam_user.username do
        subject.migrate
        curam_user.reload
        expect(curam_user.dob).to eq Date.parse("04/04/1990")
      end
    end

    it "should update the ssn of the user by finding user by email" do
      ClimateControl.modify :action => "update_ssn", :new_dob => "456738293", :find_user_by => "email", :user_email => curam_user.email, :user_name => curam_user.username, :new_ssn => "456738293" do
        subject.migrate
        curam_user.reload
        expect(curam_user.ssn).to eq "456738293"
      end
    end
  end
end
end
