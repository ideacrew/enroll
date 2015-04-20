require 'rails_helper'

describe FamilyMember, type: :model do
  context "a family with members exists" do
    include_context "BradyBunch"
    let(:family_member_id) {mikes_family.primary_applicant.id}

    it "FamilyMember.find(id) should work" do
      expect(FamilyMember.find(family_member_id).id.to_s).to eq family_member_id.to_s
    end

    it "should be possible to find the primary_relationship" do
      mikes_family.dependents.each do |dependent|
        if brady_children.include?(dependent.person)
          expect(dependent.primary_relationship).to eq "child"
        else
          expect(dependent.primary_relationship).to eq "spouse"
        end
      end
    end
  end

  describe "validation" do
    it { should validate_presence_of :person_id }
    it { should validate_presence_of :is_primary_applicant }
    it { should validate_presence_of :is_coverage_applicant }
  end

  let(:p0) {Person.create!(first_name: "Dan", last_name: "Aurbach")}
  let(:p1) {Person.create!(first_name: "Patrick", last_name: "Carney")}
  let(:ag) {Family.create()}
  let(:family_member_params) {
    { person: p0,
      is_primary_applicant: true,
      is_coverage_applicant: true,
      is_consent_applicant: true,
      is_active: true}
  }

  context "parent" do
    it "should equal to family" do
      family_member = ag.family_members.create(**family_member_params)
      expect(family_member.parent).to eq ag
    end

    it "should raise error with nil family" do
      family_member = FamilyMember.new(**family_member_params)
      expect{family_member.parent}.to raise_error
    end
  end

  context "person" do
    it "with person" do
      family_member = FamilyMember.new(**family_member_params)
      family_member.person= p1
      expect(family_member.person).to eq p1
    end

    it "without person" do
      expect(FamilyMember.new(**family_member_params.except(:person)).valid?).to be_falsey
    end
  end

  context "broker" do
    let(:person) {create(:person)}
    let(:broker_role) {person.create_broker_role(npn: "aaaa", provider_kind: "broker")}
    let(:person2) {create(:person)}
    let(:broker_role2) {person.create_broker_role(npn: "bbb", provider_kind: "broker")}

    it "with brokerrole" do
      family_member = ag.family_members.create(**family_member_params)
      family_member.broker= broker_role
      expect(family_member.broker).to eq broker_role
    end

    it "without broker_role" do
      family_member = ag.family_members.create(**family_member_params)
      family_member.broker = broker_role
      family_member.save

      family_member.broker = broker_role2
      family_member.save

      expect(family_member.broker).to eq broker_role
    end
  end

  context "comments" do
    it "with blank" do
      family_member = ag.family_members.create({
        person: p0,
        is_primary_applicant: true,
        is_coverage_applicant: true,
        is_consent_applicant: true,
        is_active: true,
        comments: [{priority: 'normal', content: ""}]
      })

      expect(family_member.errors[:comments].any?).to eq true
    end

    it "without blank" do
      family_member = ag.family_members.create({
        person: p0,
        is_primary_applicant: true,
        is_coverage_applicant: true,
        is_consent_applicant: true,
        is_active: true,
        comments: [{priority: 'normal', content: "aaas"}]
      })

      expect(family_member.errors[:comments].any?).to eq false
      expect(family_member.comments.size).to eq 1
    end
  end

  describe "indexes specified fields" do
  end

  describe "instantiates object." do
    it "sets and gets all basic model fields and embeds in parent class" do
      a = FamilyMember.new(
        person: p0,
        is_primary_applicant: true,
        is_coverage_applicant: true,
        is_consent_applicant: true,
        is_active: true
        )

      a.family = ag

      expect(a.person.last_name).to eql(p0.last_name)
      expect(a.person_id).to eql(p0._id)

      expect(a.is_primary_applicant?).to eql(true)
      expect(a.is_coverage_applicant?).to eql(true)
      expect(a.is_consent_applicant?).to eql(true)
    end
  end
end
