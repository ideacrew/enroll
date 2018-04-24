require 'rails_helper'

module BenefitSponsors
  RSpec.describe Members::MemberGroup, type: :model do

    context "A new MemberGroup instance" do
      let(:member_group)  { described_class.new }

      it "should have an empty members list" do
        expect(member_group.members).to eq []
      end

      context "and various add operators are accessed" do
        it "should support <<"
        it "should support []()"
        it "should support []="
      end


      context "and a new Employee primary member is added" do
        let(:employee_member)   { Members::EmployeeMember.new(last_name: "Duck",
                                                              first_name: "Donald",
                                                              dob: Date.new(1934,6,9),
                                                              gender: :male,
                                                              ) }

        before { member_group.add_member(employee_member) }

        it "should add the member to the MemberGroup" do
          expect(member_group.members.size).to eq 1
          expect(member_group.members.first).to eq employee_member
        end

        it "should find the primary member" do
          expect(member_group.primary_member).to eq employee_member
        end



        context "and another Employee primary member is added" do
          let(:another_employee_member)   { Members::EmployeeMember.new(last_name: "McDuck",
                                                                first_name: "Scrouge",
                                                                dob: Date.new(1924,6,9),
                                                                gender: :male,
                                                                ) }

          it "should throw a DuplicatePrimaryMemberError error" do
            expect{member_group.add_member(another_employee_member)}.to raise_error(BenefitSponsors::DuplicatePrimaryMemberError)
          end
        end


        context "and a spouse is added" do
          let(:spouse_dependent_member)   { Members::DependentMember.new(last_name: "Duck",
                                                                first_name: "Daisy",
                                                                dob: Date.new(1934,9,6),
                                                                gender: :female,
                                                                kinship_to_primary_member: :spouse,
                                                                ) }

          before { member_group.add_member(spouse_dependent_member) }

          it "should add the spouse to the MemberGroup" do
            expect(member_group.members.size).to eq 2
            expect(member_group.members).to include(spouse_dependent_member)
          end

          context "and the spouse is removed" do
            it "should remove the member from the group" do
              expect(member_group.members).to include(spouse_dependent_member)
              member_group.drop_member(spouse_dependent_member)
              expect(member_group.members).not_to include(spouse_dependent_member)
            end
          end


          context "and a second spouse is added" do
            let(:another_spouse_dependent_member)   { Members::DependentMember.new(last_name: "Bunny",
                                                                  first_name: "Bugs",
                                                                  dob: Date.new(1955,5,21),
                                                                  gender: :male,
                                                                  kinship_to_primary_member: :domestic_partner,
                                                                  ) }

            it "should throw a MultipleSpouseRelationshipError error" do
              expect{member_group.add_member(another_spouse_dependent_member)}.to raise_error(BenefitSponsors::MultipleSpouseRelationshipError)
            end


          end

        end

      end
    end


  end
end
