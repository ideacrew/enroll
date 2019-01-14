require 'rails_helper'
require File.join(Rails.root, 'app', 'data_migrations', 'move_employer_staff_role_between_two_people')

describe MoveEmployerStaffRoleBetweenTwoPeople, dbclean: :after_each do
  let(:given_task_name) { 'move_employer_staff_role_between_two_people' }
  subject { MoveEmployerStaffRoleBetweenTwoPeople.new(given_task_name, double(current_scope: nil)) }

  describe 'given a task name' do
    it 'has the given task name' do
      expect(subject.name).to eql given_task_name
    end
  end

  describe 'move employer staff role between two people', dbclean: :after_each do
    let!(:person1)             { FactoryBot.create(:person) }
    let!(:person2)             { FactoryBot.create(:person) }
    let!(:employer_staff_role) { FactoryBot.create(:employer_staff_role,person: person1) }

    before(:each) do
      allow(ENV).to receive(:[]).with('from_hbx_id').and_return(person1.hbx_id)
      allow(ENV).to receive(:[]).with('to_hbx_id').and_return(person2.hbx_id)
      subject.migrate
      person1.reload
      person2.reload
    end

    it 'should add employer staff role to person 2' do
      expect(person2.employer_staff_roles?).to be_truthy
    end

    it 'should close employer staff role to person 1' do
      expect(person1.employer_staff_roles.first.is_closed?).to be_truthy
    end

    it 'should deactivate employer staff role to person 1' do
      expect(person1.employer_staff_roles.first.is_active).to be_falsey
    end
  end
end
