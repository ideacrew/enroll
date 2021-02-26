# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'components/financial_assistance/app/views/financial_assistance/events/lawful_presence/_immigration_information.xml.haml' do
  context 'conditional data elements' do

    let!(:application) do
      FactoryBot.create(:application,
                        family_id: BSON::ObjectId.new,
                        aasm_state: 'draft',
                        effective_date: Date.today)
    end
    let!(:applicant) do
      FactoryBot.create(:applicant,
                        application: application,
                        dob: Date.today - 40.years,
                        is_primary_applicant: true,
                        family_member_id: BSON::ObjectId.new)
    end

    context 'document_I766' do
      before :each do
        applicant.update_attributes({vlp_subject: 'I-766 (Employment Authorization Card)',
                                     alien_number: '1234567890',
                                     card_number: 'car1234567890',
                                     expiration_date: Date.today})
        result = render 'financial_assistance/events/lawful_presence/immigration_information', applicant: applicant
        parsed_result = Nokogiri.parse(result.to_s)
        i766_element = parsed_result.children.first.children.detect{|child| child.name == 'documents'}.children.detect{|chil| chil.name == 'document_I766'}
        @i766_children = i766_element.children.map(&:name)
      end

      it 'should include receipt_number as one of the children' do
        expect(@i766_children).to include('receipt_number')
      end

      it 'should include expiration_date as one of the children' do
        expect(@i766_children).to include('expiration_date')
      end
    end

    context 'document_mac_read_I551' do
      before :each do
        applicant.update_attributes({vlp_subject: 'Machine Readable Immigrant Visa (with Temporary I-551 Language)',
                                     alien_number: '1234567890',
                                     passport_number: '123456'})
        result = render 'financial_assistance/events/lawful_presence/immigration_information', applicant: applicant
        parsed_result = Nokogiri.parse(result.to_s)
        document_mac_read_i551 = parsed_result.children.first.children.detect{|child| child.name == 'documents'}.children.detect{|chil| chil.name == 'document_mac_read_I551'}
        @document_mac_read_i551_children = document_mac_read_i551.children.map(&:name)
      end

      it 'should include issuing_country as one of the children' do
        expect(@document_mac_read_i551_children).to include('issuing_country')
      end

      it 'should include passport_number as one of the children' do
        expect(@document_mac_read_i551_children).to include('passport_number')
      end

      it 'should include expiration_date as one of the children' do
        expect(@document_mac_read_i551_children).to include('expiration_date')
      end
    end

    context 'document_foreign_passport_I94' do
      before :each do
        applicant.update_attributes({vlp_subject: 'I-94 (Arrival/Departure Record) in Unexpired Foreign Passport',
                                     i94_number: '1234567890',
                                     expiration_date: Date.today,
                                     passport_number: '123456'})
        result = render 'financial_assistance/events/lawful_presence/immigration_information', applicant: applicant
        parsed_result = Nokogiri.parse(result.to_s)
        document_foreign_passport_i94 = parsed_result.children.first.children.detect{|child| child.name == 'documents'}.children.detect{|chil| chil.name == 'document_foreign_passport_I94'}
        @document_foreign_passport_i94_children = document_foreign_passport_i94.children.map(&:name)
      end

      it 'should include issuing_country as one of the children' do
        expect(@document_foreign_passport_i94_children).to include('issuing_country')
      end

      it 'should include passport_number as one of the children' do
        expect(@document_foreign_passport_i94_children).to include('passport_number')
      end

      it 'should include expiration_date as one of the children' do
        expect(@document_foreign_passport_i94_children).to include('expiration_date')
      end
    end

    context 'document_foreign_passport' do
      before :each do
        applicant.update_attributes({vlp_subject: 'Unexpired Foreign Passport',
                                     i94_number: '1234567890',
                                     expiration_date: Date.today,
                                     passport_number: '123456'})
        result = render 'financial_assistance/events/lawful_presence/immigration_information', applicant: applicant
        parsed_result = Nokogiri.parse(result.to_s)
        document_foreign_passport = parsed_result.children.first.children.detect{|child| child.name == 'documents'}.children.detect{|chil| chil.name == 'document_foreign_passport'}
        @document_foreign_passport_children = document_foreign_passport.children.map(&:name)
      end

      it 'should include issuing_country as one of the children' do
        expect(@document_foreign_passport_children).to include('issuing_country')
      end

      it 'should include passport_number as one of the children' do
        expect(@document_foreign_passport_children).to include('passport_number')
      end

      it 'should include expiration_date as one of the children' do
        expect(@document_foreign_passport_children).to include('expiration_date')
      end
    end
  end
end
