require 'rails_helper'

describe Family, type: :model, dbclean: :after_each do

  let(:spouse)  { FactoryGirl.create(:person)}
  let(:person) do
    p = FactoryGirl.build(:person)
    p.person_relationships.build(relative: spouse, kind: "spouse")
    p.save
    p
  end

  let(:family_member_person) { FamilyMember.new(is_primary_applicant: true, is_consent_applicant: true, person: person) }
  let(:family_member_spouse) { FamilyMember.new(person: spouse) }

  context "when built" do
    context "with valid parameters" do
      let(:now) { DateTime.current }
      let(:user)  { "rspec@dchealthlink.com" }
      let(:curam_id) { "6754632abc" }
      let(:e_case_id) { curam_id }
      let(:renewal_consent_through_year) { 2017 }
      let(:submitted_at) { now }
      let(:updated_by) { user }

      let(:valid_params) do
        {
          e_case_id: e_case_id,
          renewal_consent_through_year: renewal_consent_through_year,
          submitted_at: submitted_at,
          updated_by: updated_by
        }
      end

      let(:params)  { valid_params }
      let(:family)  { Family.new(**params) }

      context "and the primary applicant is missing" do
        before do
          family.family_members = [family_member_spouse]
          family.valid?
        end

        it "should not be valid" do
          expect(family.errors[:family_members].any?).to be_truthy
        end
      end

      context "and primary applicant and family members are added" do
        before do
          family.family_members = [family_member_person, family_member_spouse]
          family.save
        end

        it "all the added people are represented as family members" do
          expect(family.family_members.size).to eq 2            
        end

        it "the correct person is primary applicant" do
          expect(family.primary_applicant.person).to eq person
        end

        it "the correct person is consent applicant" do
          expect(family.consent_applicant.person).to eq person
        end

        it "has an irs group" do
          expect(family.irs_groups.size).to eq 1
        end

        it "has a household that is associated with irs group" do
          expect(family.households.size).to eq 1
          expect(family.households.first.irs_group).to eq family.irs_groups.first
        end

        it "is persistable" do
          expect(family.save).to be_truthy
        end

        context "and it is persisted" do
          let!(:saved_family) do
            f = family
            f.save
            f
          end

          it "should be findable" do
            expect(Family.find(saved_family.id).id.to_s).to eq saved_family.id.to_s
          end

          context "and one of the family members is not related to the primary applicant" do
            let(:alice) { FactoryGirl.create(:person, first_name: "alice") }
            let(:non_family_member) { FamilyMember.new(person: alice) }

            before do
              family.family_members << non_family_member
            end

            it "should not be valid" do
              expect(family.errors[:family_members].any?).to be_truthy
            end

            context "and the non-related person is a responsible party" do
              pending "to be added for IVL market"
            end
          end

          context "and one of the same family members is added again" do
            before do
              family.family_members << family_member_spouse.dup
            end

            it "should not be valid" do
              expect(family.errors[:family_members].any?).to be_truthy
            end
          end

          context "and a second primary applicant is added" do
            let(:bob) do
              p = FactoryGirl.create(:person, first_name: "Bob")
              person.person_relationships << PersonRelationship.new(relative: p, kind: "child")
              p
            end

            let(:family_member_child) { FamilyMember.new(is_primary_applicant: true, is_consent_applicant: true, person: bob) }

            before do
              family.family_members << family_member_child
              family.valid?
            end

            it "should not be valid" do
              expect(family.errors[:family_members].any?).to be_truthy
            end
          end

          context "and another family is created with same members" do

            context "and the primary applicant is the same person" do
              let(:second_family) { Family.new }
              before do
                second_family.family_members = [family_member_person.dup, family_member_spouse.dup]
              end

              it "should not be valid" do
                expect(second_family.valid?).to be_falsey
              end
            end

            context "and the primary applicant is not the same person" do
              let(:second_family) { Family.new }
              let(:second_family_member_person) { FamilyMember.new(person: person) }
              let(:second_family_member_spouse) { FamilyMember.new(is_primary_applicant: true, is_consent_applicant: true, person: spouse) }
              before do
                second_family.family_members = [second_family_member_person, second_family_member_spouse]
              end

              it "should be valid" do
                expect(second_family.valid?).to be_truthy
              end
            end
          end
        end
      end
    end
  end

  context "after it's persisted" do
    include_context "BradyBunch"

    context "when you add a family member" do
      it "there is a corresponding coverage household member" do
        covered_bradys = carols_family.households.first.immediate_family_coverage_household.coverage_household_members.collect(){|m| m.family_member.person.full_name}
        expect(covered_bradys).to contain_exactly(*bradys.collect(&:full_name))
      end
    end
  end

  ## TODO: Add method
  # describe HbxEnrollment, "#is_enrollable?", type: :model do
  #   context "family is under open enrollment period" do
  #     it "should return true" do
  #     end
  #
  #     context "and employee_role is under Special Enrollment Period" do
  #       it "should return true" do
  #       end
  #     end
  #   end
  #
  #   context "employee_role is under Special Enrollment Period" do
  #     it "should return true" do
  #     end
  #   end
  #
  #   context "outside family open enrollment" do
  #     it "should return false" do
  #     end
  #   end
  #
  #   context "employee_role is not under SEP" do
  #     it "should return false" do
  #     end
  #   end
  # end

  describe "special enrollment periods" do
    include_context "BradyBunch"

    let(:family) { mikes_family }
    let(:current_sep) { FactoryGirl.build(:special_enrollment_period) }
    let(:another_current_sep) { FactoryGirl.build(:special_enrollment_period, qle_on: 4.days.ago.to_date) }
    let(:expired_sep) { FactoryGirl.build(:special_enrollment_period, :expired) }

    context "family has never had a special enrollment period" do
      it "should indicate no active SEPs" do
        expect(family.is_under_special_enrollment_period?).to be_falsey
      end

      it "current_special_enrollment_periods should return []" do
        expect(family.current_special_enrollment_periods).to eq []
      end
    end

    context "family has a past QLE, but Special Enrollment Period has expired" do
      before do
        family.special_enrollment_periods << expired_sep
        family.save
      end

      it "should have the SEP instance" do
        expect(family.special_enrollment_periods.size).to eq 1
      end

      it "should return a SEP class" do
        expect(family.special_enrollment_periods.first).to be_a SpecialEnrollmentPeriod
      end

      it "should indicate no active SEPs" do
        expect(family.is_under_special_enrollment_period?).to be_falsey
      end

      it "current_special_enrollment_periods should return []" do
        expect(family.current_special_enrollment_periods).to eq []
      end
    end

    context "family has a QLE and is under a SEP" do
      before do
        family.special_enrollment_periods << current_sep
        family.save
      end

      it "should indicate SEP is active" do
        expect(family.is_under_special_enrollment_period?).to be_truthy
      end

      it "should return one current_special_enrollment" do
        expect(family.current_special_enrollment_periods.size).to eq 1
        expect(family.current_special_enrollment_periods.first).to eq current_sep
      end

      context "and the family is under more than one SEP" do
        before do
          family.special_enrollment_periods << another_current_sep
          family.save
        end
        it "should return multiple current_special_enrollment" do
          expect(family.current_special_enrollment_periods.size).to eq 2
        end
      end
    end

    pending "TODO"
    context "attempt to add new SEP with same QLE and date as existing SEP" do
      before do
      end

      it "should not save as a duplicate" do
      end
    end
  end

  describe "large family with multiple employees - The Brady Bunch" do
    include_context "BradyBunch"

    let(:family_member_id) {mikes_family.primary_applicant.id}

    it "should be possible to find the family_member from a family_member_id" do
      expect(Family.find_family_member(family_member_id).id.to_s).to eq family_member_id.to_s
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


