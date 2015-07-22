require 'rails_helper'

describe Person do

  it { should validate_presence_of :first_name }
  it { should validate_presence_of :last_name }

  let(:first_name) {"Martina"}
  let(:last_name) {"Williams"}
  let(:ssn) {"657637863"}
  let(:gender) {"male"}
  let(:address) {FactoryGirl.build(:address)}
  let(:valid_params) do
    { first_name: first_name,
      last_name: last_name,
      ssn: ssn,
      gender: gender,
      addresses: [address]
    }
  end

  describe ".create", dbclean: :after_each do
    context "with valid arguments" do
      let(:params) {valid_params}
      let(:person) {Person.create(**params)}
      before do
        person.valid?
      end

      it 'should generate hbx_id' do
        expect(person.hbx_id).to be_truthy
      end

      context "and a second person is created with the same ssn" do
        let(:person2) {Person.create(**params)}
        before do
          person2.valid?
        end

        context "the second person" do
          it "should not be valid" do
            expect(person2.valid?).to be false
          end

          it "should have an error on ssn" do
            expect(person2.errors[:ssn].any?).to be true
          end

          it "should not have the same id as the first person" do
            expect(person2.id).not_to eq person.id
          end
        end
      end
    end
  end

  describe ".new" do
    context "with no arguments" do
      let(:params) {{}}

      it "should be invalid" do
        expect(Person.new(**params).valid?).to be_falsey
      end
    end

    context "with all valid arguments" do
      let(:params) {valid_params}
      let(:person) {Person.new(**params)}

      it "should save" do
        expect(person.valid?).to be_truthy
      end

      it "should known its relationship is self" do
        expect(person.find_relationship_with(person)).to eq "self"
      end
    end

    context "with no first_name" do
      let(:params) {valid_params.except(:first_name)}

      it "should fail validation" do
        person = Person.new(**params)
        person.valid?
        expect(person.errors[:first_name].any?).to be_truthy
      end
    end

    context "with no last_name" do
      let(:params) {valid_params.except(:last_name)}

      it "should fail validation" do
        person = Person.new(**params)
        person.valid?
        expect(person.errors[:last_name].any?).to be_truthy
      end
    end

    context "with no ssn" do
      let(:params) {valid_params.except(:ssn)}

      it "should not fail validation" do
        person = Person.new(**params)
        person.valid?
        expect(person.errors[:ssn].any?).to be_falsey
      end
    end

    context "with invalid gender" do
      let(:params) {valid_params.deep_merge({gender: "abc"})}

      it "should fail validation" do
        person = Person.new(**params)
        person.valid?
        expect(person.errors[:gender]).to eq ["abc is not a valid gender"]
      end
    end

    context 'duplicated key issue' do
      before do
        Person.collection.indexes.drop({'ssn' => 1})
        Person.create_indexes
      end
      context "with blank ssn" do

        let(:params) {valid_params.deep_merge({ssn: ""})}

        it "should fail validation" do
          person = Person.new(**params)
          person.valid?
          expect(person.errors[:ssn].any?).to be_falsey
        end

        it "allow duplicated blank ssn" do
          person1 = Person.create(**params)
          person2 = Person.create(**params)
          expect(person2.errors[:ssn].any?).to be_falsey
        end
      end

      context "with nil ssn" do
        let(:params) {valid_params.deep_merge({ssn: nil})}

        it "should fail validation" do
          person = Person.new(**params)
          person.valid?
          expect(person.errors[:ssn].any?).to be_falsey
        end

        it "allow duplicated blank ssn" do
          person1 = Person.create(**params)
          person2 = Person.create(**params)
          expect(person2.errors[:ssn].any?).to be_falsey
        end
      end
    end

    context "with nil ssn" do
      let(:params) {valid_params.deep_merge({ssn: ""})}

      it "should fail validation" do
        person = Person.new(**params)
        person.valid?
        expect(person.errors[:ssn].any?).to be_falsey
      end
    end

    context "with invalid ssn" do
      let(:params) {valid_params.deep_merge({ssn: "123345"})}

      it "should fail validation" do
        person = Person.new(**params)
        person.valid?
        expect(person.errors[:ssn]).to eq ["SSN must be 9 digits"]
      end
    end

    context "with date of birth" do
      let(:dob){ 25.years.ago }
      let(:params) {valid_params.deep_merge({dob: dob})}

      before(:each) do
        @person = Person.new(**params)
      end

      it "should get the date of birth" do
        expect(@person.date_of_birth).to eq dob.strftime("%m/%d/%Y")
      end

      it "should set the date of birth" do
        @person.date_of_birth = "01/01/1985"
        expect(@person.dob.to_s).to eq "01/01/1985"
      end

      it "should return date of birth as string" do
        expect(@person.dob_to_string).to eq dob.strftime("%Y%m%d")
      end

      it "should return if a person is active or not" do
        expect(@person.is_active?).to eq true
        @person.is_active = false
        expect(@person.is_active?).to eq false
      end
    end

    context "with invalid date values" do
      context "and date of birth is in future" do
        let(:params) {valid_params.deep_merge({dob: Date.today + 1})}

        it "should fail validation" do
          person = Person.new(**params)
          person.valid?
          expect(person.errors[:dob].size).to eq 1
        end
      end

      context "and date of death is in future" do
        let(:params) {valid_params.deep_merge({date_of_death: Date.today + 1})}

        it "should fail validation" do
          person = Person.new(**params)
          person.valid?
          expect(person.errors[:date_of_death].size).to eq 1
        end
      end

      context "and date of death preceeds date of birth" do
        let(:params) {valid_params.deep_merge({date_of_death: Date.today - 10, dob: Date.today - 1})}

        it "should fail validation" do
          person = Person.new(**params)
          person.valid?
          expect(person.errors[:date_of_death].size).to eq 1
        end
      end
    end

  end

