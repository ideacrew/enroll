require 'rails_helper'

describe Parsers::Xml::Cv::Importers::EnrollmentParser do
  let(:subject) { Parsers::Xml::Cv::Importers::EnrollmentParser.new(xml) }

  context "valid verified_policy" do
    let(:xml) { File.read(Rails.root.join("spec", "test_data", "importer_payloads", "policy.xml")) }

    context "get_enrollment_object" do
      it 'should return the enrollment as an object' do
        expect(subject.get_enrollment_object.class).to eq HbxEnrollment
      end

      it "should be individual" do
        expect(subject.get_enrollment_object.kind).to eq 'individual'
      end

      it "should get plan" do
        plan = subject.get_enrollment_object.plan
        expect(plan.name).to eq "BluePreferred PPO $1,000 100%/80%"
        expect(plan.active_year).to eq 2016
        expect(plan.ehb).to eq 91.2
        expect(plan.metal_level).to eq 'gold'
        expect(plan.coverage_kind).to eq "health_and_dental"
      end
    end
  end
end
