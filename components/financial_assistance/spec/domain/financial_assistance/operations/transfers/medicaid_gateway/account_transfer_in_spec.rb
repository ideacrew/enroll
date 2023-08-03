# frozen_string_literal: true

require 'rails_helper'
require 'aca_entities/serializers/xml/medicaid/atp'
require 'aca_entities/atp/transformers/cv/family'

RSpec.describe ::FinancialAssistance::Operations::Transfers::MedicaidGateway::AccountTransferIn, dbclean: :after_each do
  include Dry::Monads[:result, :do]

  let(:xml_file_path) { ::FinancialAssistance::Engine.root.join('spec', 'shared_examples', 'medicaid_gateway', 'Simple_Test_Case_E_New.xml') }
  let(:xml) do
    Rails.cache.fetch("test_xml_string") do
      File.read(xml_file_path)
    end
  end

  let(:serializer) { ::AcaEntities::Serializers::Xml::Medicaid::Atp::AccountTransferRequest }

  let(:transformer) { ::AcaEntities::Atp::Transformers::Cv::Family }

  context 'success' do
    before do
      ::BenefitMarkets::Locations::CountyZip.create(zip: "04330", state: "ME", county_name: "Kennebec")
      allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).and_call_original
      allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:automatic_submission).and_return(false)
      allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:load_county_on_inbound_transfer).and_return(true)
    end

    context 'with valid payload' do
      before do
        record = serializer.parse(xml)
        @transformed = transformer.transform(record.to_hash(identifier: true))
        @result = subject.call(@transformed)
      end

      it 'should set the transferred_at field' do
        app = FinancialAssistance::Application.find(@result.value!)
        expect(app.transferred_at).not_to eq nil
      end

      context 'load_county_on_inbound_transfer feature is enabled' do
        it 'should return success if zips with county are present in database' do
          expect(@result).to be_success
        end
      end

      context 'load_county_on_inbound_transfer feature is NOT enabled' do
        before do
          allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:load_county_on_inbound_transfer).and_return(false)
          ::BenefitMarkets::Locations::CountyZip.delete_all
        end

        it 'should return success if zips with county are NOT present in database' do
          expect(@result).to be_success
        end
      end

      context "vlp documents" do
        before do
          @category_code = @transformed["family"]["family_members"].first["person"]["consumer_role"]["vlp_documents"].first["subject"]
          @naturalization_number = @transformed["family"]["family_members"].first["person"]["consumer_role"]["vlp_documents"].first["naturalization_number"]
          @alien_number = @transformed["family"]["family_members"].first["person"]["consumer_role"]["vlp_documents"].first["alien_number"]
        end

        it "should populate vlp documents on the consumer role" do
          person = Person.first
          consumer_role = person.consumer_role
          active_vlp_doc = consumer_role.vlp_documents.last
          expect(consumer_role.active_vlp_document_id).to eq active_vlp_doc.id
          expect(active_vlp_doc.subject).to eq(@category_code)
          expect(active_vlp_doc.naturalization_number).to eq(@naturalization_number)
          expect(active_vlp_doc.alien_number).to eq(@alien_number)
        end

        it "should populate vlp documents on the applicant" do
          applicant = FinancialAssistance::Application.first.applicants.first
          expect(applicant.vlp_subject).to eq(@category_code)
          expect(applicant.alien_number).to eq(@alien_number)
          expect(applicant.naturalization_number).to eq(@naturalization_number)
        end
      end

      context 'person ethnicity' do
        it 'should populate person ethnicity using cv3 person demographics ethnicity' do
          person_demographics = @transformed["family"]["family_members"].first["person"]["person_demographics"]
          person = Person.first
          expect(person.ethnicity).to eq person_demographics["ethnicity"]
        end
      end

      context 'language preference' do
        it 'should populate person language preference' do
          person_demographics = @transformed["family"]["family_members"].first["person"]["consumer_role"]
          person = Person.first
          expect(person.consumer_role.language_preference).to match(/#{person_demographics["language_preference"]}/i)
        end
      end

      context 'no ssn' do
        context 'person' do
          it 'should should populate person no_ssn field using transformed cv3 person demographics' do
            person_demographics = @transformed["family"]["family_members"].first["person"]["person_demographics"]
            no_ssn_string = subject.transform_no_ssn(person_demographics["ssn"])
            person = Person.first
            expect(person.no_ssn).to eq no_ssn_string
          end
        end

        context 'applicant' do
          it 'should populate applicant no_ssn field using transformed cv3 person demographics' do
            person_demographics = @transformed["family"]["family_members"].first["person"]["person_demographics"]
            no_ssn_string = subject.transform_no_ssn(person_demographics["ssn"])
            applicant = FinancialAssistance::Application.first.applicants.first
            expect(applicant.no_ssn).to eq no_ssn_string
          end
        end
      end

      context 'with no ethnicity' do
        it 'should have an ethnicity of an empty array rather than a nil' do
          person = Person.last
          expect(person.ethnicity).to eq []
        end
      end

      context 'relationships' do
        before do
          @family_member_rels = Family.first.family_members.map(&:relationship)
          @primary_person_rels = Family.first.primary_person.person_relationships
          @application_rels = FinancialAssistance::Application.first.relationships
        end

        it 'should create the expected family member relationships' do
          expect(@family_member_rels).to eq ["self", "parent", "domestic_partner"]
        end

        it 'should persist the family primary person relationships' do
          expect(@primary_person_rels.map(&:persisted?)).not_to include(false)
        end

        it 'should create the expected application relationships' do
          expect(@application_rels.map(&:kind)).to eq ["child", "domestic_partner", "parent", "domestic_partner"]
        end

        it 'should persist the applicant relationships' do
          expect(@application_rels.map(&:persisted?)).not_to include(false)
        end
      end

      context 'immediate family coverage household' do
        before do
          family = Family.first
          @immediate_family_members = family.family_members.select { |member| Family::IMMEDIATE_FAMILY.include?(member.primary_relationship) }
          @immediate_family_coverage_household_members = family.active_household.immediate_family_coverage_household.valid_coverage_household_members
        end

        it 'should add all immediate family members as valid coverage household members' do
          expect(@immediate_family_coverage_household_members.map(&:family_member_id)).to eq @immediate_family_members.map(&:id)
        end
      end

      context 'invalid phone number' do
        context 'where the phone number starts with 0' do

          it 'should drop the invalid phone number for the person' do
            person = Person.first
            has_invalid_phone = person.phones.any? do |p|
              p.area_code == '000' || p.full_phone_number == '0000000000'
            end

            expect(has_invalid_phone).to eq false
          end

          it 'should drop the invalid phone number for the applicant' do
            application = FinancialAssistance::Application.last
            has_invalid_phone = application.applicants.any? do |a|
              a.phones.detect { |p| p.area_code == '000' || p.full_phone_number == '0000000000' }
            end

            expect(has_invalid_phone).to eq false
          end
        end
      end

      context 'valid attestations' do
        it 'should create valid attestations for the application' do
          attributes = @transformed["family"]['magi_medicaid_applications'].first
          application = FinancialAssistance::Application.find(@result.value!)
          attestation_vals = { "submission_terms": attributes["submission_terms"],
                               "medicaid_terms": attributes["medicaid_terms"],
                               "medicaid_insurance_collection_terms": attributes["medicaid_insurance_collection_terms"],
                               "parent_living_out_of_home_terms": attributes["parent_living_out_of_home_terms"],
                               "report_change_terms": attributes["report_change_terms"],
                               "attestation_terms": attributes["attestation_terms"] }

          attributes = attestation_vals.keys.map { |name| [name, application.attributes[name]] }.to_h
          expect(attributes).to eq attestation_vals
        end
      end
    end
  end

  context 'failure' do
    context 'load_county_on_inbound_transfer feature is enabled' do
      context 'with no counties loaded in database' do
        context 'with all addressess missing counties' do
          before do
            allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).and_call_original
            allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:automatic_submission).and_return(false)
            allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:load_county_on_inbound_transfer).and_return(true)
            missing_counties_xml = Nokogiri::XML(xml)
            missing_counties_xml.xpath("//ns3:LocationCountyName", { "ns3" => "http://niem.gov/niem/niem-core/2.0" }).remove
            record = serializer.parse(missing_counties_xml)
            transformed = transformer.transform(record.to_hash(identifier: true)).deep_stringify_keys!
            @result = subject.call(transformed)
          end

          it 'should return failure' do
            expect(@result).to eq(Failure("Unable to find county objects for zips [\"04330\"]"))
          end
        end
      end
    end
  end

  describe '#load_missing_county_names' do
    before do
      ::BenefitMarkets::Locations::CountyZip.create(zip: "04330", state: "ME", county_name: "Kennebec")
      missing_counties_xml = Nokogiri::XML(xml)
      missing_counties_xml.xpath("//ns3:LocationCountyName", { "ns3" => "http://niem.gov/niem/niem-core/2.0" }).remove
      record = serializer.parse(missing_counties_xml)
      @transformed = transformer.transform(record.to_hash(identifier: true)).deep_stringify_keys!
    end

    context 'zip matches exactly one county in database' do
      before do
        person_county_name = @transformed["family"]["family_members"].first["person"]["addresses"].first["county"]
        applicant_county_name = @transformed["family"]["magi_medicaid_applications"].first["applicants"].first["addresses"].first["county"]
        expect(person_county_name).to eq(nil)
        expect(applicant_county_name).to eq(nil)
        subject.load_missing_county_names(@transformed)
      end

      it 'should load missing county name for person addresses' do
        loaded_county_name = @transformed["family"]["family_members"].first["person"]["addresses"].first["county"]
        expect(loaded_county_name).to eq("Kennebec")
      end

      it 'should load missing county name for applicant addresses' do
        loaded_county_name = @transformed["family"]["magi_medicaid_applications"].first["applicants"].first["addresses"].first["county"]
        expect(loaded_county_name).to eq("Kennebec")
      end
    end

    context 'when matches more than one county' do
      before do
        ::BenefitMarkets::Locations::CountyZip.create(zip: "04330", state: "ME", county_name: "Kennebec")
        person_county_name = @transformed["family"]["family_members"].first["person"]["addresses"].first["county"]
        applicant_county_name = @transformed["family"]["magi_medicaid_applications"].first["applicants"].first["addresses"].first["county"]
        expect(person_county_name).to eq(nil)
        expect(applicant_county_name).to eq(nil)
        subject.load_missing_county_names(@transformed)
      end

      it 'should load missing county name for person addresses' do
        loaded_county_name = @transformed["family"]["family_members"].first["person"]["addresses"].first["county"]
        expect(loaded_county_name).to eq("Kennebec")
      end

      it 'should load missing county name for applicant addresses' do
        loaded_county_name = @transformed["family"]["magi_medicaid_applications"].first["applicants"].first["addresses"].first["county"]
        expect(loaded_county_name).to eq("Kennebec")
      end
    end
  end
end