end

describe Person, '.match_by_id_info' do
  before(:all) do
    @p0 = Person.create!(first_name: "Jack",   last_name: "Bruce",   dob: "1943-05-14", ssn: "517994321")
    @p1 = Person.create!(first_name: "Ginger", last_name: "Baker",   dob: "1939-08-19", ssn: "888007654")
    @p2 = Person.create!(first_name: "Eric",   last_name: "Clapton", dob: "1945-03-30", ssn: "666332345")
  end

  after(:all) do
    DatabaseCleaner.clean
  end

  it 'matches by last_name and dob' do
    expect(Person.match_by_id_info(last_name: @p0.last_name, dob: @p0.dob)).to eq [@p0]
  end

  it 'matches by ssn' do
    expect(Person.match_by_id_info(ssn: @p1.ssn)).to eq [@p1]
  end

  it 'matches by ssn, last_name and dob' do
    expect(Person.match_by_id_info(last_name: @p2.last_name, dob: @p2.dob, ssn: @p2.ssn)).to eq [@p2]
  end

  it 'not match last_name and dob if not on same record' do
    expect(Person.match_by_id_info(last_name: @p0.last_name, dob: @p1.dob).size).to eq 0
  end

  it 'returns empty array for non-matches' do
    expect(Person.match_by_id_info(ssn: "577600345")).to eq []
  end
end

describe Person, '.active', :dbclean => :after_each do
  it 'new person defaults to is_active' do
    expect(Person.create!(first_name: "eric", last_name: "Clapton").is_active).to eq true
  end

  it 'returns person records only where is_active == true' do
    p1 = Person.create!(first_name: "Jack", last_name: "Bruce", is_active: false)
    p2 = Person.create!(first_name: "Ginger", last_name: "Baker")
    expect(Person.active.size).to eq 1
    expect(Person.active.first).to eq p2
  end
end

## Instance methods
describe Person, '#addresses' do
  it "invalid address bubbles up" do
    person = Person.new
    addresses = person.addresses.build({address_1: "441 4th ST, NW", city: "Washington", state: "DC", zip: "20001"})
    expect(person.valid?).to eq false
    expect(person.errors[:addresses].any?).to eq true
  end

  it 'persists associated address', dbclean: :after_each do
    # setup
    person = FactoryGirl.build(:person)
    addresses = person.addresses.build({kind: "home", address_1: "441 4th ST, NW", city: "Washington", state: "DC", zip: "20001"})

    result = person.save

    expect(result).to eq true
    expect(person.addresses.first.kind).to eq "home"
    expect(person.addresses.first.city).to eq "Washington"
  end
end

describe Person, '#find_all_staff_roles_by_employer_profile' do
  employer_profile = FactoryGirl.build(:employer_profile)
  person = FactoryGirl.build(:person)

  it "should have the same search criteria" do
    allow(Person).to receive(:where).and_return(person)
    expect(Person.find_all_staff_roles_by_employer_profile(employer_profile)).to eq person
  end

end

describe Person, "large family with multiple employees - The Brady Bunch", :dbclean => :after_all do
  include_context "BradyBunchAfterAll"

  before :all do
    create_brady_families
  end

  context "a person" do
    it "should know its age today" do
      expect(greg.age_on(Date.today)).to eq gregs_age
    end

    it "should know its age on a given date" do
      expect(greg.age_on(18.months.ago.to_date)).to eq (gregs_age - 2)
    end

    it "should know its age yesterday" do
      expect(greg.age_on(Date.today.advance(days: -1))).to eq (gregs_age - 1)
    end

    it "should know its age tomorrow" do
      expect(greg.age_on(1.day.from_now.to_date)).to eq gregs_age
    end
  end

  context "Person#primary_family" do
    context "on Mike" do
      let(:find) {mike.primary_family}
      it "should find Mike's family" do
        expect(find.id.to_s).to eq mikes_family.id.to_s
      end
    end

    context "on Carol" do
      let(:find) {carol.primary_family}
      it "should find Carol's family" do
        expect(find.id.to_s).to eq carols_family.id.to_s
      end
    end
  end

  context "Person#families" do
    context "on Mike" do
      let(:find) {mike.families.collect(&:id)}
      it "should find two families" do
        expect(find.count).to be 2
      end
      it "should find Mike's family" do
        expect(find).to include mikes_family.id
      end
      it "should find Carol's family" do
        expect(find).to include carols_family.id
      end
    end

    context "on Carol" do
      let(:find) {carol.families.collect(&:id)}
      it "should find two families" do
        expect(find.count).to be 2
      end
      it "should find Mike's family" do
        expect(find).to include mikes_family.id
      end
      it "should find Carol's family" do
        expect(find).to include carols_family.id
      end
    end

    context "on Greg" do
      let(:find) {greg.families.collect(&:id)}
      it "should find two families" do
        expect(find.count).to be 2
      end
      it "should find Mike's family" do
        expect(find).to include mikes_family.id
      end
      it "should find Carol's family" do
        expect(find).to include carols_family.id
      end
    end
  end
