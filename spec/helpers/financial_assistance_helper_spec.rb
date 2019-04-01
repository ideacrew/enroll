require 'rails_helper'

RSpec.describe FinancialAssistanceHelper, :type => :helper do

  describe 'decode_msg' do
    let(:encoded_msg) {'101'}
    let(:wrong_encoded_msg) {'111'}

    context 'when correct message send for decode' do
      it 'should return decoded msg' do
        expect(helper.decode_msg(encoded_msg)).to eq 'faa.acdes_lookup'
      end
    end

    context 'when wrong message send for decode' do
      it 'should return nil' do
        expect(helper.decode_msg(wrong_encoded_msg)).to eq nil
      end
    end
  end
end
