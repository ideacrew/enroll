# frozen_string_literal: true

require 'rails_helper'
require File.join(Rails.root, 'spec', 'support', 'acapi_vocabulary_spec_helpers')

if ExchangeTestingConfigurationHelper.individual_market_is_enabled?
  RSpec.describe 'events/lawful_presence/vlp_verification_request.xml.haml' do
    include AcapiVocabularySpecHelpers
    let!(:individual) { FactoryBot.build_stubbed :generative_individual }

    (1..15).to_a.each do |rnd|
      describe "given a generated individual, round #{rnd}" do

        before(:all) do
          download_vocabularies
        end

        before :each do
          render :template => 'events//lawful_presence/vlp_verification_request.xml', :locals => { :individual => individual, :coverage_start_date => Time.zone.today }
        end

        it 'should be schema valid' do
          expect(validate_with_schema(Nokogiri::XML(rendered))).to eq []
        end
      end
    end

    context 'document type: I551' do
      let!(:i551_vlp_document) do
        vlp_doc = FactoryBot.build(:vlp_document,
                                   subject: 'I-551 (Permanent Resident Card)',
                                   card_number: 'card_number00',
                                   receipt_number: 'receipt_numbr')
        individual.consumer_role.vlp_documents << vlp_doc
        individual.consumer_role.vlp_documents.map(&:save!)
        individual.consumer_role.vlp_documents.last
      end

      before do
        render :template => 'events/lawful_presence/vlp_verification_request.xml', :locals => { :individual => individual, :coverage_start_date => Time.zone.today }
      end

      it 'should be schema valid' do
        expect(validate_with_schema(Nokogiri::XML(rendered))).to be_empty
      end

      it 'should set value for element document_I551_receipt_number' do
        expect(rendered).to include('<document_I551_receipt_number>card_number00</document_I551_receipt_number>')
      end

      it 'should not set the value of receipt_number to the element document_I551_receipt_number' do
        expect(rendered).not_to include('<document_I551_receipt_number>receipt_numbr</document_I551_receipt_number>')
      end
    end
  end
end
