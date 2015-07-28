require 'rails_helper'

describe Forms::EmployeeDependent do
  let(:family_id) { double }
  let(:family) { instance_double("Family") }
  before(:each) do
    allow(Family).to receive(:find).and_return(family)
    allow(family).to receive(:family_members).and_return([])
    subject.valid?
  end

  it "should require a relationship" do
    expect(subject).to have_errors_on(:relationship)
  end

  it "should require a gender" do
    expect(subject).to have_errors_on(:gender)
  end

  it "should require a dob" do
    expect(subject).to have_errors_on(:dob)
  end

  it "should require the correct set of name components" do
    expect(subject).to have_errors_on(:first_name)
    expect(subject).to have_errors_on(:last_name)
  end

  it "should require a family_id" do
    expect(subject).to have_errors_on(:family_id)
  end

  it "should not be considered persisted" do
    expect(subject.persisted?).to be_falsey
  end
end

describe Forms::EmployeeDependent, "which describes a new family member, and has been saved" do
  let(:family_id) { double }
  let(:family) { instance_double("Family") }
  let(:ssn) { nil }
  let(:dob) { "2007-06-09" }
  let(:existing_family_member_id) { double }
  let(:relationship) { double }
  let(:existing_family_member) { nil }
  let(:existing_person) { nil }

  let(:person_properties) {
    {
      :first_name => "aaa",
      :last_name => "bbb",
      :middle_name => "ccc",
      :name_pfx => "ddd",
      :name_sfx => "eee",
      :ssn => "123456778",
      :gender => "male",
      :dob => dob
    }
  }

  subject { Forms::EmployeeDependent.new(person_properties.merge({:family_id => family_id, :relationship => relationship })) }

  before(:each) do
    allow(subject).to receive(:valid?).and_return(true)
    allow(Family).to receive(:find).with(family_id).and_return(family)
    allow(family).to receive(:find_matching_inactive_member).with(subject).and_return(existing_family_member)
    allow(Person).to receive(:match_existing_person).with(subject).and_return(existing_person)
  end

  describe "where the same family member existed previously" do
    let(:previous_family_member) { existing_family_member }
    let(:existing_family_member) { instance_double(::FamilyMember, :id => existing_family_member_id, :save! => true) }

    it "should use that family member's id" do
      allow(existing_family_member).to receive(:reactivate!).with(relationship)
      subject.save
      expect(subject.id).to eq existing_family_member.id
    end

    it "should reactivate the family member with the correct relationship." do
      expect(existing_family_member).to receive(:reactivate!).with(relationship)
      subject.save
    end
  end

  describe "that matches an existing person" do
    let(:existing_person) { instance_double("Person") }
    let(:new_family_member_id) { double }
    let(:new_family_member) { instance_double(::FamilyMember, :id => new_family_member_id, :save! => true) }

    it "should create a family member for that person" do
      expect(family).to receive(:relate_new_member).with(existing_person, relationship).and_return(new_family_member)
      subject.save
      expect(subject.id).to eq new_family_member_id
    end
  end

  describe "for a new person" do
    let(:new_family_member_id) { double }
    let(:new_family_member) { instance_double(::FamilyMember, :id => new_family_member_id, :save! => true) }
    let(:new_person) { double(:save => true, :errors => double(:has_key? => false)) }

    before do
      allow(family).to receive(:relate_new_member).with(new_person, relationship).and_return(new_family_member)
      allow(family).to receive(:save!).and_return(true)
    end

    it "should create a new person" do
      person_properties[:dob] = Date.strptime(person_properties[:dob], "%Y-%m-%d")
      expect(Person).to receive(:new).with(person_properties).and_return(new_person)
      subject.save
    end

    it "should create a new family member" do
      person_properties[:dob] = Date.strptime(person_properties[:dob], "%Y-%m-%d")
      allow(Person).to receive(:new).with(person_properties).and_return(new_person)
      subject.save
      expect(subject.id).to eq new_family_member_id
    end
  end
end

