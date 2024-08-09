# frozen_string_literal: true

require 'rails_helper'
require 'bundler'
require 'gem_utils'

RSpec.describe GemUtils do
  describe '.aca_entities_sha' do
    let(:spec) { instance_double(Bundler::StubSpecification, name: 'aca_entities', source: source) }
    let(:source) { instance_double(Bundler::Source::Git, revision: 'abc123') }

    before do
      allow(Bundler).to receive_message_chain(:load, :specs).and_return([spec])
    end

    it 'returns the SHA of the aca_entities gem' do
      expect(GemUtils.aca_entities_sha).to eq('abc123')
    end

    context 'when the aca_entities gem is not found' do
      before do
        allow(Bundler).to receive_message_chain(:load, :specs).and_return([])
      end

      it 'returns nil' do
        expect(GemUtils.aca_entities_sha).to be_nil
      end
    end
  end
end
