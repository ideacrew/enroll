require 'rails_helper'

describe CuramUser, "verification if user exists in Curam" do
  let(:dob_1980) { Date.new(1980, 1, 1) }
  let(:dob_1981) { Date.new(1981, 1, 1) }
  let(:dob_1982) { Date.new(1982, 1, 1) }

  before :each do
    user1 = FactoryBot.create(:curam_user, ssn: "123456789")
  end

  context "match email" do
    it "should match if email is case-sensitive" do
      expect(CuramUser.match_email("test@example.com").any?).to be true
    end

    it "should match when email has all uppercase characters" do
      expect(CuramUser.match_email("TEST@EXAMPLE.COM").any?).to be true
    end

    it "should match when email has only one uppercase character" do
      expect(CuramUser.match_email("test@Example.COM").any?).to be true
    end

    it "returns false for incomplete email address" do
      expect(CuramUser.match_email("TEST@EXAMPLE").any?).to be false
    end

    it "returns false for extra letters on front of email address" do
      expect(CuramUser.match_email("extraTEST@EXAMPLE.com").any?).to be false
    end
  end

  it "returns true if SSN is matching any record" do
    expect(CuramUser.match_ssn(123456789)).to be true
  end

  it "return false if SSN doesn't match" do
    expect(CuramUser.match_ssn(12345678)).to be false
  end

  it "returns true if SSN and DOB exist and belongs to the same user" do
    expect(CuramUser.match_ssn_dob(123456789, "01/01/1980").any?).to be true
  end

  it "returns false if DOB matching but SSN doesn't" do
    expect(CuramUser.match_ssn_dob(123456782, "01/01/1980").any?).to be false
  end

  it "returns false if DOB mathing and SSN matching but belongs to diff users" do
    user2 = FactoryBot.create(:curam_user, dob: Date.new(1981, 1, 1))
    expect(CuramUser.match_ssn_dob(123456789, "01/01/1981").any?).to be false
  end

  it "returns true if firstname and lastname exists in list" do
    expect(CuramUser.name_in_curam_list("Ivan", "Lisyk")).to be true
  end
end
