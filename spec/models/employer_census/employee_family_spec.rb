require 'rails_helper'

describe EmployerCensus::EmployeeFamily, type: :model do
  it { should validate_presence_of :census_employee }

  let(:employer) {FactoryGirl.create(:employer)}
  let(:census_employee) {FactoryGirl.build(:employer_census_employee)}

  describe ".new" do
    let(:valid_params) do
      { 
        employer: employer,
        census_employee: census_employee
      }
    end

    context "with no arguments" do
      let(:params) {{}}

      it "should not save" do
        expect(EmployerCensus::EmployeeFamily.new(**params).save).to be_false
      end
    end

    context "with no employer" do
      let(:params) {valid_params.except(:employer)}

      it "should raise" do
        expect{EmployerCensus::EmployeeFamily.create(**params)}.to raise_error(Mongoid::Errors::NoParent)
      end
    end

    context "with no census_employee" do
      let(:params) {valid_params.except(:census_employee)}

      it "should fail validation" do
        expect(EmployerCensus::EmployeeFamily.create(**params).errors[:census_employee].any?).to be_true
      end
    end

    context "with all required data" do
      let(:params) {valid_params}

      it "should successfully save" do
        expect(EmployerCensus::EmployeeFamily.new(**params).save).to be_true
      end
    end
  end
end

  # let(:linked_at) {Date.today}
  # let(:census_dependent) {FactoryGirl.create(:employer_census_dependent)}

describe EmployerCensus::EmployeeFamily, 'class methods' do

  describe 'links and unlinks employees' do
    let(:employer) {FactoryGirl.create(:employer)}
    let(:employee) {FactoryGirl.build(:employee)}
    let(:census_family) {FactoryGirl.build(:employer_census_family)}

    it 'link_employee' do
      census_family.link_employee(employee)
      expect(census_family.linked_employee_id).to eq employee.id
    end

    it 'returns #linked_employee' do
      employee.employer = employer
      employee.save!
      census_family.link_employee(employee)
      expect(census_family.linked_employee).to be_an_instance_of Employee
      expect(census_family.linked_employee).to eq employee
    end

    it 'delinks employee' do
    end
  end

  describe '#benefit_group' do
    let(:benefit_group) {FactoryGirl.create(:benefit_group)}

    it 'sets benefit_group' do
    end

    it 'gets benefit_group' do
    end
  end

  describe '#plan_year' do
    let(:plan_year) {FactoryGirl.create(:plan_year)}

    it 'sets plan_year' do
    end

    it 'gets plan_year' do
    end
  end

  describe '#replicate' do
      it 'copies this family to new instance' do
        # user - FactoryGirl.create(:user)
        er = FactoryGirl.create(:employer)
        ee = FactoryGirl.build(:employer_census_employee)
        ee.address = FactoryGirl.build(:address)

        family = er.employee_families.build(census_employee: ee)
        # family.link(user)
        family.census_employee.hired_on = Date.today - 1.year
        family.census_employee.terminated_on = Date.today - 10.days
        ditto = family.replicate

        expect(ditto).to be_an_instance_of EmployerCensus::EmployeeFamily
        expect(ditto.linked_employee_id).to be_nil
        expect(ditto.is_linked?).to eq false

        expect(ditto.census_employee).to eq ee
        expect(ditto.census_employee.hired_on).to be_nil
        expect(ditto.census_employee.terminated_on).to be_nil
        expect(ditto.census_employee.address).to eq ee.address
      end
    end
end
