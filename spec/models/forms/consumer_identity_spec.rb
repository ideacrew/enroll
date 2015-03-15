require "rails_helper"

describe Forms::ConsumerIdentity do
    it "should have error on dob" do
      subject.valid?
      expect(subject.errors).to include(:date_of_birth)
    end

    it "should have errors on the missing names" do
      subject.valid?
      expect(subject.errors).to include(:last_name)
      expect(subject.errors).to include(:first_name)
    end

    it "should have errors on the ssn" do
      subject.valid?
      expect(subject.errors).to include(:ssn)
    end
end

describe Forms::ConsumerIdentity do

end
