# frozen_string_literal: true

require 'rails_helper'
require 'bundler'
require 'gem_utils'

RSpec.describe GemUtils do
  describe '.aca_entities_sha' do
    let(:spec) { instance_double(Bundler::StubSpecification, name: 'aca_entities', source: source) }
    let(:source) { instance_double(Bundler::Source::Git, revision: 'abc123') }

    before do
      # Removes the instance variable before each block to ensure the code is tested correctly with different scenarios.
      GemUtils.remove_instance_variable(:@aca_entities_sha) if GemUtils.instance_variable_defined?(:@aca_entities_sha)

      allow(Bundler).to receive_message_chain(:load, :specs).and_return(mocked_specs)
    end

    context 'when the aca_entities gem is not found' do
      let(:mocked_specs) { [] }

      it 'returns nil' do
        expect(GemUtils.aca_entities_sha).to be_nil
      end
    end

    context 'when the aca_entities gem is found' do
      let(:mocked_specs) { [spec] }

      it 'returns the SHA of the aca_entities gem' do
        expect(GemUtils.aca_entities_sha).to eq('abc123')
      end
    end
  end
end
