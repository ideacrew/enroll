require 'rails_helper'

# Should only be one active employee_family per employer at one time
# terminate employee must set the employee family inactive
# replicate_for_rehire_for_rehire

describe EmployerCensus::EmployeeFamily, type: :model, dbclean: :after_each do
  it { should validate_presence_of :census_employee }

  let(:employer_profile) {FactoryGirl.create(:employer_profile)}
  let(:census_employee) {FactoryGirl.build(:employer_census_employee)}

  describe ".new" do
    let(:valid_params) do
      {
        employer_profile: employer_profile,
        census_employee: census_employee
      }
    end

    context "with no arguments" do
      let(:params) {{}}

      it "should not save" do
        expect(EmployerCensus::EmployeeFamily.new(**params).save).to be_falsey
      end
    end

    context "with no employer_profile" do
      let(:params) {valid_params.except(:employer_profile)}

      it "should raise" do
        expect{EmployerCensus::EmployeeFamily.create(**params)}.to raise_error(Mongoid::Errors::NoParent)
      end
    end

    context "with no census_employee" do
      let(:params) {valid_params.except(:census_employee)}

      it "should fail validation" do
        expect(EmployerCensus::EmployeeFamily.create(**params).errors[:census_employee].any?).to be_truthy
      end
    end

    context "with all required data" do
      let(:params) {valid_params}
      let(:census_family) {EmployerCensus::EmployeeFamily.new(**params)}

      it "should successfully save" do
        expect(census_family.save).to be_truthy
      end


      context "and it is saved" do
        before do
          census_family.save
        end

        it "should return instance of employerprofile when parent method is called" do
          expect(census_family.parent).to be_an_instance_of EmployerProfile
        end

        it "should not be linked" do
          expect(census_family.is_linked?).to be_falsey
        end

      end
    end
  end
end

describe EmployerCensus::EmployeeFamily, 'class methods', dbclean: :after_each do
  def employer_profile; FactoryGirl.create(:employer_profile); end
  def employee_family;  FactoryGirl.create(:employer_census_family, employer_profile: employer_profile); end
  def census_employee;  employee_family.census_employee; end
  def employee_role;    FactoryGirl.build(:employee_role, ssn: census_employee.ssn, dob: census_employee.dob); end

  describe ".id" do
    it "should return nil if no census family present " do
      expect(EmployerCensus::EmployeeFamily.find(EmployerCensus::EmployeeFamily.new.id)).to be_nil
    end
    it "should return census family object" do
      expect(EmployerCensus::EmployeeFamily.find(employee_family.id)).to be_an_instance_of EmployerCensus::EmployeeFamily
    end
  end

  describe ".find_by_employee_role" do
    context "and there's no matching employee_role in employee_families" do
      it "should return nil" do
        expect(EmployerCensus::EmployeeFamily.find_by_employee_role(employee_role)).to be_nil
      end
    end

    context "and a matching employee_role exists" do
      let!(:saved_employee_role) do
        employee_role.save
        employee_role
      end

      context "and employee_role is not linked to census_family" do
        it "should return nil" do
          expect(EmployerCensus::EmployeeFamily.find_by_employee_role(saved_employee_role)).to be_nil
        end
      end

      context "and employee_role is linked to census_family" do
        let(:benefit_group)             { FactoryGirl.create(:benefit_group)}
        let(:benefit_group_assignment)  { EmployerCensus::BenefitGroupAssignment.new(
                                            benefit_group: benefit_group, 
                                            start_on: Date.current - 45.days
                                          ) }
        let(:linked_employee_family) do
          lf = employee_family
          lf.add_benefit_group_assignment(benefit_group_assignment)
          lf.link_employee_role(saved_employee_role)
          lf
        end

        it "should return matching EmployeeFamily instance" do
          expect(linked_employee_family.is_linked?).to be_truthy
          linked_employee_family.save
          # expect(linked_employee_family).to eq ""
          expect(EmployerCensus::EmployeeFamily.find_by_employee_role(saved_employee_role)).to be_an_instance_of EmployerCensus::EmployeeFamily
          expect(EmployerCensus::EmployeeFamily.find_by_employee_role(saved_employee_role).census_employee.ssn.to_i).to eq employee_role.ssn.to_i-1
        end
      end
    end
  end
end

