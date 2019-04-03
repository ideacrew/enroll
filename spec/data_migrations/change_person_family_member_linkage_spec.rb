require 'rails_helper'
require File.join(Rails.root, 'app', 'data_migrations', 'change_person_family_member_linkage')

describe ChangePersonFamilyMemberLinkage, dbclean: :after_each do 
  let(:given_task_name) { 'change_person_family_member_linkage' }
  let(:family_1) { FactoryBot.create(:family, :with_primary_family_member) }
  let(:family_2) { FactoryBot.create(:family, :with_primary_family_member) }
  let(:family_member) { family_2.primary_applicant }
  let(:person) { family_1.primary_applicant.person }
  subject { ChangePersonFamilyMemberLinkage.new(given_task_name, double(:current_scope => nil)) }

  describe 'given a task name' do
    it 'has the given task name' do
      expect(subject.name).to eql given_task_name
    end
  end

  describe 'changing the person to family member linkage' do
    it 'should change the linkage' do 
      ClimateControl.modify hbx_id: person.hbx_id, family_member_id: family_2.primary_applicant._id do
        subject.migrate
        family_member.reload
        expect(family_member.person_id).to eq person.id
      end
    end
  end
end
