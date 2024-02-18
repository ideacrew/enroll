# frozen_string_literal: true

require 'rails_helper'

class SanitizeConcernTestClass
  include SanitizeConcern
end

describe SanitizeConcernTestClass, type: :model do
  describe '#sanitize' do
    context 'when the value is a string' do
      context 'when the value contains img tag' do
        let(:input_value) { "<img src=x onerror=alert('NHBR');> Lastname" }

        it 'returns the sanitized value' do
          expect(subject.sanitize(input_value)).to eq(' Lastname')
        end
      end

      context 'when the value contains script tag' do
        let(:input_value) { "<script>alert('NHBR');</script> Lastname" }

        it 'returns the sanitized value' do
          expect(subject.sanitize(input_value)).to eq(' Lastname')
        end
      end

      context 'when the value contains other HTML tags' do
        let(:input_value) { "<div>Firstname</div> Lastname" }

        it 'returns the sanitized value' do
          expect(subject.sanitize(input_value)).to eq('Firstname Lastname')
        end
      end

      context 'when the value contains iframe tag' do
        let(:input_value) { "<iframe src='https://www.google.com' title='A search Engine'></iframe> Lastname" }

        it 'returns the sanitized value' do
          expect(subject.sanitize(input_value)).to eq(' Lastname')
        end
      end
    end

    context 'when the value is not a string' do
      it 'returns the original value' do
        expect(subject.sanitize(123)).to eq(123)
      end
    end
  end
end