describe EmployerCensus::EmployeeFamily, "that exists for an employer and has no assigned benefit group" do
  let(:census_family)               { EmployerCensus::EmployeeFamily.new }

  let(:benefit_group_1)             { FactoryGirl.build(:benefit_group)}
  let(:benefit_group_assignment_1)  { EmployerCensus::BenefitGroupAssignment.new(
    benefit_group: benefit_group_1, 
    start_on: Date.current - 45.days
  ) }
  let(:employee_role) { double }

  it "should assign a new benefit group when asked" do
    census_family.add_benefit_group_assignment(benefit_group_assignment_1)
    expect(census_family.benefit_group_assignments.size).to eq 1
    expect(census_family.benefit_group_assignments.first.benefit_group).to eq benefit_group_1
    expect(census_family.active_benefit_group_assignment).to eq benefit_group_assignment_1
  end

  it "should not be linkable" do
    expect(census_family.is_linkable?).to be_falsey
  end

  it "should raise an error if you try to link it to an employee_role" do
    expect{census_family.link_employee_role(employee_role)}.to raise_error(EmployeeFamilyLinkError)
  end
end

describe EmployerCensus::EmployeeFamily, 'that exists for an employer and is already assigned a benefit group' do
  let(:census_employee) { EmployerCensus::Employee.new }
  let(:census_family)               { 
    EmployerCensus::EmployeeFamily.new(
      :census_employee => census_employee
    )
  }
  let(:benefit_group_1)             { FactoryGirl.build(:benefit_group)}
  let(:benefit_group_assignment_1)  { EmployerCensus::BenefitGroupAssignment.new(
    benefit_group: benefit_group_1, 
    start_on: Date.current - 45.days
  ) }
        let(:start_on)                    { Date.current - 5.days }
        let(:end_on)                      { start_on - 1.day }
        let(:benefit_group_2)             { FactoryGirl.build(:benefit_group)}
        let(:benefit_group_assignment_2)  { EmployerCensus::BenefitGroupAssignment.new(
          benefit_group: benefit_group_2, 
          start_on: start_on
        ) }

  before :each do
    census_family.add_benefit_group_assignment(benefit_group_assignment_1)
  end

  it "should be linkable" do
    expect(census_family.is_linkable?).to be_truthy
  end

  describe "after another benefit group is added" do
    before :each do
      census_family.add_benefit_group_assignment(benefit_group_assignment_2)
    end

        it "should add the new benefit group assignment" do
          expect(census_family.benefit_group_assignments.size).to eq 2
        end

        it "should inactivate the prior benefit group assignment and set the end date" do
          expect(census_family.inactive_benefit_group_assignments.first.is_active?).to be_falsey
          expect(census_family.inactive_benefit_group_assignments.first.end_on).to eq end_on
          expect(census_family.active_benefit_group_assignment).to eq benefit_group_assignment_2
        end
  end

end

describe EmployerCensus::EmployeeFamily, "that is already linked" do
  let(:census_family) { EmployerCensus::EmployeeFamily.new(:employee_role_id => "WHATEVERDUDE") }
  let(:employee_role) { double }

  it "should not be linkable" do
    expect(census_family.is_linkable?).to be_falsey
  end

  it "should raise an error if you try to link it to an employee_role" do
    expect{census_family.link_employee_role(employee_role)}.to raise_error(EmployeeFamilyLinkError)
  end
end

describe EmployerCensus::EmployeeFamily, "with a terminated employee" do
  let(:census_employee) { EmployerCensus::Employee.new }
  let(:census_family) { EmployerCensus::EmployeeFamily.new(:employee_role_id => "WHATEVERDUDE", :census_employee => census_employee) }
  let(:employee_role) { double }

  before :each do
    census_family.terminate!(Date.today)
  end

  it "should be terminated" do
    expect(census_family.terminated?).to be_truthy
  end

  it "should not be linkable" do
    expect(census_family.is_linkable?).to be_falsey
  end

  it "should raise an error if you try to link it to an employee_role" do
    expect{census_family.link_employee_role(employee_role)}.to raise_error(EmployeeFamilyLinkError)
  end
end

