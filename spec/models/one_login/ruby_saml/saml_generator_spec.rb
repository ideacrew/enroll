require 'rails_helper'

module OneLogin
  RSpec.describe RubySaml::SamlGenerator do
    let(:transaction_id) { '1234' }
    let(:carrier_key) { :kaiser_pay_now }
    let!(:family) { FactoryBot.create(:family, :with_primary_family_member_and_dependent) }
    let!(:issuer_profile) { FactoryBot.create(:benefit_sponsors_organizations_issuer_profile, legal_name: 'Kaiser') }
    let(:product) {FactoryBot.create(:benefit_markets_products_health_products_health_product, benefit_market_kind: :aca_individual, kind: :health, csr_variant_id: '01', issuer_profile: issuer_profile)}
    let!(:hbx_enrollment) { FactoryBot.create(:hbx_enrollment, hbx_id: "123456789", household: family.active_household, aasm_state: 'shopping', family: family, product: product) }
    let!(:hbx_enrollment_member1) { FactoryBot.create(:hbx_enrollment_member, applicant_id: family.primary_applicant.id, is_subscriber: true, eligibility_date: (TimeKeeper.date_of_record - 10.days), hbx_enrollment: hbx_enrollment) }
    let!(:hbx_enrollment_member2) { FactoryBot.create(:hbx_enrollment_member, applicant_id: family.family_members[1].id, eligibility_date: (TimeKeeper.date_of_record - 10.days), hbx_enrollment: hbx_enrollment) }
    let(:saml_generator) { OneLogin::RubySaml::SamlGenerator.new(transaction_id,hbx_enrollment) }
    let(:test_priv_key) { OpenSSL::PKey::RSA.new(File.read(Rails.root.join('spec', 'test_data').to_s + '/test_wfpk.pem')) }
    let(:test_x509_cert) { OpenSSL::X509::Certificate.new(File.read(Rails.root.join('spec', 'test_data').to_s + '/test_x509.pem')) }
    let(:pay_now_double) { double }
    let(:embed_xml_key) { :embed_xml }
    let(:xml_settings_double) { double }

    before :each do
      saml_generator.instance_variable_set(:@private_key, test_priv_key)
      saml_generator.instance_variable_set(:@cert, test_x509_cert)
      hbx_enrollment.update_attributes(kind: 'individual')
      allow(EnrollRegistry).to receive(:[]).and_call_original
      @saml_response = saml_generator.build_saml_response
      @noko = Nokogiri.parse(@saml_response.to_s) do
        XMLSecurity::BaseDocument::NOKOGIRI_OPTIONS
      end
    end

    context 'initilaze saml generator with fileds required' do
      it 'should intialize the fields' do
        expect(saml_generator.transaction_id). to eq transaction_id
        expect(saml_generator.hbx_enrollment). to eq hbx_enrollment
      end
    end

    context 'saml validator' do
      it 'should generate a schema valid payload' do
        result = AcaEntities::Serializers::Xml::PayNow::CareFirst::Operations::ValidatePayNowTransferPayloadSaml.new.call(@saml_response.to_s)
        expect(result.success?).to be_truthy
      end
    end

    context '#build_saml_response' do
      let(:assertion) { 'urn:oasis:names:tc:SAML:2.0:assertion' }
      let(:protocol) { 'urn:oasis:names:tc:SAML:2.0:protocol' }
      let(:name_id_format) { 'urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified' }
      let(:sender_token) { 'urn:oasis:names:tc:SAML:2.0:cm:sendervouches' }
      let(:bearer) { 'urn:oasis:names:tc:SAML:2.0:cm:bearer' }
      let(:password) { 'urn:oasis:names:tc:SAML:2.0:ac:classes:PasswordProtectedTransport' }
      it 'should build return a string with encoded value' do
        expect(@saml_response.class). to eq XMLSecurity::Document
      end

      it 'should generate saml response with version 2.0' do
        expect(@noko.xpath('//samlp:Response').map(&:attributes)[0]['Version'].value).to eq '2.0'
      end

      it 'saml response should contain ID, Issuer Instant and Version attributes present' do
        expect(@noko.xpath('//samlp:Response').map(&:attributes)[0]['ID'].present?).to eq true
        expect(@noko.xpath('//samlp:Response').map(&:attributes)[0]['Version'].present?).to eq true
        expect(@noko.xpath('//samlp:Response').map(&:attributes)[0]['IssueInstant'].present?).to eq true
      end

      it 'should assert valid arguments to Response tag' do
        expect(@noko.xpath('//samlp:Response').first.namespace.href). to eq protocol
      end

      it 'should assert valid arguments to assertion tag' do
        expect(@noko.xpath('//samlp:Response').children[3].namespace.href). to eq assertion
        expect(@noko.xpath('//samlp:Response').children[3].name). to eq 'Assertion'
      end

      it 'assertion should have issuer child node present' do
        assertion = @noko.xpath('//samlp:Response').children[3]
        expect(assertion.children[0].name). to eq 'Issuer'
      end

      it 'name id should have the format and value present' do
        assertion = @noko.xpath('//samlp:Response').children[3]
        subject = assertion.children[1]
        expect(subject.children[0].attributes['Format'].value). to eq name_id_format
        expect(subject.children[0].children.first.text). to eq hbx_enrollment.hbx_id
      end

      it 'root should have signature node present' do
        signature = @noko.xpath('//samlp:Response').children[1]
        expect(signature.name). to eq 'Signature'
        expect(signature.namespace.prefix). to eq 'ds'
        expect(signature.children[0].children[1].attributes['Algorithm'].value.include?("sha256")).to eq true
      end

      it 'should have send BEARER as subject confirmation method' do
        assertion = @noko.xpath('//samlp:Response').children[3]
        expect(assertion.children[1].children[1].attributes['Method'].name).to eq 'Method'
        expect(assertion.children[1].children[1].attributes['Method'].value).to eq bearer
      end

      it 'should sign the assertion and not the response' do
        assertion = @noko.xpath('//samlp:Response').children[3]
        expect(assertion.children.map(&:name)).not_to include('Signature')
        expect(assertion.children[3].children[0].children[0].text).to eq password
      end

      it 'should have payment transaction ID with 13 characters' do
        attr_stmt = @noko.xpath('//samlp:Response').children[3].children[4]
        expect(attr_stmt.children[0].attributes['Name'].value).to eq 'Payment Transaction ID'
        expect(attr_stmt.children[0].children[0].children[0].text.length).to eq 13
      end

      it 'should have aqhp product id as hios id without -' do
        attr_stmt = @noko.xpath('//samlp:Response').children[3].children[4]
        expect(attr_stmt.children[2].attributes['Name'].value).to eq 'Assigned QHP Identifier'
        expect(attr_stmt.children[2].children[0].children[0].text).to eq hbx_enrollment.product.hios_id.gsub('-', '')
      end

      it 'should have street name' do
        attr_stmt = @noko.xpath('//samlp:Response').children[3].children[4]
        expect(attr_stmt.children[10].attributes['Name'].value).to eq 'Street Name 2'
      end

      it 'should have street name' do
        attr_stmt = @noko.xpath('//samlp:Response').children[3].children[4]
        expect(attr_stmt.children[14].attributes['Name'].value).to eq 'Contact Email Address'
      end

      it 'should have subscriber ID' do
        attr_stmt = @noko.xpath('//samlp:Response').children[3].children[4]
        expect(attr_stmt.children[15].attributes['Name'].value).to eq 'Subscriber Identifier'
        expect(attr_stmt.children[15].children[0].children.text).to eq hbx_enrollment.subscriber.hbx_id.rjust(10, '0')
      end

      context 'carrier has embedded custom xml' do
        let(:operation) { instance_double(Operations::PayNow::CareFirst::EmbeddedXml) }
        let(:carrier_key) { :carefirst_pay_now }
        let(:custom_xml) do
          "<coverage_kind>urn:openhbx:terms:v1:qhp_benefit_coverage#health</coverage_kind><primary><exchange_assigned_member_id>12345678</exchange_assigned_member_id>"\
          "<member_name><person_surname>Smith</person_surname><person_given_name>John</person_given_name><person_full_name>John Smith</person_full_name></member_name>"\
          "</primary><members><member><exchange_assigned_member_id>12345678</exchange_assigned_member_id><member_name><person_surname>Smith</person_surname><person_given_name>"\
          "John</person_given_name><person_full_name>John Smith</person_full_name></member_name><birth_date>19860401</birth_date><sex>M</sex><ssn>123456789</ssn><relationship>"\
          "18</relationship><is_subscriber>false</is_subscriber></member></members>"
        end

        before do
          allow(EnrollRegistry).to receive(:[]).with(carrier_key).and_return(pay_now_double)
          allow(pay_now_double).to receive(:setting).with(embed_xml_key).and_return(xml_settings_double)
          allow(xml_settings_double).to receive(:item).and_return(false)
          allow(xml_settings_double).to receive(:item).and_return(true)
          allow(Operations::PayNow::CareFirst::EmbeddedXml).to receive(:new).and_return(operation)
          allow(operation).to receive(:call).and_return(::Dry::Monads::Result::Success.new(custom_xml))
          issuer_profile.update(legal_name: 'CareFirst')
          saml_generator.build_saml_response
        end

        it 'should call the external operation to generate xml' do
          expect(operation).to have_received(:call)
        end

        it 'should generate a schema valid payload' do
          result = AcaEntities::Serializers::Xml::PayNow::CareFirst::Operations::ValidatePayNowTransferPayloadSaml.new.call(@saml_response.to_s)
          expect(result.success?).to be_truthy
        end
      end
    end

    context '#encode_response' do
      it 'should return encoded value with String class' do
        encoded_response = saml_generator.encode_saml_response(@saml_response)
        expect(encoded_response.class). to eq String
      end
    end

    context '#embed_custom_xml?' do
      it 'should retun nil if the carrier does not have the custom xml setting' do
        expect(saml_generator.send(:embed_custom_xml?)).to eq nil
      end
    end
  end
end
