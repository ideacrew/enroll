require 'rails_helper'

describe Parsers::Xml::Cv::Importers::FamilyParser do
  let(:subject) { Parsers::Xml::Cv::Importers::FamilyParser.new(xml) }

  context "valid verified_family" do
    let(:xml) { File.read(Rails.root.join("spec", "test_data", "importer_payloads", "family.xml")) }

    context "get_family_object" do
      it 'should return the family as an object' do
        expect(subject.get_family_object.class).to eq Family
      end

      it "should get e_case_id" do
        expect(subject.get_family_object.e_case_id).to eq "abc123xyz2"
      end

      it "should get family_members" do
        family = subject.get_family_object
        expect(family.family_members.class).to eq Array
      end

      it "should get person info by family_members" do
        person = subject.get_family_object.family_members.first.person
        expect(person.first_name).to eq "Michael"
        expect(person.middle_name).to eq "J"
        expect(person.last_name).to eq "Green"
      end

      it "should get households" do
        family = subject.get_family_object
        expect(family.households.class).to eq Array
      end

      it "should get irs_groups" do
        family = subject.get_family_object
        expect(family.irs_groups.class).to eq Array
      end
    end
  end
end
