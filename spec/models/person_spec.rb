require 'rails_helper'

describe Person, type: :model do

  it { should validate_presence_of :first_name }
  it { should validate_presence_of :last_name }

  let(:first_name) {"Martina"}
  let(:last_name) {"Williams"}
  let(:ssn) {"123456789"}
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

  describe ".create" do
    context "with valid arguments" do
      let(:params) {valid_params}
      let(:person) {Person.create(**params)}
      before do
        person.valid?
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

      it "should not save" do
        expect(Person.new(**params).save).to be_false
      end
    end

    context "with all valid arguments" do
      let(:params) {valid_params}

      it "should save" do
        expect(Person.new(**params).save).to be_true
      end
    end

    context "with no first_name" do
      let(:params) {valid_params.except(:first_name)}

      it "should fail validation" do
        expect(Person.create(**params).errors[:first_name].any?).to be_true
      end
    end

    context "with no last_name" do
      let(:params) {valid_params.except(:last_name)}

      it "should fail validation" do
        expect(Person.create(**params).errors[:last_name].any?).to be_true
      end
    end

    context "with no ssn" do
      let(:params) {valid_params.except(:ssn)}

      it "should not fail validation" do
        expect(Person.create(**params).errors[:ssn].any?).to be_false
      end
    end

   context "with invalid gender" do
      let(:params) {valid_params.deep_merge({gender: "abc"})}

      it "should fail validation" do
        expect(Person.create(**params).errors[:gender]).to eq ["abc is not a valid gender"]
      end
    end

   context "with invalid ssn" do
      let(:params) {valid_params.deep_merge({ssn: "123345"})}

      it "should fail validation" do
        expect(Person.create(**params).errors[:ssn]).to eq ["SSN must be 9 digits"]
      end
    end

    context "with invalid date values" do
      context "and date of birth is in future" do
        let(:params) {valid_params.deep_merge({dob: Date.today + 1})}

        it "should fail validation" do
          expect(Person.create(**params).errors[:dob].size).to eq 1
        end
      end

      context "and date of death is in future" do
        let(:params) {valid_params.deep_merge({date_of_death: Date.today + 1})}

        it "should fail validation" do
          expect(Person.create(**params).errors[:date_of_death].size).to eq 1
        end
      end

      context "and date of death preceeds date of birth" do
        let(:params) {valid_params.deep_merge({date_of_death: Date.today - 10, dob: Date.today - 1})}

        it "should fail validation" do
          expect(Person.create(**params).errors[:date_of_death].size).to eq 1
        end
      end
    end

  end

end

## Class methods
describe Person, '.match_by_id_info' do
  let(:p0) { Person.create!(first_name: "Jack",   last_name: "Bruce",   dob: "1943-05-14", ssn: "517994321") }
  let(:p1) { Person.create!(first_name: "Ginger", last_name: "Baker",   dob: "1939-08-19", ssn: "888007654") }
  let(:p2) { Person.create!(first_name: "Eric",   last_name: "Clapton", dob: "1945-03-30", ssn: "666332345") }

  it 'matches by last_name and dob' do
    expect(Person.match_by_id_info(last_name: p0.last_name, dob: p0.dob)).to eq [p0]
  end

  it 'matches by ssn' do
    expect(Person.match_by_id_info(ssn: p1.ssn)).to eq [p1]
  end

  it 'matches by ssn, last_name and dob' do
    expect(Person.match_by_id_info(last_name: p2.last_name, dob: p2.dob, ssn: p2.ssn)).to eq [p2]
  end

  it 'matches multiple records' do
    expect(Person.match_by_id_info(last_name: p2.last_name, dob: p2.dob, ssn: p0.ssn).size).to eq 2
  end

  it 'not match last_name and dob if not on same record' do
    expect(Person.match_by_id_info(last_name: p0.last_name, dob: p1.dob).size).to eq 0
  end

  it 'returns empty array for non-matches' do
    expect(Person.match_by_id_info(ssn: "577600345")).to eq []
  end
end

describe Person, '.active' do
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

  it 'persists associated address' do
    # setup
    person = FactoryGirl.build(:person)
    addresses = person.addresses.build({kind: "home", address_1: "441 4th ST, NW", city: "Washington", state: "DC", zip: "20001"})

    result = person.save

    expect(result).to eq true
    expect(person.addresses.first.kind).to eq "home"
    expect(person.addresses.first.city).to eq "Washington"
  end

  describe "large family with multiple employees - The Brady Bunch" do
    include_context "BradyBunch"

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
