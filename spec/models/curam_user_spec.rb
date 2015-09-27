require 'rails_helper'

describe CuramUser, "verification if user exists in Curam" do
  before :each do
    user1 = CuramUser.create(username: "username", first_name: "Serg", last_name:"Lis", ssn: "123456789", dob: "1980")
    user2 = CuramUser.create(username: "username2", first_name: "Ivan", last_name:"Umen", ssn: "987654321", dob: "1981")
    user3 = CuramUser.create(username: "username3", first_name: "Potap", last_name:"Razumen", ssn: "345678912", dob: "1982")
  end
  it "returns true if SSN is matching any record" do
    expect(CuramUser.match_ssn(123456789)).to be true
  end

  it "return false if SSN doesn't match" do
    expect(CuramUser.match_ssn(12345678)).to be false
  end

  it "returns true if SSN and DOB exist and belongs to the same user" do
    expect(CuramUser.match_ssn_dob(123456789, "1980")).to be true
  end

  it "returns false if SSN mathing but DOB doesn't" do
    expect(CuramUser.match_ssn_dob(123456789, "12345")).to be false
  end

  it "returns false if DOB matching but SSN doesn't" do
    expect(CuramUser.match_ssn_dob(1234567899, "1980")).to be false
  end

  it "returns false if DOB mathing and SSN matching but belongs to diff users" do
    expect(CuramUser.match_ssn_dob(123456789, "1981")).to be false
  end
end
