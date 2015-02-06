require 'rails_helper'

RSpec.describe Factories::EnrollmentFactory, type: :model do
  
  describe "with a person initialized" do
    it "should have a person initialized" do
      person = FactoryGirl.build(:person)
      subject = Factories::EnrollmentFactory.new(person)
      expect(subject.person).to eq person
    end
  end
  
  describe Factories::EnrollmentFactory, '#add_consumer_role' do
    it 'returns the consumer' do
      person = FactoryGirl.build(:person)
      consumer = FactoryGirl.build(:consumer)
      consumer.application_state = "enrollment_closed"
      subject = Factories::EnrollmentFactory.new(person)
      consumer_role = subject.add_consumer_role('1111111111', "01/01/1980", 'male', 'yes', 'yes', 'yes', 'citizen')
      expect(consumer_role.ssn).to eq consumer.ssn
      expect(consumer_role.dob).to eq consumer.dob
    end
  end
  
  
    describe Factories::EnrollmentFactory, '#add_broker_role' do
    it 'returns the broker' do
      person = FactoryGirl.build(:person)
      broker = FactoryGirl.build(:broker)
      subject = Factories::EnrollmentFactory.new(person)
      
      broker_role = subject.add_broker_role('broker', 'abx123xyz', FactoryGirl.build(:address))
      expect(broker_role.npn).to eq consumer.npn
      expect(broker_role.kind).to eq consumer.kind
    end
  end
  
  
end