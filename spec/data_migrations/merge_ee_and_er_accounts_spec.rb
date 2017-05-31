require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "merge_ee_and_er_accounts")

describe MergeEeAndErAccounts do

  let(:given_task_name) { "merge ee and er accounts" }
  subject { MergeEeAndErAccounts.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end


  # ER Account
  # Username: nlonghi@coastalstates.org
  # e-Mail: nlonghi@coastalstates.org
  # User Roles: employer_staff
  # Last Sign In: 12/05/2016 20:12
  # First Name: Norma
  # Last Name: Longihi
  # HBX ID: 19895435
  # Person Created At: 12/05/2016 20:00
  # Person Roles: employer_staff_roles
  #
  # EE account
  # no user record
  # First Name: Norma
  # Last Name: Longhi
  # HBX ID: 19892264
  # Person Created At: 11/25/2016 20:55
  # e-Case ID:


  # pee = Person.where(hbx_id: /19892264/i).first
  # pemp = Person.where(hbx_id: /19895435/i).first
  # pee.employer_staff_roles
  # pemp.employer_staff_roles.size
  # pemp.employer_staff_roles.first
  # EmployerProfile.find("5838a0ddfaca1467200003c0").organization
  # pee.employer_staff_roles = pemp.employer_staff_roles
  # pee.save!
  #
  # pee.user
  # pee.user_id = pemp.user_id
  # pemp.unset(:user_id)
  # pee.save!
  # pee.user.roles.append("employee")
  # pee.user.save!


  # def migrate
  #   employee_hbx_id= ENV['employee_hbx_id']
  #   employer_hbx_id= ENV['employer_hbx_id']
  #   if Person.where(hbx_id: employee_hbx_id).nil?
  #     puts "No employee found with given hbx_id"
  #   elsif Person.where(hbx_id: employer_hbx_id).nil?
  #     puts "No employer found with givin hbx_id"
  #   else
  #     employee=Person.where(hbx_id: employee_hbx_id).first
  #     employer=Person.where(hbx_id: employer_hbx_id).first
  #     if employer.employer_staff_roles.nil?
  #       puts "No employer staff role attached to the employer"
  #     else
  #       employer_staff_role=employer.employer_staff_roles.first
  #       if employer_staff_role.employer_profile_id.nil?
  #         puts "No employer_profile_id found with employer staff role"
  #       else
  #         employee.employer_staff_roles=employer.employer_staff_roles
  #         employee.save!
  #       end
  #       employee.user_id = employer.user_id
  #       employer.unset(:user_id)
  #       employee.save!
  #       employee.user.roles.append("employee")
  #       employee.user.save!
  #     end
  #   end
  # end


  describe "merge ee and er roles" do

    let!(:user) { FactoryGirl.create(:user, person: employer_staff_role.person)}
    let(:person)  {FactoryGirl.create(:person,:with_employee_role, hbx_id: "1234567")}
    let(:employer_staff_role) {FactoryGirl.create(:employer_staff_role,employer_profile_id:employer_profile.id)}
    let(:employer_profile){FactoryGirl.create(:employer_profile)}

    before(:each) do
      allow(ENV).to receive(:[]).with("employee_hbx_id").and_return(person.hbx_id)
      allow(ENV).to receive(:[]).with("employer_hbx_id").and_return(employer_staff_role.person.hbx_id)
    end

    context "giving a new state" do
      it "should assign user to the employee" do
        expect(person.user).to eq nil
        expect(employer_staff_role.person.user).not_to eq nil
        puts Person.all.map{|p| p.user.inspect}
        subject.migrate
        person.reload
        expect(person.user).not_to eq nil
      end

      # it "should not change it's state" do
      #   plan_year.aasm_state = "renewing_enrolling"
      #   plan_year.save
      #   subject.migrate
      #   plan_year.reload
      #   expect(plan_year.aasm_state).to eq "renewing_enrolling"
      # end

    end
  end
end
