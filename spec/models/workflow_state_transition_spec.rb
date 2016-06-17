require 'rails_helper'

RSpec.describe WorkflowStateTransition, type: :model do
  it { should validate_presence_of :to_state }
  it { should validate_presence_of :transition_at }

  let(:from_state) { "applicant" }
  let(:to_state) { "approved" }
  let(:transition_at) { Time.now }

  describe ".new" do
    let(:valid_params) do
      {
        from_state: from_state,
        to_state: to_state,
        transition_at: transition_at
      }
    end

    context "with no arguments" do
      let(:params) {{}}

      it "should invalid" do
        expect(WorkflowStateTransition.new(**params).valid?).to be_falsey
      end
    end

     context "with no to_state" do
      let(:params) {valid_params.except(:to_state)}

      it "should invalid" do
        expect(WorkflowStateTransition.new(**params).valid?).to be_falsey
      end
    end

    context "with no transition_at" do
      let(:params)                    {valid_params.except(:transition_at)}
      let(:workflow_state_transition) { WorkflowStateTransition.new(**params) }
      let(:mock_time) { Time.mktime(2014, 2, 13, 0, 0, 0) }

      before do
        allow(Time).to receive(:now).and_return(mock_time)
      end

      it "should set the transition_at value before validation" do
        expect(workflow_state_transition.valid?).to be_truthy
        expect(workflow_state_transition.transition_at.to_time).to eq mock_time
      end
    end

    context "with all valid data" do
      let(:params)                    { valid_params }
      let(:workflow_state_transition) { WorkflowStateTransition.new(**params) }

      it "should be valid" do
        expect(workflow_state_transition.valid?).to be_truthy
      end

      it "should use the passed value for transition_at" do
        expect(workflow_state_transition.transition_at).to eq transition_at
      end

    end
  end
end
