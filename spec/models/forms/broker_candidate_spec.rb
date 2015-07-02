require "rails_helper"

describe Forms::BrokerCandidate, "validations" do

  subject {
    Forms::BrokerCandidate.new(attributes)
  }

  context 'when firstname, lastname, dob, email are blank' do 

    let(:attributes) { { broker_applicant_type: 'staff' } }

    before :each do
      subject.valid?
    end

    it "should validate dob" do
      expect(subject).to have_errors_on(:dob)
    end

    it "should validate first_name" do
      expect(subject).to have_errors_on(:first_name)
    end

    it "should validate last_name" do
      expect(subject).to have_errors_on(:last_name)
    end

    it "should validate email" do
      expect(subject).to have_errors_on(:email)
    end

    it "should not validate NPN" do
      expect(subject).not_to have_errors_on(:npn)
    end
  end


  context 'when applicant_type is broker staff member' do 

    let(:attributes) { { broker_applicant_type: 'broker' } }

    before :each do
      subject.valid?
    end

    it "should validate NPN" do
      expect(subject).to have_errors_on(:npn)
    end
  end
end
