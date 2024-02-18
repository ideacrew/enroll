# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FileUploadHelper, type: :helper do
  before do
    allow(helper).to receive(:flash).and_return({})
  end

  describe '#valid_file_upload?' do
    let(:valid_pdf) { fixture_file_upload("#{Rails.root}/test/JavaScript.pdf", 'application/pdf') }
    let(:invalid_pdf) { fixture_file_upload("#{Rails.root}/test/uhic.jpg", 'image/jpeg') }
    let(:invalid_mime_type) { fixture_file_upload("#{Rails.root}/test/fake_sample.docx.jpg", 'image/pdf') }

    context 'with a valid PDF file' do
      it 'returns true' do
        expect(helper.valid_file_upload?(valid_pdf, ['application/pdf'])).to be true
      end
    end

    context 'with an invalid file type' do
      it 'returns false' do
        expect(helper.valid_file_upload?(invalid_pdf, ['application/pdf'])).to be false
      end

      it 'sets a flash error' do
        helper.valid_file_upload?(invalid_pdf, ['application/pdf'])
        expect(flash[:error]).to be_present
      end

    end

    context "detects right mime type" do
      it 'returns false' do
        expect(helper.valid_file_upload?(invalid_mime_type, ['application/pdf'])).to be false
      end
    end

  end
end
