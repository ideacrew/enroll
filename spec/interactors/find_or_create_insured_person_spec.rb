# frozen_string_literal: true

require "rails_helper"

describe FindOrCreateInsuredPerson, :dbclean => :after_each do
  let(:first_name) { "Joe" }
  let(:last_name) { "Smith" }
  let(:dob) { Date.new(1988, 3, 10) }
  let(:ssn) { "789834231" }
  let(:user) { FactoryBot.create(:user) }
  let(:result) { FindOrCreateInsuredPerson.call(context_arguments) }

  context "given a person who does not exist" do
    let(:context_arguments) do
      { :first_name => first_name,
        :last_name => last_name,
        :dob => dob }
    end

    it "should create that person and return them" do
      expect(result.person.first_name).to eq first_name
    end

    it "should communicate it created a new person" do
      expect(result.is_new).to be_truthy
    end
  end

  context "given a person who does exist" do
    let!(:found_person) { FactoryBot.create(:person, ssn: nil, :first_name => first_name, :last_name => last_name, :dob => dob) }
    let(:context_arguments) do
      { :first_name => first_name,
        :last_name => last_name,
        :dob => dob }
    end

    it "should return the found person" do
      expect(result.person).to eq found_person
    end

    it "should communicate that a new person was not created" do
      expect(result.is_new).to be_falsey
    end
  end

  context "given a person who does not exist but SSN is already taken" do
    let!(:found_person) {  FactoryBot.create(:person, ssn: ssn) }
    let(:context_arguments) do
      { :first_name => first_name,
        :last_name => last_name,
        :dob => dob,
        :ssn => ssn}
    end

    it "should just return" do
      expect(result.person).to eq nil
    end

    it "should communicate that a new person was not created" do
      expect(result.is_new).to be_falsey
    end
  end

  context "given an invalid SSN with the :validate_ssn feature flag active" do
    let(:context_arguments) do
      { :first_name => first_name,
        :last_name => last_name,
        :dob => dob}
    end

    before :each do
      allow(EnrollRegistry).to receive(:feature_enabled?).with(:check_for_crm_updates).and_return(true)
      allow(EnrollRegistry).to receive(:feature_enabled?).with(:crm_publish_primary_subscriber).and_return(true)
      allow(EnrollRegistry).to receive(:feature_enabled?).with(:validate_ssn).and_return(true)
    end

    it "will throw an error if the SSN consists of only zeroes" do
      context_arguments[:ssn] = '000000000'
      person = result.person

      expect(person.valid?).to be_falsey
      expect(person.errors[:ssn]).to include('Invalid SSN format')
    end

    it "will throw an error if the first three digits of an SSN consists of only zeroes" do
      context_arguments[:ssn] = '000834231'
      person = result.person

      expect(person.valid?).to be_falsey
      expect(person.errors[:ssn]).to include('Invalid SSN format')
    end

    it "will throw an error if the first three digits of an SSN consists of only sixes" do
      context_arguments[:ssn] = '666834231'
      person = result.person

      expect(person.valid?).to be_falsey
      expect(person.errors[:ssn]).to include('Invalid SSN format')
    end

    it "will throw an error if the first three digits of an SSN is between 900-999" do
      ssn = "#{rand(900..999)}834231"
      context_arguments[:ssn] = ssn
      person = result.person

      expect(person.valid?).to be_falsey
      expect(person.errors[:ssn]).to include('Invalid SSN format')
    end

    it "will throw an error if the fourth and fifth digit of an SSN are zeroes" do
      context_arguments[:ssn] = '789004231'
      person = result.person

      expect(person.valid?).to be_falsey
      expect(person.errors[:ssn]).to include('Invalid SSN format')
    end

    it "will throw an error if the last four digits of an SSN are zeroes" do
      context_arguments[:ssn] = '789830000'
      person = result.person

      expect(person.valid?).to be_falsey
      expect(person.errors[:ssn]).to include('Invalid SSN format')
    end
  end
end
