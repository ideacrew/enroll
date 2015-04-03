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
    include_context "BradyBunch"

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

describe "update_household callback" do
    let!(:primary_person) { FactoryGirl.create(:person, :male) }
    let!(:second_person) { FactoryGirl.create(:person) }
    let!(:new_family) { FactoryGirl.build(:family) }
    let!(:first_primary_member) { FactoryGirl.create(:family_member, :primary, family: new_family, person: primary_person) }

    context "family is saved" do


      it "should create a household" do
        expect(new_family.save).to be_truthy
        expect(new_family.households.length).to eq(1)
      end

      it "should create a coverage_household" do
        expect(new_family.save).to be_truthy
        expect(new_family.active_household.coverage_households.length).to eq(1)
      end

      it "should create a member in coverage_household" do
        expect(new_family.save).to be_truthy
        expect(new_family.active_household.coverage_households.first.coverage_household_members.length).to eq(1)
      end

      context "family has multiple family members" do
        let!(:second_member) { FactoryGirl.create(:family_member, family: new_family, person: second_person) }
        it "should create coverage_household with 2 members (self and spouse)" do
          new_family.family_members.first.person.person_relationships << PersonRelationship.new({kind: 'spouse', relative_id: second_person.id})
          expect(new_family.save).to be_truthy
          expect(new_family.active_household.coverage_households.first.coverage_household_members.length).to eq(2)
        end

        it "should create one coverage_household for valid family_member (relationships) and another for the rest " do
          new_family.family_members.first.person.person_relationships << PersonRelationship.new({kind: 'brother', relative_id: second_person.id})
          expect(new_family.save).to be_truthy
          expect(new_family.active_household.coverage_households.length).to eq(2)
        end
      end


      it "should create a hbx_enrollment" do
        plan = FactoryGirl.create(:directory_plan)
        enrollee = Enrollee.new({person: primary_person, coverage_start_on: Date.today})
        policy = FactoryGirl.create(:policy, plan: plan, enrollees: [enrollee])

        expect(new_family.save).to be_truthy
        expect(new_family.active_household.hbx_enrollments.length).to eq(1)
      end
    end


    context "family is updated" do

      it "should create coverage_household with the new family member" do
        second_member = FactoryGirl.create(:family_member, family: new_family, person: second_person)
        new_family.family_members.first.person.person_relationships << PersonRelationship.new({kind: 'spouse', relative_id: second_person.id})

        expect(new_family.save).to be_truthy
        expect(new_family.active_household.coverage_households.length).to eq(1)
        expect(new_family.active_household.coverage_households.first.coverage_household_members.length).to eq(2)
      end

      it "should create coverage_household when a family member removed" do
        second_member = FactoryGirl.create(:family_member, family: new_family, person: second_person)
        new_family.family_members.first.person.person_relationships << PersonRelationship.new({kind: 'brother', relative_id: second_person.id})
        new_family.family_members.last.delete

        expect(new_family.save).to be_truthy
        expect(new_family.active_household.coverage_households.length).to eq(1)
        expect(new_family.active_household.coverage_households.first.coverage_household_members.length).to eq(1)
      end

      context "all family members removed" do
        it "should have no coverage_household and no hbx_enrollment" do

          #adding a policy, hence a hbx_enrollment
          plan = FactoryGirl.create(:directory_plan)
          enrollee = Enrollee.new({person: primary_person, coverage_start_on: Date.today})
          policy = FactoryGirl.create(:policy, plan: plan, enrollees: [enrollee])

          new_family.family_members.each(&:delete) #delete all family members

          expect(new_family.save).to be_truthy
          expect(new_family.active_household.coverage_households.blank?).to be_truthy
          expect(new_family.active_household.hbx_enrollments.blank?).to be_truthy
        end
      end
    end
  end
end