describe Family, ".find_or_build_from_employee_role:", type: :model, dbclean: :after_each do

  let(:submitted_at)  { DateTime.current}
  let(:spouse)        { FactoryGirl.create(:person, last_name: "richards", first_name: "denise") }
  let(:child)         { FactoryGirl.create(:person, last_name: "sheen", first_name: "sam") }
  let(:grandpa)       { FactoryGirl.create(:person, last_name: "sheen", first_name: "martin") }

  let(:married_relationships) { [PersonRelationship.new(relative: spouse, kind: "spouse"),
                                 PersonRelationship.new(relative: child, kind: "child")] }
  let(:family_relationships)  {  married_relationships <<
                                 PersonRelationship.new(relative: grandpa, kind: "grandparent") }

  let(:single_dude)   { FactoryGirl.create(:person, last_name: "sheen", first_name: "tigerblood") }
  let(:married_dude)  { FactoryGirl.create(:person, last_name: "sheen", first_name: "chuck",
                                           person_relationships: married_relationships ) }
  let(:family_dude)   { FactoryGirl.create(:person, last_name: "sheen", first_name: "charles",
                                           person_relationships: family_relationships ) }

  let(:single_employee_role)    { FactoryGirl.create(:employee_role, person: single_dude) }
  let(:married_employee_role)   { FactoryGirl.create(:employee_role, person: married_dude) }
  let(:family_employee_role)    { FactoryGirl.create(:employee_role, person: family_dude) }

  let(:single_family)          { Family.find_or_build_from_employee_role(single_employee_role) }
  let(:married_family)         { Family.find_or_build_from_employee_role(married_employee_role) }
  let(:large_family)           { Family.find_or_build_from_employee_role(family_employee_role) }


  context "when no families exist" do
    context "and employee is single" do

      it "should create one family_member with set attributes" do
        expect(single_family.family_members.size).to eq 1
        expect(single_family.family_members.first.is_primary_applicant).to eq true
        expect(single_family.family_members.first.is_coverage_applicant).to eq true
        expect(single_family.family_members.first.person).to eq single_employee_role.person
      end

      it "and create a household and associated IRS group" do
        expect(single_family.irs_groups.size).to eq 1
        expect(single_family.households.size).to eq 1
        expect(single_family.households.first.irs_group).to eq single_family.irs_groups.first
      end

      it "and create a coverage_household with one family_member" do
        expect(single_family.households.first.coverage_households.size).to eq 1
        expect(single_family.households.first.coverage_households.first.coverage_household_members.first.family_member).to eq single_family.family_members.first
      end
    end

    context "and employee has spouse and child" do
      it "creates one coverage_household with all family members" do
        expect(married_family.households.first.coverage_households.size).to eq 1
      end

      it "and all family_members are members of this coverage_household" do
        expect(married_family.family_members.size).to eq 3
        expect(married_family.households.first.coverage_households.first.coverage_household_members.size).to eq 3

        expect(married_family.households.first.coverage_households.first.coverage_household_members.where(family_member_id: married_family.family_members[0]._id)).not_to be_nil
        expect(married_family.households.first.coverage_households.first.coverage_household_members.where(family_member_id: married_family.family_members[1]._id)).not_to be_nil
        expect(married_family.households.first.coverage_households.first.coverage_household_members.where(family_member_id: married_family.family_members[2]._id)).not_to be_nil
      end
    end

    context "and family includes extended family relationships" do

      it "creates two coverage households" do
        expect(large_family.households.first.coverage_households.size).to eq 2
      end

      it "and immediate family is in one coverage household" do
        immediate_family_coverage_household = large_family.households.first.coverage_households.where(:is_immediate_family => true).first
        expect(immediate_family_coverage_household.coverage_household_members.size).to eq 3
      end

      it "and extended family is in a second coverage household" do
        extended_family_coverage_household =  large_family.households.first.coverage_households.where(:is_immediate_family => false).first
        expect(extended_family_coverage_household.coverage_household_members.size).to eq 1
        # expect(extended_family_coverage_household.coverage_household_members.first.).to eq 1
      end

    end
  end

  context "family already exists with employee_role as primary_family_member" do
    let(:existing_primary_member) {existing}
    let(:existing_family) { FactoryGirl.create(:family)}

    it "should return the family for this employee_role" 
  end

end

describe Family, "given an inactive member" do
  describe "given search criteria for that member which matches" do
    it "should find the member"
  end

  describe "given search criteria for that member which does not match" do
    it "should not find the member"
  end
end

describe Family, "with a primary applicant" do
  describe "given a new person and relationship to make to the primary applicant" do
    it "should relate the person and create the family member"
  end
end
