require 'rails_helper'
require 'rake'

require File.join(Rails.root, 'app', 'data_migrations', 'delete_duplicate_workflow_state_transitions')

describe DeleteDuplicateWorkflowStateTransitions, dbclean: :after_each do
  let(:given_task_name) { 'delete_duplicate_workflow_state_transitions' }

  subject { DeleteDuplicateWorkflowStateTransitions.new(given_task_name, double(:current_scope => nil)) }

  describe 'given a task name' do
    it 'has the given task name' do
      expect(subject.name).to eql given_task_name
    end
  end

  describe 'for a given hxb_id' do
    let(:person) { FactoryBot.create(:person, :with_consumer_role) }

    around do |example|
      ClimateControl.modify person_hbx_id: hbx_id do
        example.run
      end
    end


    context 'for an invalid person hbx_id' do
      let(:hbx_id) { 'hbx_id' }

      it 'should do nothing' do
        expect { subject.migrate }.not_to raise_error
      end
    end

    context 'has duplicate tax household' do
      let(:hbx_id) { person.hbx_id }
      let(:consumer_role) { person.consumer_role }
      let(:transition1) { FactoryBot.create(:workflow_state_transition, transitional: consumer_role) }
      let(:transition2) { FactoryBot.create(:workflow_state_transition, transitional: consumer_role) }

      before do
        person.save!
        subject.migrate
        person.reload
      end

      it 'should delete duplicate workflow state transitions' do
        expect { person.consumer_role.workflow_state_transitions.count.to eq(1) }
      end
    end
  end
end
