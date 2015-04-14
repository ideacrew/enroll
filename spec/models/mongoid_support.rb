require 'rails_helper'

describe MongoidSupport do

  describe "included in FamilyMember and associated with person" do
    let(:person) { Person.new }
    subject { FamilyMember.new }

    it "should allow me to assign an unsaved person" do
      subject.person = person
      expect(subject.person).to eq person 
    end

    it "nilling the underlying attribute should nil the association" do
      subject.person = person
      subject.person_id = nil
      expect(subject.person).to eq nil
    end

    it "nilling the association should nil the attribute" do
      subject.person = person
      subject.person = nil
      expect(subject.person_id).to eq nil
    end
  end
end
