require "rails_helper"

describe Forms::PersonSignup, "validations" do

  subject {
    Forms::PersonSignup.new
  }

  context 'when firstname, lastname, dob, email are blank' do 

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
  end
end


describe Forms::PersonSignup, ".match_or_create_person" do

  let(:person_attributes) { {
    first_name: "steve",
    last_name: "smith",
    email: "example@email.com",
    dob: "1974-10-10"
  }.merge(other_attributes)}

  let(:other_attributes) { {} }

  subject {
    Forms::PersonSignup.new(person_attributes)
  }

  context 'when more than 1 person matched' do 
    before :each do
      2.times { FactoryBot.create(:person, first_name: "steve", last_name: "smith", dob: "10/10/1974") }
    end

    it "should raise an exception" do
      expect { subject.match_or_create_person }.to raise_error(Forms::PersonSignup::TooManyMatchingPeople)
    end
  end

  context 'when person with same information already present in the system' do 
    let(:other_attributes) { {first_name: "james"}}

     before :each do
      FactoryBot.create(:person, first_name: "james", last_name: "smith", dob: "10/10/1974")
      subject.match_or_create_person
    end

    it "should build person with existing record" do
      person = Person.where(first_name: "james", last_name: "smith", dob: "10/10/1974").first
      expect(subject.person).to eq(person)
    end
  end

  context 'when person not matched in the system' do 
    let(:person_attributes) { {
      first_name: "joe",
      last_name: "smith",
      email: "example@email.com",
      dob: "1978-10-10"
      }}

    before :each do 
      subject.match_or_create_person
    end

    it "should build new person" do
      expect(subject.person).to be_truthy
      expect(subject.person.first_name).to eq(person_attributes[:first_name])
      expect(subject.person.last_name).to eq(person_attributes[:last_name])
      expect(subject.person.dob).to eq(subject.dob)
    end

    it "should add work email address to the person" do
      expect(subject.person.emails).not_to be_empty
      expect(subject.person.emails[0].kind).to eq('work')
      expect(subject.person.emails[0].address).to eq(person_attributes[:email])
    end
  end
end