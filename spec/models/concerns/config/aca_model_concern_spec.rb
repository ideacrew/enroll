require "rails_helper"

class TestAcaModelConcernClass
  include Config::AcaModelConcern
end

describe Config::AcaModelConcern do

  subject { TestAcaModelConcernClass.new }
 
  context ".aca_transmit_scheduled_employers" do
    it "should return setting" do
      expect(subject.aca_transmit_scheduled_employers).to be_truthy
    end
  end

  context ".aca_employer_transmission_day_of_month" do 
    it "should return setting" do
      expect(subject.aca_employer_transmission_day_of_month).to be_kind_of(Numeric)
    end
  end
end