end

describe Person, '#person_relationships' do
  it 'accepts associated addresses' do
    # setup
    person = FactoryGirl.build(:person)
    relationship = person.person_relationships.build({kind: "self", relative: person})

    expect(person.save).to eq true
    expect(person.person_relationships.size).to eq 1
    expect(relationship.invert_relationship.kind).to eq "self"
  end
end

describe Person, '#full_name' do
  it 'returns the concatenated name attributes' do
    expect(Person.new(first_name: "Ginger", last_name: "Baker").full_name).to eq 'Ginger Baker'
  end
end

describe Person, '#phones' do
  it "sets person's home telephone number" do
    person = Person.new
    person.phones.build({kind: 'home', area_code: '202', number: '555-1212'})

    # expect(person.phones.first.number).to eq '5551212'
  end
end

describe Person, '#emails' do
  it "sets person's home email" do
    person = Person.new
    person.emails.build({kind: 'home', address: 'sam@example.com'})

    expect(person.emails.first.address).to eq 'sam@example.com'
  end
end

describe Person, '#families' do
  it 'returns families where the person is present' do
  end
end

describe Person, "with no relationship to a dependent" do
  describe "after ensure_relationship_with" do
    it "should have the new relationship"
  end
end

describe Person, "with an existing relationship to a dependent" do
  describe "after ensure_relationship_with a different type of relationship" do
    it "should correct the existing relationship"
  end
end

describe Person, "call notify change event when after save" do
  before do
    extend Notify
  end

  context "notify change event" do
    let(:person){FactoryGirl.build(:person)}
    it "when new record" do
#      expect(person).to receive(:notify_change_event).exactly(1).times
      person.save
    end

    it "when change record" do
#      expect(person).to receive(:notify_change_event).exactly(1).times
      first_name = person.first_name
      person.first_name = "Test"
      person.save
    end
  end
end

describe Person, "does not allow two people with the same user ID to be saved" do
  let(:person1){FactoryGirl.build(:person)}
  let(:person2){FactoryGirl.build(:person)}

  it "should let fail to save" do
    user_id = BSON::ObjectId.new
    person1.user_id = user_id
    person2.user_id = user_id
    person1.save!
    expect { person2.save! }.to raise_error(Moped::Errors::OperationFailure)
  end
  
end

describe Person, "persisted with no user" do
  let(:person1){FactoryGirl.create(:person)}
  let(:user1){FactoryGirl.create(:user)}

  it "should be fine with having a user assigned" do
    person1.user = user1
    expect(person1.valid?).to eq(true)
  end
end

describe Person, "persisted with a user" do
  let(:person1){FactoryGirl.create(:person)}
  let(:user1){FactoryGirl.create(:user)}
  let(:user2){FactoryGirl.create(:user)}

  before :each do
    person1.user = user1
    person1.save!
  end

  it "should not allow a different user to be assigned" do
    expect(person1.valid?).to eq(true)
    person1.user = user2
    expect(person1.valid?).to eq(false)
  end
  it "should allow the same user to be assigned" do
    expect(person1.valid?).to eq(true)
    person1.user = nil
    person1.user = user1
    expect(person1.valid?).to eq(true)
  end
end

describe Person, "validation of date_of_birth and date_of_death" do
  let(:person) { FactoryGirl.create(:person) }

  context "validate of date_of_birth_is_past" do
    it "should invalid" do
      dob = (Date.today + 10.days)
      allow(person).to receive(:dob).and_return(dob)
      expect(person.save).to be_falsey
      expect(person.errors[:dob].any?).to be_truthy
      expect(person.errors[:dob].to_s).to match /future date: #{dob.to_s} is invalid date of birth/
    end
  end

  context "date_of_death_is_blank_or_past" do
    it "should invalid" do
      date_of_death = (Date.today + 10.days)
      allow(person).to receive(:date_of_death).and_return(date_of_death)
      expect(person.save).to be_falsey
      expect(person.errors[:date_of_death].any?).to be_truthy
      expect(person.errors[:date_of_death].to_s).to match /future date: #{date_of_death.to_s} is invalid date of death/
    end
  end
end
