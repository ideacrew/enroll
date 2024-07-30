# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Validators::HbxEnrollments::FindContract, type: :model do
  describe '#call' do
    context 'with hbx_id' do
      it 'validates the datatype' do
        result = subject.call(hbx_id: '123456789012345')
        expect(result.errors.to_h).to be_empty
        expect(result.to_h).to eq(hbx_id: '123456789012345')
      end

      it 'fails validation when datatype is incorrect' do
        result = subject.call(hbx_id: 87_834_876_473)
        expect(result.errors.to_h[:hbx_id]).to eq(['must be a string', 'size must be within 1 - 15'])
      end

      it 'fails validation when size is not in range' do
        result = subject.call(hbx_id: '1234567890123456')
        expect(result.errors.to_h[:hbx_id]).to eq(['length must be within 1 - 15'])
      end

      it 'fails validation when format is incorrect' do
        result = subject.call(hbx_id: '1234567890abcd')
        expect(result.errors.to_h[:hbx_id]).to eq(['is in invalid format'])
      end
    end

    context 'with id' do
      it 'validates the datatype' do
        result = subject.call(id: '4d7a457f4d345b7a8a9b0c1d')
        expect(result.errors.to_h).to be_empty
        expect(result.to_h).to eq(id: '4d7a457f4d345b7a8a9b0c1d')
      end

      it 'fails validation when datatype is incorrect' do
        result = subject.call(id: 8_924_768_267_843_374)
        expect(result.errors.to_h[:id]).to eq(['must be a string', 'size must be 24'])
      end

      it 'fails validation when size is not in range' do
        result = subject.call(id: '4d7a457f4d345b7a8a9b0c1d2e')
        expect(result.errors.to_h[:id]).to eq(['length must be 24'])
      end

      it 'fails validation when format is incorrect' do
        result = subject.call(id: '4d7a457f4d345b7a8a9b0c1g')
        expect(result.errors.to_h[:id]).to eq(['is in invalid format'])
      end
    end

    context 'with external_id' do
      it 'validates the datatype' do
        result = subject.call(external_id: '123abc')
        expect(result.errors.to_h).to be_empty
        expect(result.to_h).to eq(external_id: '123abc')
      end

      it 'fails validation when datatype is incorrect' do
        result = subject.call(external_id: 23_876_273_838)
        expect(result.errors.to_h[:external_id]).to eq(['must be a string'])
      end

      it 'fails validation when format is incorrect' do
        result = subject.call(external_id: '123-abc')
        expect(result.errors.to_h[:external_id]).to eq(['is in invalid format'])
      end
    end
  end
end
