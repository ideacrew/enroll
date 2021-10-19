require "rails_helper"

describe FindOrCreateInsuredPerson, :dbclean => :after_each do
  let(:first_name) { "Joe" }
  let(:last_name) { "Smith" }
  let(:dob) { Date.new(1988, 3, 10) }
  let(:ssn) { "989834231" }
  let(:user) { FactoryBot.create(:user) }
  let(:result) { FindOrCreateInsuredPerson.call(context_arguments) }

  context "given a person who does not exist" do
    let(:context_arguments) {
      { :first_name => first_name,
      :last_name => last_name,
      :dob => dob }
    }

    it "should create that person and return them" do
      expect(result.person.first_name).to eq first_name
    end

    it "should communicate it created a new person" do
      expect(result.is_new).to be_truthy
    end
  end

  context "given a person who does exist" do
    let!(:found_person) { FactoryBot.create(:person, ssn: nil, :first_name => first_name, :last_name => last_name, :dob => dob) }
    let(:context_arguments) {
      { :first_name => first_name,
        :last_name => last_name,
        :dob => dob }
    }

    it "should return the found person" do
      expect(result.person).to eq found_person
    end

    it "should communicate that a new person was not created" do
      expect(result.is_new).to be_falsey
    end
  end

  context "given a person who does not exist but SSN is already taken" do
    let(:found_person) {  FactoryBot.create(:person, ssn: ssn) }
    let(:context_arguments) {
      { :first_name => first_name,
        :last_name => last_name,
        :dob => dob,
        :ssn => ssn
      }
    }

    before :each do
      allow(Person).to receive(:where).and_return [found_person]
    end

    it "should just return" do
      expect(result.person).to eq nil
    end

    it "should communicate that a new person was not created" do
      expect(result.is_new).to be_falsey
    end
  end
end