describe Forms::EmployeeDependent, "which describes an existing family member" do
  let(:family_member_id) { double }
  let(:family_id) { double }
  let(:family) { instance_double("Family", :id => family_id) }
  let(:dob) { "2007-06-09" }
  let(:relationship) { "spouse" }
  let(:person_properties) {
    {
      :first_name => "aaa",
      :last_name => "bbb",
      :middle_name => "ccc",
      :name_pfx => "ddd",
      :name_sfx => "eee",
      :ssn => "123456778",
      :gender => "male",
      :dob => Date.strptime(dob, "%Y-%m-%d")
    }
  }
  let(:person) { double(:errors => double(:has_key? => false)) }
  let(:family_member) { instance_double(::FamilyMember,
                                        person_properties.merge({
                                        :family => family,
                                        :family_id => family_id, :person => person, :primary_relationship => relationship, :save! => true})) }

  let(:update_attributes) { person_properties.merge(:family_id => family_id, :relationship => relationship, :dob => dob) }

  subject { Forms::EmployeeDependent.new({ :id => family_member_id }) }

  before(:each) do
    allow(FamilyMember).to receive(:find).with(family_member_id).and_return(family_member)
    allow(subject).to receive(:valid?).and_return(true)
  end

  it "should be considered persisted" do
    expect(subject.persisted?).to be_truthy
  end


  describe "that is findable using the family_member_id" do
    before(:each) do
      @found_form = Forms::EmployeeDependent.find(family_member_id)
    end

    it "should have the correct family_id" do
      expect(@found_form.family_id).to eq(family_id)
    end

    it "should have the existing family" do
      expect(@found_form.family).to eq family
    end
  end

  describe "when updated" do
    it "should update the relationship of the dependent" do
      allow(person).to receive(:update_attributes).with(person_properties).and_return(true)
      expect(family_member).to receive(:update_relationship).with(relationship)
      subject.update_attributes(update_attributes)
    end

    it "should update the attributes of the person" do
      expect(person).to receive(:update_attributes).with(person_properties)
      allow(family_member).to receive(:update_relationship).with(relationship)
      subject.update_attributes(update_attributes)
    end
  end
end

describe Forms::EmployeeDependent, "relationship validation" do
  let(:family) { FactoryGirl.build(:family) }
  let(:family_member) { FactoryGirl.build(:family_member, family: family) }
  let(:family_members) { family.family_members}
  let(:ssn) { nil }
  let(:dob) { "2007-06-09" }

  let(:person_properties) {
    {
      :first_name => "aaa",
      :last_name => "bbb",
      :middle_name => "ccc",
      :name_pfx => "ddd",
      :name_sfx => "eee",
      :ssn => "123456778",
      :gender => "male",
      :dob => dob
    }
  }

  before(:each) do
    allow(Family).to receive(:find).with(family.id).and_return(family)
    allow(family).to receive(:family_members).and_return(family_members)
    allow(family_members).to receive(:where).and_return([family_member])
  end

  context "spouse" do
    let(:relationship) { "spouse" }
    subject { Forms::EmployeeDependent.new(person_properties.merge({:family_id => family.id, :relationship => relationship })) }

    it "should fail with multiple spouse" do
      allow(family_member).to receive(:relationship).and_return("spouse")
      expect(subject.valid?).to be false
      expect(subject.errors.to_hash[:base]).to include("can not have multiple spouse or life partner") 
    end

    it "should fail with spouse and life_partner" do
      allow(family_member).to receive(:relationship).and_return("life_partner")
      expect(subject.valid?).to be false
      expect(subject.errors.to_hash[:base]).to include("can not have multiple spouse or life partner") 
    end
  end

  context "life_partner" do
    let(:relationship) { "life_partner" }
    subject { Forms::EmployeeDependent.new(person_properties.merge({:family_id => family.id, :relationship => relationship })) }

    it "should fail with multiple life_partner" do
      allow(family_member).to receive(:relationship).and_return("life_partner")
      expect(subject.valid?).to be false
      expect(subject.errors.to_hash[:base]).to include("can not have multiple spouse or life partner") 
    end
  end

  context "change to spouse from life_partner" do
    let(:relationship) { "spouse" }

    it "should success" do
      allow(family_member).to receive(:relationship).and_return("life_partner")
      allow(family_member).to receive(:reactivate!).and_return(true)
      allow(FamilyMember).to receive(:find).and_return(family_member)

      dependent = Forms::EmployeeDependent.find(family_member.id)
      dependent.update_attributes(person_properties.merge({:family_id => family.id, :relationship => relationship, :id => family_member.id }))

      expect(dependent.valid?).to be true
      expect(dependent.errors[:base].any?).to be_falsey
    end
  end
end
