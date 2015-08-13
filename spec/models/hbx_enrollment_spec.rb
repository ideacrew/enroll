require 'rails_helper'

describe HbxEnrollment do
  context "an employer defines a plan year with multiple benefit groups, adds employees to roster and assigns benefit groups" do
    let(:blue_collar_employee_count)              { 7 }
    let(:white_collar_employee_count)             { 5 }
    let(:fte_count)                               { blue_collar_employee_count + white_collar_employee_count }
    let(:employer_profile)                        { FactoryGirl.create(:employer_profile) }

    let(:plan_year_start_on)                      { Date.current.next_month.end_of_month + 1.day }
    let(:plan_year_end_on)                        { (plan_year_start_on + 1.year) - 1.day }

    let(:blue_collar_benefit_group)               { plan_year.benefit_groups[0] }
    def blue_collar_benefit_group_assignment
      BenefitGroupAssignment.new(benefit_group: blue_collar_benefit_group, start_on: plan_year_start_on )
    end

    let(:white_collar_benefit_group)              { plan_year.benefit_groups[1] }
    def white_collar_benefit_group_assignment
      BenefitGroupAssignment.new(benefit_group: white_collar_benefit_group, start_on: plan_year_start_on )
    end

    let(:all_benefit_group_assignments)           { [blue_collar_census_employees, white_collar_census_employees].flat_map do |census_employees|
                                                      census_employees.flat_map(&:benefit_group_assignments)
                                                    end
                                                  }
    let(:plan_year)                               { py = FactoryGirl.create(:plan_year,
                                                      start_on: plan_year_start_on,
                                                      end_on: plan_year_end_on,
                                                      open_enrollment_start_on: Date.current,
                                                      open_enrollment_end_on: Date.current + 5.days,
                                                      employer_profile: employer_profile
                                                    )
                                                    blue = FactoryGirl.build(:benefit_group, title: "blue collar", plan_year: py)
                                                    white = FactoryGirl.build(:benefit_group, title: "white collar", plan_year: py)
                                                    py.benefit_groups = [blue, white]
                                                    py.save
                                                    py
                                                  }
    let!(:blue_collar_census_employees)            { ees = FactoryGirl.create_list(:census_employee, blue_collar_employee_count, employer_profile: employer_profile)
                                                     ees.each() do |ee|
                                                       ee.benefit_group_assignments = [blue_collar_benefit_group_assignment]
                                                       ee.save
                                                     end
                                                     ees
                                                    }
    let!(:white_collar_census_employees)           { ees = FactoryGirl.create_list(:census_employee, white_collar_employee_count, employer_profile: employer_profile)
                                                     ees.each() do |ee|
                                                       ee.benefit_group_assignments = [white_collar_benefit_group_assignment]
                                                       ee.save
                                                     end
                                                     ees
                                                    }

    before do
      plan_year.publish!
    end

    it "should have a valid plan year in published state" do
      expect(plan_year.aasm_state).to eq "enrolling"
    end

    it "should have a roster with all blue and white collar employees" do
      expect(employer_profile.census_employees.size).to eq fte_count
    end

    context "and employees create employee roles and families" do
      let(:blue_collar_employee_roles) do
        bc_employees = blue_collar_census_employees.collect do |census_employee|
          person = Person.create!(
                    first_name: census_employee.first_name,
                    last_name: census_employee.last_name,
                    ssn: census_employee.ssn,
                    dob: census_employee.dob,
                    gender: "male"
                  )
          employee_role = person.employee_roles.build(
                    employer_profile: census_employee.employer_profile,
                    census_employee: census_employee,
                    hired_on: census_employee.hired_on
                  )

          census_employee.employee_role = employee_role
          census_employee.save!
          employee_role
        end
        bc_employees
      end

      let(:white_collar_employee_roles) do
        wc_employees = white_collar_census_employees.collect do |census_employee|
          person = Person.create!(
                    first_name: census_employee.first_name,
                    last_name: census_employee.last_name,
                    ssn: census_employee.ssn,
                    # ssn: (census_employee.ssn.to_i + 20).to_s,
                    dob: census_employee.dob,
                    gender: "male"
                  )
          employee_role = person.employee_roles.build(
                    employer_profile: census_employee.employer_profile,
                    census_employee: census_employee,
                    hired_on: census_employee.hired_on
                  )

          census_employee.employee_role = employee_role
          census_employee.save!
          employee_role
        end
        wc_employees
      end

      let(:blue_collar_families) do
        blue_collar_employee_roles.reduce([]) { |list, employee_role| family = Family.find_or_build_from_employee_role(employee_role); list << family }
      end

      let(:white_collar_families) do
        white_collar_employee_roles.reduce([]) { |list, employee_role| family = Family.find_or_build_from_employee_role(employee_role); list << family }
      end

      it "should include the requisite blue collar employee roles and families" do
        expect(blue_collar_employee_roles.size).to eq blue_collar_employee_count
        expect(blue_collar_families.size).to eq blue_collar_employee_count
      end

      it "should include the requisite white collar employee roles and families" do
        expect(white_collar_employee_roles.size).to eq white_collar_employee_count
        expect(white_collar_families.size).to eq white_collar_employee_count
      end

      context "and families either select plan or waive coverage" do
        let!(:blue_collar_enrollment_waivers) do
          family = blue_collar_families.first
          employee_role = family.primary_family_member.person.employee_roles.first
          election = HbxEnrollment.create_from(
              employee_role: employee_role,
              coverage_household: family.households.first.coverage_households.first,
              benefit_group: employee_role.census_employee.active_benefit_group_assignment.benefit_group
            )
          election.waiver_reason = HbxEnrollment::WAIVER_REASONS.first
          election.waive_coverage
          election.household.family.save!
          election.save!
          election.to_a
        end

        let!(:blue_collar_enrollments) do
          enrollments = blue_collar_families[1..(blue_collar_employee_count - 1)].collect do |family|
            employee_role = family.primary_family_member.person.employee_roles.first
            benefit_group = employee_role.census_employee.active_benefit_group_assignment.benefit_group
            election = HbxEnrollment.create_from(
                employee_role: employee_role,
                coverage_household: family.households.first.coverage_households.first,
                benefit_group: benefit_group
              )
            election.plan = benefit_group.elected_plans.sample
            election.select_coverage if election.can_complete_shopping?
            election.household.family.save!
            election.save!
            election
          end
          enrollments
        end

        let!(:white_collar_enrollment_waivers) do
          white_collar_families[0..1].collect do |family|
            employee_role = family.primary_family_member.person.employee_roles.first
            election = HbxEnrollment.create_from(
              employee_role: employee_role,
              coverage_household: family.households.first.coverage_households.first,
              benefit_group: employee_role.census_employee.active_benefit_group_assignment.benefit_group
            )
            election.waiver_reason = HbxEnrollment::WAIVER_REASONS.first
            election.waive_coverage
            election.household.family.save!
            election.save!
            election
          end
        end

        let!(:white_collar_enrollments) do
          white_collar_families[-3..-1].collect do |family|
            employee_role = family.primary_family_member.person.employee_roles.first
            benefit_group = employee_role.census_employee.active_benefit_group_assignment.benefit_group
            election = HbxEnrollment.create_from(
                employee_role: employee_role,
                coverage_household: family.households.first.coverage_households.first,
                benefit_group: benefit_group
              )
            election.plan = benefit_group.elected_plans.sample
            election.select_coverage if election.can_complete_shopping?
            election.household.family.save!
            election.save!
            election
          end
        end

        it "should find all employees who have waived or selected plans" do
          enrollments = HbxEnrollment.find_by_benefit_groups(all_benefit_group_assignments.collect(&:benefit_group))
          expect(enrollments.size).to eq (blue_collar_employee_count + white_collar_employee_count)
          expect(enrollments).to match_array(blue_collar_enrollment_waivers + white_collar_enrollment_waivers + blue_collar_enrollments + white_collar_enrollments)
        end

        it "should know the total premium" do
          expect(blue_collar_enrollments.first.total_premium).to be
        end

        it "should know the total employee cost" do
          expect(blue_collar_enrollments.first.total_employee_cost).to be
        end

        it "should know the total employer contribution" do
          expect(blue_collar_enrollments.first.total_employer_contribution).to be
        end

        context "covered" do
          before :each do
            @enrollments = white_collar_enrollments + white_collar_enrollment_waivers + blue_collar_enrollments + blue_collar_enrollment_waivers
          end
          it "should return only covered enrollments count" do
            expect(HbxEnrollment.covered(@enrollments).size).to eq 9
          end

          it "should return only active enrollments" do
            white_collar_enrollments.each do |hbx|
              allow(hbx).to receive(:is_active).and_return(false)
            end
            expect(HbxEnrollment.covered(@enrollments).size).to eq (9-white_collar_enrollments.size)
          end
        end
      end

    end
  end