describe EmployerCensus::EmployeeFamily, 'instance methods:', dbclean: :after_each do

  let(:employer_profile)            { FactoryGirl.create(:employer_profile) }
  let(:employee_role)               { FactoryGirl.build(:employee_role) }
  let(:census_family)               { EmployerCensus::EmployeeFamily.new(
    :census_employee => FactoryGirl.build(:employer_census_employee),
    :terminated => false
  )
  } 
  let(:census_employee)             { census_family.census_employee }

  let(:benefit_group_1)             { FactoryGirl.create(:benefit_group)}
  let(:benefit_group_assignment_1)  { EmployerCensus::BenefitGroupAssignment.new(
    benefit_group: benefit_group_1, 
    start_on: Date.current - 45.days
  ) }

  context 'a valid employee family exists in the employer census' do

    context 'and an employee => employee_role link is requested' do

      context "and the employee is terminated" do
        before do
          census_family.add_benefit_group_assignment(benefit_group_assignment_1)
          census_family.terminate(Date.today)
        end

        it "should raise an error" do
          expect{census_family.link_employee_role(employee_role)}.to raise_error(EmployeeFamilyLinkError)
        end
      end

      ## These should prevent enrollment, not ability to link
      # context "and the eligibility date is too far in future" do
      #   pending "use HbxProfile:ShopMaximumEnrollmentPeriodBeforeEligibilityInDays"
      #   it "should raise an error" do
      #   end
      # end

      # context "and the employee isn't under any special enrollment period" do
      #   pending "use HbxProfile:ShopMinimumEnrollmentPeriodAfterRosterEntryInDays"
      #   context "and the employee's roster entry wasn't timely" do
      #   end
      # end

      context "with a valid employee" do
        before do
          employer_profile.employee_families = [census_family]
          census_family.add_benefit_group_assignment(benefit_group_assignment_1)
          census_family.link_employee_role(employee_role)
        end

        it 'should link to the employee' do
          expect(census_family.is_linked?).to be_truthy
          expect(census_family.is_linkable?).to be_falsey
          expect(census_family.employee_role_id).to eq employee_role.id
          expect(employer_profile.employee_families.first.employee_role_id).to eq employee_role._id
        end
      end
    end
  end

  # describe "#delink_employee_role" do

  #   context "and it isn't linked" do
  #     it "should return the employee_family" do
  #       expect(census_family.delink_employee_role).to be_an_instance_of EmployerCensus::EmployeeFamily
  #     end
  #   end

  #   context "and it is linked" do
  #     before do
  #       census_family.link_employee_role(employee_role)
  #     end

  #     it "should make it linkable" do
  #       expect(census_family.delink_employee_role.is_linkable?).to be_truthy
  #     end
  #   end
  # end

  describe '#terminate and #terminate!' do
    let(:valid_termination_date) {(Date.today - maximum_retroactive_termination).beginning_of_month}
    let(:maximum_retroactive_termination) {HbxProfile::ShopRetroactiveTerminationMaximumInDays}

    context "termination date > HBX policy for retro terms" do
      let(:overdue_termination_date) { valid_termination_date - 1.day}

      context "user role isn't an HBX admin" do
        context "and terminate! is called" do
          it "should raise an error" do
            expect{census_family.terminate!(overdue_termination_date)}.to raise_error(HbxPolicyError)
          end
        end

        context "and terminate is called" do
          it "should return nil" do
            expect(census_family.terminate(overdue_termination_date)).to be_nil
          end
        end
      end

      context "user role is HBX admin" do
        pending "add HBX admin role authorization to override"
        it "should terminate employee" do
          expect(census_family.terminate(valid_termination_date).is_terminated?).to be_truthy
        end
      end
    end

    context "termination date is valid for retro terms" do
      it "should return terminated employee" do
        expect(census_family.terminate(valid_termination_date).is_terminated?).to be_truthy
      end
    end
  end

  describe '#replicate_for_rehire' do
    it 'copies the family to new instance if the employee is rehired.' do
      census_family.census_employee.hired_on = Date.today - 1.year
      census_family.census_employee.terminated_on = Date.today - 10.days
      census_family.terminated = true
      ditto = census_family.replicate_for_rehire
      expect(ditto).to be_an_instance_of EmployerCensus::EmployeeFamily
      expect(ditto.employee_role_id).to be_nil
      expect(ditto.is_active?).to eq false
      expect(ditto.is_linked?).to eq false

      expect(ditto.census_employee).to eq census_employee
      expect(ditto.census_employee.hired_on).to be_nil
      expect(ditto.census_employee.terminated_on).to be_nil
      expect(ditto.census_employee.address).to eq census_employee.address
    end

    it "does not copy if the employee is already present." do
      ditto = census_family.replicate_for_rehire
      ditto.census_employee.hired_on = 1.year.ago
      employer_profile.employee_families = [ditto]
      employer_profile.save

      ditto_1 = census_family.replicate_for_rehire
      expect(census_family.is_active?).to eq true
      expect(ditto_1).to be_nil
      # expect{census_family.replicate_for_rehire}.to raise_error("EmployerCensus::EmployeeFamily instance is already active")
    end
  end
end
