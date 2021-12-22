# frozen_string_literal: true

require 'rails_helper'
require 'aca_entities/serializers/xml/medicaid/atp'
require 'aca_entities/atp/transformers/cv/family'

RSpec.describe ::FinancialAssistance::Operations::Transfers::MedicaidGateway::AccountTransferIn, dbclean: :after_each do
  include Dry::Monads[:result, :do]

  let(:xml) { File.read(::FinancialAssistance::Engine.root.join('spec', 'shared_examples', 'medicaid_gateway', 'Simple_Test_Case_E_New.xml')) }

  let(:serializer) { ::AcaEntities::Serializers::Xml::Medicaid::Atp::AccountTransferRequest }

  let(:transformer) { ::AcaEntities::Atp::Transformers::Cv::Family }

  context 'success' do
    before do
      ::BenefitMarkets::Locations::CountyZip.create(zip: "04330", state: "ME", county_name: "Kennebec")
    end

    context 'with valid payload' do
      before do
        record = serializer.parse(xml)
        @transformed = transformer.transform(record.to_hash(identifier: true))
        @result = subject.call(@transformed)
      end

      it 'should return success if zips are present in database' do
        expect(@result).to be_success
      end

      context 'person ethnicity' do
        it 'should populate person ethnicity using cv3 person demographics ethnicity' do
          person_demographics = @transformed["family"]["family_members"].first["person"]["person_demographics"]
          person = Person.first
          expect(person.ethnicity).to eq person_demographics["ethnicity"]
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
    end
  end

  context 'failure' do
    context 'with counties not matching those present in database' do
      before do
        record = serializer.parse(xml)
        transformed = transformer.transform(record.to_hash(identifier: true))
        @result = subject.call(transformed)
      end

      it 'should return failure if no zips are present' do
        expect(@result).to eq(Failure("Unable to find county objects for zips [\"04330\"]"))
      end
    end

    context 'with zip code matching multiple counties' do
      before do
        ::BenefitMarkets::Locations::CountyZip.create(zip: "04930", state: "ME", county_name: "Somerset")
        ::BenefitMarkets::Locations::CountyZip.create(zip: "04930", state: "ME", county_name: "Somerset")
        duplicate_zip_counties_xml = Nokogiri::XML(xml)
        duplicate_zip_counties_xml.xpath("//ns3:LocationPostalCode", {"ns3" => "http://niem.gov/niem/niem-core/2.0"}).each {|node| node.content = "04930"}
        record = serializer.parse(duplicate_zip_counties_xml)
        transformed = transformer.transform(record.to_hash(identifier: true))
        @result = subject.call(transformed)
      end

      it 'should return failure if zip code matches multiple counties' do
        expect(@result).to eq(Failure("Unable to match county for [\"04930\"], as multiple counties have this zip code."))
      end
    end
  end

  describe '#load_missing_county_names' do
    before do
      ::BenefitMarkets::Locations::CountyZip.create(zip: "04330", state: "ME", county_name: "Kennebec")
      missing_counties_xml = Nokogiri::XML(xml)
      missing_counties_xml.xpath("//ns3:LocationCountyName", {"ns3" => "http://niem.gov/niem/niem-core/2.0"}).remove
      record = serializer.parse(missing_counties_xml)
      @transformed = transformer.transform(record.to_hash(identifier: true)).deep_stringify_keys!
    end

    it 'should load missing county name if zip matches exactly one county in database' do
      county_name = @transformed["family"]["family_members"].first["person"]["addresses"].first["county"]
      expect(county_name).to eq(nil)

      subject.load_missing_county_names(@transformed)
      loaded_county_name = @transformed["family"]["family_members"].first["person"]["addresses"].first["county"]
      expect(loaded_county_name).to eq("Kennebec")
    end
  end
end
