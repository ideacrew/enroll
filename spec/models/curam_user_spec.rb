require 'rails_helper'

describe CuramUser, "verification if user exists in Curam" do
  let(:dob_1980) { Date.new(1980, 1, 1) }
  let(:dob_1981) { Date.new(1981, 1, 1) }
  let(:dob_1982) { Date.new(1982, 1, 1) }

  before :each do
    user1 = CuramUser.create(first_name: "Serg", last_name:"Lis", ssn: "123456789", dob: dob_1980)
    user2 = CuramUser.create(first_name: "Ivan", last_name:"Umen", ssn: "987654321", dob: dob_1981)
    user3 = CuramUser.create(first_name: "Potap", last_name:"Razumen", ssn: "345678912", dob: dob_1982)
  end
  it "returns true if SSN is matching any record" do
    expect(CuramUser.match_ssn(123456789)).to be true
  end

  it "return false if SSN doesn't match" do
    expect(CuramUser.match_ssn(12345678)).to be false
  end

  it "returns true if SSN and DOB exist and belongs to the same user" do
    expect(CuramUser.match_ssn_dob(123456789, dob_1980).any?).to be true
  end

  it "returns false if SSN mathing but DOB doesn't" do
    expect(CuramUser.match_ssn_dob(123456789, Date.new(1970, 1, 1)).any?).to be false
  end

  it "returns false if DOB matching but SSN doesn't" do
    expect(CuramUser.match_ssn_dob(1234567899, dob_1980).any?).to be false
  end

  it "returns false if DOB mathing and SSN matching but belongs to diff users" do
    expect(CuramUser.match_ssn_dob(123456789, dob_1981).any?).to be false
  end
end
