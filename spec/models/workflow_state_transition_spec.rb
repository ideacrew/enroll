require 'rails_helper'

RSpec.describe WorkflowStateTransition, type: :model do
  it { should validate_presence_of :end_state }
  it { should validate_presence_of :transition_on }

  let(:end_state) { "approved" }
  let(:transition_on) { Date.current }

  describe ".new" do
    let(:valid_params) do
      {
        end_state: end_state,
        transition_on: Date.current
      }
    end

    context "with no arguments" do
      let(:params) {{}}

      it "should invalid" do
        expect(WorkflowStateTransition.new(**params).valid?).to be_falsey
      end
    end

    context "with no end_state" do
      let(:params) {valid_params.except(:end_state)}

      it "should invalid" do
        expect(WorkflowStateTransition.new(**params).valid?).to be_falsey
      end
    end

    context "with no transition_on" do
      let(:params) {valid_params.except(:transition_on)}

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
