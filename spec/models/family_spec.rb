require 'rails_helper'

describe Family do

  let(:p0) { Person.create!(first_name: "Dan", last_name: "Aurbach") }
  let(:p1) { Person.create!(first_name: "Patrick", last_name: "Carney") }
  let(:a0) { family_member = FamilyMember.new(is_primary_applicant: true, is_consent_applicant: true);
  family_member.person=p0;
  family_member }
  let(:a1) { family_member = FamilyMember.new();
  family_member.person=p1;
  family_member }

  describe "instantiates object." do
    it "sets and gets all basic model fields" do
      now = DateTime.now.utc
      ag = Family.new(
          e_case_id: "6754632abc",
          renewal_consent_through_year: 2017,
          family_members: [a0, a1],
          submitted_at: now,
          is_active: true,
          updated_by: "rspec"
      )

      expect(ag.e_case_id).to eql("6754632abc")
      expect(ag.is_active).to eql(true)
      expect(ag.renewal_consent_through_year).to eql(2017)
      expect(ag.submitted_at.to_s).to eql(now.to_s)
      expect(ag.updated_by).to eql("rspec")

      expect(ag.family_members.size).to eql(2)
      expect(ag.primary_applicant.id).to eql(a0.id)
      expect(ag.primary_applicant.person.first_name).to eql("Dan")
      expect(ag.consent_applicant.person.last_name).to eql("Aurbach")
    end
  end

  describe "manages embedded associations." do

    it "sets family_members" do


      family = Family.create!(
          e_case_id: "6754632abc",
          renewal_consent_through_year: 2017,
          submitted_at: Date.today,
          family_members: [a0, a1],
          irs_groups: [IrsGroup.new()]
      );

      expect(family.family_members.size).to eql(2)

    end

  end

  describe "one family exists" do
    let!(:primary_person) {FactoryGirl.create(:person)}
    let!(:dependent_person) {FactoryGirl.create(:person)}
    let!(:first_family) {FactoryGirl.create(:family)}
    let!(:first_primary_member) {FactoryGirl.create(:family_member, :primary, family: first_family, person: primary_person)}
    let!(:first_dependent_member) {FactoryGirl.create(:family_member, family: first_family, person: dependent_person)}

    context "and a second family is built" do
      let!(:second_family) {FactoryGirl.build(:family)}
      let!(:second_primary_member) {FactoryGirl.build(:family_member, :primary, family: second_family, person: primary_person)}
      let!(:second_dependent_member) {FactoryGirl.build(:family_member, family: second_family, person: dependent_person)}

      it "second family should be valid" do
        expect(second_family.valid?).to be
      end
    end
  end

  describe "large family with multiple employees - The Brady Bunch" do
    let(:brady_addr) do
      FactoryGirl.build(:address,
        kind: "home",
        address_1:
        "4222 Clinton Way",
        address_2: nil,
        city: "Washington",
        state: "DC",
        zip: "20011"
      )
    end
    let(:brady_ph) {FactoryGirl.build(:phone, kind: "home", area_code: "202", number: "7620799", extension: nil)}
    let(:last_name) {"Brady"}
    let(:mike)   {FactoryGirl.create(:male, first_name: "Mike",   last_name: last_name, dob: 40.years.ago, addresses: [brady_addr.dup], phones: [brady_ph.dup])}
    let(:carol)  {FactoryGirl.create(:male, first_name: "Carol",  last_name: last_name, dob: 35.years.ago, addresses: [brady_addr.dup], phones: [brady_ph.dup])}
    let(:greg)   {FactoryGirl.create(:male, first_name: "Greg",   last_name: last_name, dob: 17.years.ago, addresses: [brady_addr.dup], phones: [brady_ph.dup])}
    let(:marcia) {FactoryGirl.create(:male, first_name: "Marcia", last_name: last_name, dob: 16.years.ago, addresses: [brady_addr.dup], phones: [brady_ph.dup])}
    let(:peter)  {FactoryGirl.create(:male, first_name: "Peter",  last_name: last_name, dob: 14.years.ago, addresses: [brady_addr.dup], phones: [brady_ph.dup])}
    let(:jan)    {FactoryGirl.create(:male, first_name: "Jan",    last_name: last_name, dob: 12.years.ago, addresses: [brady_addr.dup], phones: [brady_ph.dup])}
    let(:bobby)  {FactoryGirl.create(:male, first_name: "Bobby",  last_name: last_name, dob: 8.years.ago,  addresses: [brady_addr.dup], phones: [brady_ph.dup])}
    let(:cindy)  {FactoryGirl.create(:male, first_name: "Cindy",  last_name: last_name, dob: 6.years.ago,  addresses: [brady_addr.dup], phones: [brady_ph.dup])}
    let(:bradys) {[mike, carol, greg, marcia, peter, jan, bobby, cindy]}
    let!(:mikes_family) do
      family = FactoryGirl.create(:family)
      family.family_members << FactoryGirl.build(:family_member, :primary, family: family, person: mike)
      (bradys - [mike]).each do |brady|
        family.family_members << FactoryGirl.build(:family_member, family: family, person: brady)
      end
      family.save
      family
    end
    let!(:carols_family) do
      family = FactoryGirl.create(:family)
      family.family_members << FactoryGirl.build(:family_member, :primary, family: family, person: carol)
      (bradys - [carol]).each do |brady|
        family.family_members << FactoryGirl.build(:family_member, family: family, person: brady)
      end
      family.save
      family
    end

    context "Family.find_by_primary_applicant" do
      context "on Mike" do
        let(:find) {Family.find_by_primary_applicant(mike)}
        it "should find Mike's family" do
          expect(find.id.to_s).to eq mikes_family.id.to_s
        end
      end

      context "on Carol" do
        let(:find) {Family.find_by_primary_applicant(carol)}
        it "should find Carol's family" do
          expect(find.id.to_s).to eq carols_family.id.to_s
        end
      end
    end

    context "Family.find_by_person" do
      context "on Mike" do
        let(:find) {Family.find_all_by_person(mike).collect(&:id)}
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
        let(:find) {Family.find_all_by_person(carol).collect(&:id)}
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
        let(:find) {Family.find_all_by_person(greg).collect(&:id)}
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
