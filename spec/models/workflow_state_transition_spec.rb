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
      let(:params) {valid_params.except(:transition_at)}

      it "should invalid" do
        expect(WorkflowStateTransition.new(**params).valid?).to be_falsey
      end
    end

    context "with all valid data" do
      it "should be valid" do
        expect(WorkflowStateTransition.new(**valid_params).valid?).to be_truthy
      end
    end
  end
end
