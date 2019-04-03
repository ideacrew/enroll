require 'rails_helper'
require File.join(Rails.root, 'app', 'data_migrations', 'move_employer_staff_role_between_two_people')

describe MoveEmployerStaffRoleBetweenTwoPeople, dbclean: :after_each do
  let(:given_task_name) { 'move_employer_staff_role_between_two_people' }
  subject { MoveEmployerStaffRoleBetweenTwoPeople.new(given_task_name, double(current_scope: nil)) }

  def with_modified_env(options, &block)
    ClimateControl.modify(options, &block)
  end

  describe 'given a task name' do
    it 'has the given task name' do
      expect(subject.name).to eql given_task_name
    end
  end

  describe 'move employer staff role between two people', dbclean: :after_each do
    let!(:person1)             { FactoryBot.create(:person) }
    let!(:person2)             { FactoryBot.create(:person) }
    let!(:employer_staff_role) { FactoryBot.create(:employer_staff_role,person: person1) }
    let(:poc_env_support) {{from_hbx_id: person1.hbx_id, to_hbx_id: person2.hbx_id }}

    it 'should add employer staff role to person 2' do
      with_modified_env poc_env_support do 
        subject.migrate
        expect(person2.reload.employer_staff_roles?).to be_truthy
      end
    end

    it 'should close employer staff role to person 1' do
      with_modified_env poc_env_support do 
        subject.migrate
        expect(person1.reload.employer_staff_roles.first.is_closed?).to be_truthy
      end
    end

    it 'should deactivate employer staff role to person 1' do
      with_modified_env poc_env_support do 
        subject.migrate
        expect(person1.reload.employer_staff_roles.first.is_active).to be_falsey
      end
    end
  end
end
