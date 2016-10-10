require 'rails_helper'

describe Parsers::Xml::Cv::Importers::IndividualParser do

  context "valid verified_family" do
    let(:xml) { File.read(Rails.root.join("spec", "test_data", "individual_person_payloads", "individual.xml")) }
    let(:subject) { Parsers::Xml::Cv::Importers::IndividualParser.new }

    context "get_person_object" do
      before do
        subject.parse(xml)
      end

      it 'should return the person as an object' do
        expect(subject.get_person_object.class).to eq Person
      end

      it "should get person object with actual person info" do
        person = subject.get_person_object
        expect(person.first_name).to eq "Michael"
        expect(person.middle_name).to eq "J"
        expect(person.last_name).to eq "Hutchins"
      end
    end

    context "get_errors_for_person_object" do
      before do
        subject.parse(xml)
      end

      it "should return an array" do
        expect(subject.get_errors_for_person_object.class).to eq Array
      end
    end
  end
end
