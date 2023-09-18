# frozen_string_literal: true

require 'rails_helper'
require Rails.root.join('spec/shared_contexts/valid_cv3_application_setup.rb')

RSpec.describe Operations::Fdsh::BuildAndValidateApplicationPayload, dbclean: :after_each do
  include_context "valid cv3 application setup"

  describe '#call' do
    context 'returning a payload in during an admin FDSH hub call' do
      context 'for :income request type' do
        let(:request_type) { :income }

        context 'when all validation rules pass' do
          it 'returns a Success result' do
            result = described_class.new.call(application)
            expect(result).to be_success
          end
        end

        context 'with a malformed cv3' do
          before do
            allow(application).to receive(:applicants).and_return(nil)
          end

          it 'raises an error' do
            result = described_class.new.call(application)

            expect(result).to be_failure
          end
        end
      end
    end
  end
end