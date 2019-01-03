require 'rails_helper'
require 'aasm/rspec'

describe HbxEnrollment, dbclean: :after_all do

  context "an employer defines a plan year with multiple benefit groups, adds employees to roster and assigns benefit groups" do
    let(:blue_collar_employee_count)              { 7 }
    let(:white_collar_employee_count)             { 5 }
    let(:fte_count)                               { blue_collar_employee_count + white_collar_employee_count }
    let(:employer_profile)                        { FactoryGirl.create(:employer_profile) }

    let(:plan_year_start_on)                      { TimeKeeper.date_of_record.next_month.end_of_month + 1.day }
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
    let!(:plan_year)                               { py = FactoryGirl.create(:renewing_draft_plan_year
                                                                             )
                                                     blue = FactoryGirl.build(:benefit_group, title: "blue collar", plan_year: py)
                                                     white = FactoryGirl.build(:benefit_group, title: "white collar", plan_year: py)
                                                     py.benefit_groups = [blue, white]
                                                    #  py.save
                                                    #  py
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


      context "and families either select plan or waive coverage" do
        let!(:blue_collar_enrollment_waivers) do
          family = blue_collar_families.first
          employee_role = family.primary_family_member.person.employee_roles.first
          election = HbxEnrollment.create_from(
            employee_role: employee_role,
            coverage_household: family.households.first.coverage_households.first,
            benefit_group_assignment: employee_role.census_employee.active_benefit_group_assignment,
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
              benefit_group_assignment: employee_role.census_employee.active_benefit_group_assignment,
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
              benefit_group_assignment: employee_role.census_employee.active_benefit_group_assignment,
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
              benefit_group_assignment: employee_role.census_employee.active_benefit_group_assignment,
              benefit_group: benefit_group
            )
            election.plan = benefit_group.elected_plans.sample
            election.select_coverage if election.can_complete_shopping?
            election.household.family.save!
            election.save!
            election
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
        benefit_group: mikes_benefit_group,
        benefit_group_assignment: @mikes_benefit_group_assignments
      )
    end

    context "update_current" do
      before :all do
        @enrollment2 = household.create_hbx_enrollment_from(
          employee_role: mikes_employee_role,
          coverage_household: coverage_household,
          benefit_group: mikes_benefit_group,
          benefit_group_assignment: @mikes_benefit_group_assignments
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
  end 
end