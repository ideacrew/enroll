# frozen_string_literal: true

require "rails_helper"
 # This class is invoked when we want to send a tax notice
module Operations
  RSpec.describe SendTaxFormNoticeAlert do
    subject do
      described_class.new.call(**params)
    end

    let(:person) { FactoryBot.create(:person) }

    describe "not passing :resource" do

      let(:params) { { resource: nil }}
      let(:error_message) {{:message => ['Please find valid resource to send the alert message']}}

      it "fails" do
        expect(subject).not_to be_success
        expect(subject.failure).to eq error_message
      end
    end

    describe "passing consumer person as :resource" do

      let(:params) { { resource: person }}

      before do
        allow(person.consumer_role).to receive(:can_receive_electronic_communication?).and_return true
      end

      it "passes" do
        expect(subject).to be_success
      end
    end
  end
end
