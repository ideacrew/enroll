require "rails_helper"

describe PrimaryPOC do
  
  let(:given_task_name) { "primary_poc" }
  subject { PrimaryPOC.new(given_task_name, double(:current_scope => nil)) }
  
  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end
  
  describe "build_employer" do 
    
    let(:given_task_name) {':create_employer'}
    let(:employer_profile)  { FactoryGirl.create(:employer_profile) }
    let(:user1) { FactoryGirl.create(:user, oim_id:'username10',email:'test@gmail.com') }
    let(:person) { FactoryGirl.create(:person, user_id:user1.id)}
    
    context "checks poc for employers with one poc present and make them primary_poc", dbclean: :after_each do
      
      it "expects primary poc count to be zero and staff count to be 1" do
        employer_staff_role = EmployerStaffRole.create(person: person, employer_profile_id: employer_profile._id)
        employer_staff_role.approve!
        expect(Person.staff_for_employer(employer_profile).size).to eq 1
        expect(person.active_employer_staff_roles.first.primary_poc).to eq false
      end
    
      it "expects primary poc count to be true" do
        employer_staff_role = EmployerStaffRole.create(person: person, employer_profile_id: employer_profile._id)
        employer_staff_role.approve!
        person.make_primary(true)
        expect(person.active_employer_staff_roles.first.primary_poc).to eq true
      end
    
  end
    
  end
  
end