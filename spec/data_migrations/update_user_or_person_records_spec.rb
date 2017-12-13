require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "update_user_or_person_records")

describe UpdateUserOrPersonRecords, dbclean: :after_each do

  let(:given_task_name) { "update_user_or_person_records" }
  subject { UpdateUserOrPersonRecords.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "update username & email on user and also destroying headless user", dbclean: :after_each do

    let!(:person) { FactoryGirl.create(:person, hbx_id: "1234", user: user) }
    let!(:user) { FactoryGirl.create(:user) }

    before :each do
      ['action', 'user_email', 'person_email', 'user_name', 'headless_user', 'find_user_by', 'hbx_id'].each do |var|
        ENV[var] = nil
      end

    end

    it "should update the username on the user" do
      ENV['action'] = "update_username"
      ENV['user_name'] = "UpdatE@This"
      ENV['hbx_id'] = "1234"
      subject.migrate
      user.reload
      expect(user.oim_id).to eq "UpdatE@This"
    end

    it "should update the email on the user" do
      ENV['action'] = "update_email"
      ENV['user_email'] = "updatingemail@gmail.com"
      ENV['find_user_by'] = "user_name"
      ENV['user_name'] = user.oim_id
      subject.migrate
      user.reload
      expect(user.email).to eq "updatingemail@gmail.com"
    end

    it "should not destroy user record by oim_id if it's not headless" do
      ENV['find_user_by'] = "user_name"
      ENV['headless_user'] = "yes"
      ENV['user_name'] = user.oim_id
      subject.migrate
      expect(User.where(oim_id: user.oim_id).present?).to eq true
    end

    it "should destroy the headless user by user email" do
      ENV['find_user_by'] = "email"
      ENV['headless_user'] = "yes"
      ENV['user_email'] = user.email
      user.person.destroy!
      subject.migrate
      expect(User.where(email: user.email).present?).to eq false
    end

    context "updating email on person record" do
      let(:person) { FactoryGirl.create(:person)}

      it "should update the home email on person record" do
        ENV['action'] = "update_person_home_email"
        ENV['person_email'] = "my_home1198@test.com"
        ENV['headless_user'] = "no"
        ENV['hbx_id'] = person.hbx_id
        subject.migrate
        person.reload
        home_email = person.emails.detect { |email| email.kind == "home"}
        expect(home_email.address).to eq "my_home1198@test.com"
      end

      it "should update the work email on person record using oim_id" do
        ENV['hbx_id'] = person.hbx_id
        ENV['headless_user'] = "no"
        ENV['user_name'] = user.oim_id
        ENV['action'] = "update_person_work_email"
        ENV['person_email'] = "my_work1198@test.com"
        person.emails.first.update_attributes(kind: "work")
        subject.migrate
        person.reload
        work_email = person.emails.detect { |email| email.kind == "work"}
        expect(work_email.address).to eq "my_work1198@test.com"
      end
    end
  end
end
