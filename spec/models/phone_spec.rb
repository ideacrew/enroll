require 'rails_helper'

describe Phone, type: :model do

  it "area_code invalid with improper characters" do
    expect(Phone.create(area_code: "a7d8d9d8h").errors[:area_code].any?).to eq true
  end

  it "area_code invalid when length <> 3" do
    expect(Phone.create(area_code: "20").errors[:area_code].any?).to eq true
    expect(Phone.create(area_code: "2020").errors[:area_code].any?).to eq true
  end

  it "strips non-numeric characters in valid area code" do
    expect(Phone.create(area_code: "(202)").errors[:area_code].any?).to eq false
  end

  it "area_code valid with correct numeric-only value" do
    expect(Phone.create(area_code: "202").errors[:area_code].any?).to eq false
  end

  it "number invalid when length <> 7" do
    expect(Phone.create(number: "20").errors[:number].any?).to eq true
    expect(Phone.create(number: "202578987420").errors[:number].any?).to eq true
  end

  it "strips non-numeric characters in valid number" do
    expect(Phone.create(number: "741-9874").errors[:number].any?).to eq false
  end

  it "kind invalid with null value" do
    expect(Phone.create(kind: "").errors[:kind].any?).to eq true
  end

  it "kind invalid with improper value" do
    expect(Phone.create(kind: :banana).errors[:kind].any?).to eq true
  end

  it "kind valid with proper value" do
    expect(Phone.create(kind: "work").errors[:kind].any?).to eq false
  end
  
  
  let(:person) {FactoryGirl.create(:person, gender: "male", dob: "10/10/1974", ssn: "123456789" )}
  let(:params) {{kind: "home", full_phone_number: "(222)-1111-111", person: person}}
  it "strips valid area code and number from full phone number" do
    phone = Phone.new(**params)
    expect(phone.save).to eq true
    expect(phone.area_code).to eq "222"
    expect(phone.number).to eq "1111111"
  end


end

