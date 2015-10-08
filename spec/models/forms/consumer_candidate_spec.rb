require 'rails_helper'
describe Forms::ConsumerCandidate, "asked to match a person" do

  subject {
    Forms::ConsumerCandidate.new({
                                     :dob => "2012-10-12",
                                     :ssn => "123-45-6789",
                                     :first_name => "yo",
                                     :last_name => "guy",
                                     :gender => "m",
                                     :user_id => 20
                                 })
  }
  let(:person) {FactoryGirl.create(:person)}
  context "uniq ssn" do 
    it "return true when ssn is blank" do 
      allow(subject).to receive(:ssn).and_return(nil)
      expect(subject.uniq_ssn).to eq true
    end

    it "add errors when duplicated ssn with a user account" do
      allow(subject).to receive(:ssn).and_return("123456789") 
      allow(Person).to receive(:where).and_return([person])
      allow(person).to receive(:user).and_return(true)
      subject.uniq_ssn
      expect(subject.errors[:base]).to eq ["This Social Security Number has been taken on another account.  If this is your correct SSN, and you don’t already have an account, please contact #{HbxProfile::CallCenterName} at #{HbxProfile::CallCenterPhoneNumber}."]
    end

    it "does not add errors when duplicated ssn and no account" do
      allow(subject).to receive(:ssn).and_return("123456789")
      allow(Person).to receive(:where).and_return([person])
      allow(person).to receive(:user).and_return(false)
      subject.uniq_ssn
      expect(subject.errors[:base]).to eq []
    end

  end
end
