require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "update_user_or_person_records")

describe UpdateUserOrPersonRecords, dbclean: :after_each do

  let(:given_task_name) { "update_user_or_person_records" }
  let(:user) { FactoryBot.create(:user, :with_family)}
  subject { UpdateUserOrPersonRecords.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "update username & email on user and also destroying headless user", dbclean: :after_each do
    let!(:person) { FactoryBot.create(:person, :with_ssn, hbx_id: "1234", user: user) }
    let!(:user) { FactoryBot.create(:user) }

    around :each do |example|
      attrs = {
        action: nil,
        user_email: nil,
        person_email: nil,
        user_name: nil,
        headless_user: nil,
        find_user_by: nil,
        hbx_id: nil,
        new_user_email: nil,
        new_user_name: nil,
        dob: nil
      }

      ClimateControl.modify attrs do
        example.run
      end
    end

    it "should update the username on the user" do
      ClimateControl.modify action: 'update_username', user_name: 'UpdatE@This', hbx_id: '1234' do
        subject.migrate
        user.reload
        expect(user.oim_id).to eq "UpdatE@This"
      end
    end

    it "should update the email on the user" do
      ClimateControl.modify action: 'update_email', user_email: 'updatingemail@gmail.com', find_user_by: 'user_name', user_name: user.oim_id do
        subject.migrate
        user.reload
        expect(user.email).to eq "updatingemail@gmail.com"
      end
    end

    it "should not destroy user record by oim_id if it's not headless" do
      ClimateControl.modify user_name: user.oim_id, find_user_by: 'user_name', headless_user: 'yes' do
        subject.migrate
        expect(User.where(oim_id: user.oim_id).present?).to eq true
      end
    end

    it "should destroy the headless user by user email" do
      ClimateControl.modify user_email: user.email, find_user_by: 'email', headless_user: 'yes' do
        user.person.destroy!
        subject.migrate
        expect(User.where(email: user.email).present?).to eq false
      end
    end

    it "should update the home email on person record" do
      ClimateControl.modify hbx_id: person.hbx_id, action: 'update_person_home_email', person_email: 'my_home1198@test.com' do
        subject.migrate
        person.reload
        home_email = person.emails.detect { |email| email.kind == "home"}
        expect(home_email.address).to eq "my_home1198@test.com"
      end
    end

    it "should update the work email on person record using oim_id" do
      ClimateControl.modify hbx_id: person.hbx_id, action: 'update_person_work_email', user_name: user.oim_id, person_email: 'my_work1198@test.com' do
        person.emails.first.update_attributes(kind: "work")
        subject.migrate
        person.reload
        work_email = person.emails.detect { |email| email.kind == "work"}
        expect(work_email.address).to eq "my_work1198@test.com"
      end
    end

    context "create email record on person" do
      context "if you say 'yes' to create a new email" do
        before do
          allow(STDIN).to receive(:gets).and_return "yes"
        end

        around do |example|
          # allow(STDIN).to receive(:gets).and_return "yes"
          ClimateControl.modify hbx_id: person.hbx_id, person_email: 'my_work1198@test.com', gets: 'yes' do
            example.run
          end
        end

        it "should create a new home email" do
          ClimateControl.modify action: 'update_person_home_email' do
            person.emails.delete_if { |email| email.kind == "home"}
            subject.migrate
            person.reload
            expect(person.emails.select { |email| email.kind == "home"}.size).to eq 1
          end
        end

        it "should create a new work email" do
          ClimateControl.modify action: 'update_person_work_email' do
            person.emails.delete_if { |email| email.kind == "work"}
            subject.migrate
            person.reload
            expect(person.emails.select { |email| email.kind == "work"}.size).to eq 1
          end
        end
      end

      context "if you say 'no' to create a new email" do

        before do
          allow(STDIN).to receive(:gets).and_return "no"
        end

        around do |example|
          # allow(STDIN).to receive(:gets).and_return "no"
          ClimateControl.modify person_email: 'my_work1198@test.com', gets: "no" do
            example.run
          end
        end

        it "should not create a new home email" do
          person.emails.delete_if { |email| email.kind == "home"}
          subject.migrate
          person.reload
          expect(person.emails.select { |email| email.kind == "home"}.size).to eq 0
        end

        it "should not create a new work email" do
          ClimateControl.modify action: 'update_person_work_email' do
            person.emails.delete_if { |email| email.kind == "work"}
            subject.migrate
            person.reload
            expect(person.emails.select { |email| email.kind == "work"}.size).to eq 0
          end
        end
      end

      context "update dob on person" do
        let(:birthday) { (person.dob - 4.years) }
        let(:wrong_birthday) { (person.dob - 3.years)}
        let(:too_old) { (person.dob - 112.years) }

        around do |example|
          ClimateControl.modify hbx_id: person.hbx_id, action: 'person_dob', dob: birthday.strftime('%d/%m/%Y') do
            example.run
          end
        end

        #this spec should not pass due to emplyee role being created after person create and migration escapes people with employee roles
        # it "should update the dob on the record" do
        #   updated_dob = birthday
        #   subject.migrate
        #   person.reload
        #   expect(person.dob).to eq updated_dob
        # end

        it "should not update the dob if greater than 110 years old" do
          updated_dob = too_old
          ClimateControl.modify dob: updated_dob.strftime('%d/%m/%Y') do
            subject.migrate
            person.reload
            expect(person.dob).not_to eq updated_dob
          end
        end

        it "should not update the dob if it effects person match" do
          updated_dob = wrong_birthday
          ClimateControl.modify dob: updated_dob.strftime('%d/%m/%Y') do
            allow(Person).to receive(:match_by_id_info).and_return [double("Person")]
            subject.migrate
            person.reload
            expect(person.dob).not_to eq updated_dob
          end
        end

        context "person with employee_role" do
          let(:person) { FactoryBot.create(:person, :with_employee_role)}

          it "should not update the dob if the census record already linked" do
            updated_dob = wrong_birthday
            ClimateControl.modify dob: updated_dob.strftime('%d/%m/%Y') do
              subject.migrate
              person.reload
              expect(person.dob).not_to eq updated_dob
            end
          end
        end
      end
    end
  end
end
