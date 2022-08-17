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

      it 'should set the transferred_at field'  do
        app = FinancialAssistance::Application.find(@result.value!)
        expect(app.transferred_at).not_to eq nil
      end
    end
  end

  context 'failure' do
    context 'with no counties loaded in database' do
      context 'with all addressess missing counties' do
        before do
          missing_counties_xml = Nokogiri::XML(xml)
          missing_counties_xml.xpath("//ns3:LocationCountyName", {"ns3" => "http://niem.gov/niem/niem-core/2.0"}).remove
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

  describe '#load_missing_county_names' do
    before do
      ::BenefitMarkets::Locations::CountyZip.create(zip: "04330", state: "ME", county_name: "Kennebec")
      missing_counties_xml = Nokogiri::XML(xml)
      missing_counties_xml.xpath("//ns3:LocationCountyName", {"ns3" => "http://niem.gov/niem/niem-core/2.0"}).remove
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
