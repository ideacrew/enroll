# frozen_string_literal: true

class TestingScrubber
  extend StringScrubberUtil
end

RSpec.describe StringScrubberUtil do
  describe '#sanitize_to_hex' do
    it 'removes non-hexadecimal characters from the string' do
      expect(TestingScrubber.sanitize_to_hex('123abcXYZxyz')).to eq('123abc')
    end

    it 'returns an empty string when there are no hexadecimal characters' do
      expect(TestingScrubber.sanitize_to_hex('XYZ')).to eq('')
    end

    it 'does not change the string when all characters are hexadecimal' do
      expect(TestingScrubber.sanitize_to_hex('123abc')).to eq('123abc')
    end

    it 'returns an empty string when the input is nil' do
      expect(TestingScrubber.sanitize_to_hex(nil)).to eq('')
    end

    it 'removes special characters from the string' do
      expect(TestingScrubber.sanitize_to_hex('123abc!@#$%^&*()')).to eq('123abc')
    end

    it 'prevents script injection by removing non-hexadecimal characters' do
      expect(TestingScrubber.sanitize_to_hex('<script>alert("123abc")</script>')).to eq('cae123abcc')
    end

    it 'does not alter a valid BSON::ObjectId' do
      object_id = BSON::ObjectId.new
      expect(TestingScrubber.sanitize_to_hex(object_id.to_s)).to eq(object_id.to_s)
    end
  end
end