end

describe HbxEnrollment, dbclean: :after_all do
  include_context "BradyWorkAfterAll"

  before :all do
    create_brady_census_families
  end

  context "is created from an employer_profile, benefit_group, and coverage_household" do
    attr_reader :enrollment, :household, :coverage_household
    before :all do
      @household = mikes_family.households.first
      @coverage_household = household.coverage_households.first
      @enrollment = household.create_hbx_enrollment_from(
        employee_role: mikes_employee_role,
        coverage_household: coverage_household,
        benefit_group: mikes_benefit_group
      )
    end

    it "should assign the benefit group assignment" do
      expect(enrollment.benefit_group_assignment_id).not_to be_nil
    end

    it "should be employer sponsored" do
      expect(enrollment.kind).to eq "employer_sponsored"
    end

    it "should set the employer_profile" do
      expect(enrollment.employer_profile._id).to eq mikes_employer._id
    end

    it "should be active" do
      expect(enrollment.is_active?).to be_truthy
    end

    it "should be effective when the plan_year starts by default" do
      expect(enrollment.effective_on).to eq mikes_plan_year.start_on
    end

    it "should be valid" do
      expect(enrollment.valid?).to be_truthy
    end

    it "should default to enrolling everyone" do
      expect(enrollment.applicant_ids).to match_array(coverage_household.applicant_ids)
    end

    it "should not return a total premium" do
      expect{enrollment.total_premium}.not_to raise_error
    end

    it "should not return an employee cost" do
      expect{enrollment.total_employee_cost}.not_to raise_error
    end

    it "should not return an employer contribution" do
      expect{enrollment.total_employer_contribution}.not_to raise_error
    end

    context "and the employee enrolls" do
      before do
        enrollment.plan = enrollment.benefit_group.reference_plan
        enrollment.save
      end

      it "should return a total premium" do
        expect(enrollment.total_premium).to be
      end

      it "should return an employee cost" do
        expect(enrollment.total_employee_cost).to be
      end

      it "should return an employer contribution" do
        expect(enrollment.total_employer_contribution).to be
      end
    end

    context "update_current" do
      before :each do
        @enrollment2 = household.create_hbx_enrollment_from(
          employee_role: mikes_employee_role,
          coverage_household: coverage_household,
          benefit_group: mikes_benefit_group
        )
        @enrollment2.save
        @enrollment2.update_current(is_active: false)
      end

      it "enrollment and enrollment2 should have same household" do
        expect(@enrollment2.household).to eq enrollment.household
      end

      it "enrollment2 should be not active" do
        expect(@enrollment2.is_active).to  be_falsey
      end

      it "enrollment should be active" do
        expect(enrollment.is_active).to be_truthy
      end
    end

    context "inactive_related_hbxs" do
      before :each do
        @enrollment3 = household.create_hbx_enrollment_from(
          employee_role: mikes_employee_role,
          coverage_household: coverage_household,
          benefit_group: mikes_benefit_group
        )
        @enrollment3.save
        @enrollment3.inactive_related_hbxs
      end

      it "should have an assigned hbx_id" do
        expect(@enrollment3.hbx_id).not_to eq nil
      end

      it "enrollment and enrollment3 should have same household" do
        expect(@enrollment3.household).to eq enrollment.household
      end

      it "enrollment should be not active" do
        expect(enrollment.is_active).to  be_falsey
      end

      it "enrollment3 should be active" do
        expect(@enrollment3.is_active).to be_truthy
      end

      it "should only one active when they have same employer" do
        hbxs = @enrollment3.household.hbx_enrollments.select do |hbx|
          hbx.employee_role.employer_profile_id == @enrollment3.employee_role.employer_profile_id and hbx.is_active?
        end
        expect(hbxs.count).to eq 1
      end
    end
  end
