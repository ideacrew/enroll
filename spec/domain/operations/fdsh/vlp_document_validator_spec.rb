RSpec.describe Operations::Fdsh::VlpDocumentValidator do
  let(:validator) { described_class.new }

  describe '#call' do
    let!(:vlp_document_hash) do
      {:subject => nil,
       :alien_number => nil,
       :i94_number => nil,
       :visa_number => nil,
       :passport_number => nil,
       :sevis_id => nil,
       :naturalization_number => nil,
       :receipt_number => nil,
       :citizenship_number => nil,
       :card_number => nil,
       :country_of_citizenship => nil,
       :expiration_date => nil,
       :issuing_country => nil}
    end

    context 'subject: I-327 (Reentry Permit)' do
      context 'when given a valid document entity' do
        let(:document_entity) do
          Entities::VlpDocument.new(vlp_document_hash.merge!({'subject' => 'I-327 (Reentry Permit)','alien_number' => '123456789'}))
        end

        it 'returns a success result' do
          result = validator.call(document_entity)
          expect(result).to be_success
        end
      end

      context 'when given an invalid document entity' do
        let(:document_entity) do
          Entities::VlpDocument.new(vlp_document_hash.merge!({'subject' => 'I-327 (Reentry Permit)'}))
        end

        it 'returns a failure result' do
          result = validator.call(document_entity)
          expect(result).to be_failure
        end

        it 'returns an error message' do
          result = validator.call(document_entity)
          expect(result.failure).to eq('Missing information for document type I-327 (Reentry Permit): alien_number')
        end
      end
    end

    context 'subject: I-551 (Permanent Resident Card)' do
      context 'when given a valid document entity' do
        let(:document_entity) do
          Entities::VlpDocument.new(vlp_document_hash.merge!({
                                                               'subject' => 'I-766 (Employment Authorization Card)',
                                                               'alien_number' => '123456789',
                                                               'receipt_number' => '987654321'
                                                             }))
        end

        it 'returns a success result' do
          result = validator.call(document_entity)
          expect(result).to be_success
        end
      end

      context 'when given an invalid document entity' do
        let(:document_entity) do
          Entities::VlpDocument.new(vlp_document_hash.merge!({'subject' => 'I-766 (Employment Authorization Card)','alien_number' => '123456789'}))
        end

        it 'returns a failure result' do
          result = validator.call(document_entity)
          expect(result).to be_failure
        end

        it 'returns an error message' do
          result = validator.call(document_entity)
          expect(result.failure).to eq('Missing information for document type I-766 (Employment Authorization Card): receipt_number')
        end
      end
    end

    context 'when given a Certificate of Citizenship document entity' do
      let(:document_entity) do
        Entities::VlpDocument.new(vlp_document_hash.merge!({'subject' => 'Certificate of Citizenship','citizenship_number' => '123456789'}))
      end

      it 'returns a success result' do
        result = validator.call(document_entity)
        expect(result).to be_success
      end
    end

    context 'when given a Naturalization Certificate document entity' do
      let(:document_entity) do
        Entities::VlpDocument.new(vlp_document_hash.merge!({
                                                             'subject' => 'Naturalization Certificate',
                                                             'naturalization_number' => '123456789'
                                                           }))
      end

      it 'returns a success result' do
        result = validator.call(document_entity)
        expect(result).to be_success
      end
    end

    context 'when given a Machine Readable Immigrant Visa document entity' do
      let(:document_entity) do
        Entities::VlpDocument.new(vlp_document_hash.merge!({
                                                             'subject' => 'Machine Readable Immigrant Visa (with Temporary I-551 Language)',
                                                             'alien_number' => '123456789',
                                                             'passport_number' => '987654321',
                                                             'country_of_citizenship' => 'USA'
                                                           }))
      end

      it 'returns a success result' do
        result = validator.call(document_entity)
        expect(result).to be_success
      end
    end

    context 'when given a Temporary I-551 Stamp document entity' do
      let(:document_entity) do
        Entities::VlpDocument.new(vlp_document_hash.merge!({
                                                             'subject' => 'Temporary I-551 Stamp (on passport or I-94)',
                                                             'alien_number' => '123456789'
                                                           }))
      end

      it 'returns a success result' do
        result = validator.call(document_entity)
        expect(result).to be_success
      end
    end

    context 'when given an I-94 document entity' do
      let(:document_entity) do
        Entities::VlpDocument.new(vlp_document_hash.merge!({
                                                             'subject' => 'I-94 (Arrival/Departure Record)',
                                                             'i94_number' => '123456789'
                                                           }))
      end

      it 'returns a success result' do
        result = validator.call(document_entity)
        expect(result).to be_success
      end
    end

    context 'when given an I-94 in Unexpired Foreign Passport document entity' do
      let(:document_entity) do
        Entities::VlpDocument.new(vlp_document_hash.merge!({
                                                             'subject' => 'I-94 (Arrival/Departure Record) in Unexpired Foreign Passport',
                                                             'i94_number' => '123456789',
                                                             'passport_number' => '987654321',
                                                             'country_of_citizenship' => 'USA',
                                                             'expiration_date' => Date.today + 90.days
                                                           }))
      end

      it 'returns a success result' do
        result = validator.call(document_entity)
        expect(result).to be_success
      end
    end

    context 'when given an Unexpired Foreign Passport document entity' do
      let(:document_entity) do
        Entities::VlpDocument.new(vlp_document_hash.merge!({
                                                             'subject' => 'Unexpired Foreign Passport',
                                                             'passport_number' => '987654321',
                                                             'country_of_citizenship' => 'USA',
                                                             'expiration_date' => Date.today + 90.days
                                                           }))
      end

      it 'returns a success result' do
        result = validator.call(document_entity)
        expect(result).to be_success
      end
    end

    context 'when given an I-20 document entity' do
      let(:document_entity) do
        Entities::VlpDocument.new(vlp_document_hash.merge!({
                                                             'subject' => 'I-20 (Certificate of Eligibility for Nonimmigrant (F-1) Student Status)',
                                                             'sevis_id' => '123456789'
                                                           }))
      end

      it 'returns a success result' do
        result = validator.call(document_entity)
        expect(result).to be_success
      end
    end

    context 'when given a DS2019 document entity' do
      let(:document_entity) do
        Entities::VlpDocument.new(vlp_document_hash.merge!({
                                                             'subject' => 'DS2019 (Certificate of Eligibility for Exchange Visitor (J-1) Status)',
                                                             'sevis_id' => '123456789'
                                                           }))
      end

      it 'returns a success result' do
        result = validator.call(document_entity)
        expect(result).to be_success
      end
    end

    context 'when given an Other (With Alien Number) document entity' do
      let(:document_entity) do
        Entities::VlpDocument.new(vlp_document_hash.merge!({
                                                             'subject' => 'Other (With Alien Number)',
                                                             'alien_number' => '123456789'
                                                           }))
      end

      it 'returns a success result' do
        result = validator.call(document_entity)
        expect(result).to be_success
      end
    end

    context 'when given an Other (With I-94 Number) document entity' do
      let(:document_entity) do
        Entities::VlpDocument.new(vlp_document_hash.merge!({
                                                             'subject' => 'Other (With I-94 Number)',
                                                             'i94_number' => '123456789'
                                                           }))
      end

      it 'returns a success result' do
        result = validator.call(document_entity)
        expect(result).to be_success
      end
    end

    context 'when given an invalid document type' do
      let(:document_entity) do
        Entities::VlpDocument.new(vlp_document_hash.merge!({
                                                             'subject' => 'Test 1234',
                                                             'i94_number' => '123456789'
                                                           }))
      end

      it 'returns a failure result' do
        result = validator.call(document_entity)
        expect(result).to be_failure
      end

      it 'returns an error message' do
        result = validator.call(document_entity)
        expect(result.failure).to eq('Invalid document type: Test 1234')
      end
    end
  end
end