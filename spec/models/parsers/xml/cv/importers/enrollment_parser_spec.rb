require 'rails_helper'

describe Parsers::Xml::Cv::Importers::EnrollmentParser do

  context "valid verified_family" do
    let(:xml) { File.read(Rails.root.join("spec", "test_data", "individual_person_payloads", "IndividualFile.xml")) }
    let(:subject) { Parsers::Xml::Cv::Importers::EnrollmentParser.new }

    context "get_person_object" do
      before do
        subject.parse(xml)
      end

      it 'should return the person as an object' do
        expect(subject.get_person_object.class).to eq Array
        subject.get_person_object.each do |person|
          expect(person.class).to eq Person
        end
      end

      it "should get person object with actual person info" do
        people = subject.get_person_object
        expect(people.first.first_name).to eq "Michael"
        expect(people.first.middle_name).to eq "J"
        expect(people.first.last_name).to eq "Hutchins"
      end
    end

    context "get_errors_for_person_object" do
      before do
        subject.parse(xml)
      end

      it "the size should equal to get_person_object" do
        expect(subject.get_errors_for_person_object.count).to eq subject.get_person_object.count
      end
    end
  end
end