end

# describe HbxEnrollment, "#save", type: :model do
#
#   context "SHOP market validations" do
#     context "plan coverage is valid" do
#       context "selected plan is not for SHOP market" do
#         it "should return an error" do
#         end
#       end
#
#       context "selected plan is not offered by employer" do
#         it "should return an error" do
#         end
#       end
#
#       context "selected plan is not active on effective date" do
#         it "should return an error" do
#         end
#       end
#     end
#
#     context "effective date is valid" do
#       context "Special Enrollment Period" do
#       end
#
#       context "open enrollment" do
#       end
#     end
#
#     context "premium is valid" do
#       it "should include a valid total premium amount" do
#       end
#
#       it "should include a valid employer_profile contribution amount" do
#       end
#
#       it "should include a valid employee_role contribution amount" do
#       end
#     end
#
#     context "correct EDI event is created" do
#     end
#
#     context "correct employee_role notice is created" do
#     end
#
#   end
#
#   context "IVL market validations" do
#   end
#
# end
#
# describe HbxEnrollment, ".new", type: :model do
#
#   context "employer_role is enrolling in SHOP market" do
#     context "employer_profile is under open enrollment period" do
#         it "should instantiate object" do
#         end
#     end
#
#     context "outside employer open enrollment" do
#       context "employee_role is under special enrollment period" do
#         it "should instantiate object" do
#         end
#
#       end
#
#       context "employee_role isn't under special enrollment period" do
#         it "should return an error" do
#         end
#       end
#     end
#   end
#
#   context "consumer_role is enrolling in individual market" do
#   end
# end
#
#
# ## Retroactive enrollments??
#
#
# describe HbxEnrollment, "SHOP open enrollment period", type: :model do
#  context "person is enrolling for SHOP coverage" do
#     context "employer is under open enrollment period" do
#
#       context "and employee_role is under special enrollment period" do
#
#         context "and sep coverage effective date preceeds open enrollment effective date" do
#
#           context "and selected plan is for next plan year" do
#             context "and no active coverage exists for employee_role" do
#               context "and employee_role hasn't confirmed 'gap' coverage start date" do
#                 it "should record employee_role confirmation (user & timestamp)" do
#                 end
#               end
#
#               context "and employee_role has confirmed 'gap' coverage start date" do
#                 it "should process enrollment" do
#                 end
#               end
#             end
#           end
#
#           context "and selected plan is for current plan year" do
#             it "should process enrollment" do
#             end
#           end
#
#         end
#
#         context "and sep coverage effective date is later than open enrollment effective date" do
#           context "and today's date is past open enrollment period" do
#             it "and should process enrollment" do
#             end
#           end
#         end
#
#       end
#     end
#   end
# end
#
# describe HbxEnrollment, "SHOP special enrollment period", type: :model do
#
#   context "and person is enrolling for SHOP coverage" do
#
#     context "and outside employer open enrollment" do
#       context "employee_role is under a special enrollment period" do
#       end
#
#       context "employee_role isn't under a special enrollment period" do
#         it "should return error" do
#         end
#       end
#     end
#   end
# end
#
#
# ## Coverage of same type
# describe HbxEnrollment, "employee_role has active coverage", type: :model do
#   context "enrollment is with same employer" do
#
#     context "and new effective date is later than effective date on active coverage" do
#       it "should replace existing enrollment and notify employee_role" do
#       end
#
#       it "should fire an EDI event: terminate coverage" do
#       end
#
#       it "should fire an EDI event: enroll coverage" do
#       end
#
#       it "should trigger notice to employee_role" do
#       end
#     end
#
#     context "and new effective date is later prior to effective date on active coverage"
#       it "should replace existing enrollment" do
#       end
#
#       it "should fire an EDI event: cancel coverage" do
#       end
#
#       it "should fire an EDI event: enroll coverage" do
#       end
#
#       it "should trigger notice to employee_role" do
#       end
#   end
#
#   context "and enrollment coverage is with different employer" do
#     context "and employee specifies enrollment termination with other employer" do
#       it "should send other employer termination request notice" do
#       end
#
#     end
#
#     ### otherwise process enrollment
#   end
#
#   context "active coverage is with person's consumer_role" do
#   end
# end
#
# describe HbxEnrollment, "consumer_role has active coverage", type: :model do
# end
#
# describe HbxEnrollment, "Enrollment renewal", type: :model do
#
#   context "person is enrolling for IVL coverage" do
#
#     context "HBX is under open enrollment period" do
#     end
#
#     context "outside HBX open enrollment" do
#       context "consumer_role is under a special enrollment period" do
#       end
#
#       context "consumer_role isn't under a special enrollment period" do
#       end
#     end
#   end
# end
