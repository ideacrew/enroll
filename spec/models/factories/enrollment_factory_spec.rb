require 'rails_helper'
require 'factories/enrollment_factory'

RSpec.describe EnrollmentFactory do
  let(:employer) {FactoryGirl.create(:employer)}
  let(:employee_family) {FactoryGirl.create(:employer_census_employee_family)}
  let(:person) {FactoryGirl.build(:person)}
  let(:ssn) {"123456789"}
  let(:gender) {"male"}
  let(:dob) {"01/01/1970"}
  let(:hired_on) {"01/01/2014"}
  let(:valid_params) do
    { person: person,
      employer: employer,
      ssn: ssn,
      gender: gender,
      dob: dob,
      hired_on: hired_on
    }
  end

  describe ".add_employee_role" do
    context "with no arguments" do
      let(:params) {{}}
      it "should raise" do
        expect{EnrollmentFactory.add_employee_role(**params)}.to raise_error(ArgumentError)
      end
    end

    context "with no person" do
      let(:params) {valid_params.except(:person)}
      it "should raise" do
        expect{EnrollmentFactory.add_employee_role(**params)}.to raise_error(ArgumentError)
      end
    end

    context "with no employer" do
      let(:params) {valid_params.except(:employer)}
      it "should raise" do
        expect{EnrollmentFactory.add_employee_role(**params)}.to raise_error(ArgumentError)
      end
    end

    context "with no date of hire" do
      let(:params) {valid_params.except(:hired_on)}
      it "should raise" do
        expect{EnrollmentFactory.add_employee_role(**params)}.to raise_error(ArgumentError)
      end
    end

    context "with no date of birth" do
      let(:params) {valid_params.except(:dob)}
      it "should raise" do
        expect{EnrollmentFactory.add_employee_role(**params)}.to raise_error(ArgumentError)
      end
    end

    context "with no gender" do
      let(:params) {valid_params.except(:gender)}
      it "should raise" do
        expect{EnrollmentFactory.add_employee_role(**params)}.to raise_error(ArgumentError)
      end
    end

    context "with no ssn" do
      let(:params) {valid_params.except(:ssn)}
      it "should raise" do
        expect{EnrollmentFactory.add_employee_role(**params)}.to raise_error(ArgumentError)
      end
    end

    context "with all required data" do
      let(:params) {valid_params}
      it "should not raise" do
        expect{EnrollmentFactory.add_employee_role(**params)}.not_to raise_error
      end
    end

  end
  # describe "with a person initialized" do
  #   it "should have a person initialized" do
  #     person = FactoryGirl.build(:person)
  #     subject = Factories::EnrollmentFactory.new(person)
  #     expect(subject.person).to eq person
  #   end
  # end

  # describe Factories::EnrollmentFactory, '#add_consumer_role' do
  #   it 'returns the consumer' do
  #     person = FactoryGirl.build(:person)
  #     consumer = FactoryGirl.build(:consumer)
  #     consumer.application_state = "enrollment_closed"
  #     subject = Factories::EnrollmentFactory.new(person)
  #     consumer_role = subject.add_consumer_role('1111111111', "01/01/1980", 'male', 'yes', 'yes', 'yes', 'citizen')
  #     expect(consumer_role.ssn).to eq consumer.ssn
  #     expect(consumer_role.dob).to eq consumer.dob
  #   end
  # end


  #   describe Factories::EnrollmentFactory, '#add_broker_role' do
  #   it 'returns the broker' do
  #     person = FactoryGirl.build(:person)
  #     broker = FactoryGirl.build(:broker)
  #     subject = Factories::EnrollmentFactory.new(person)
  #
  #     broker_role = subject.add_broker_role('broker', 'abx123xyz', FactoryGirl.build(:address))
  #     expect(broker_role.npn).to eq consumer.npn
  #     expect(broker_role.kind).to eq consumer.kind
  #   end
  # end


end
