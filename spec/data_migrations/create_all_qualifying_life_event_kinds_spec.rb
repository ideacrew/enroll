require 'rails_helper'
require File.join(Rails.root, 'app', 'data_migrations', 'create_all_qualifying_life_event_kinds')

describe CreateAllQualifyingLifeEventKinds do
  let(:given_task_name) { 'create_all_qualifying_life_event_kinds' }
  subject { CreateAllQualifyingLifeEventKinds.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe 'migrate' do
    context 'activate_benefit_group_assignment', dbclean: :after_each do
      it 'should activate_related_benefit_group_assignment' do
        subject.migrate
        expect(QualifyingLifeEventKind.all.count).to be > 1
      end
    end
  end
end
