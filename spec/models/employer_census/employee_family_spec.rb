require 'rails_helper'

describe EmployerCensus::EmployeeFamily, '.new', type: :model do
  it { should validate_presence_of :employee }

  it 'properly intantiates the class' do
    er = FactoryGirl.create(:employer)
    ee = FactoryGirl.build(:employer_census_employee)
    # deps = FactoryGirl.build_list(:employer_census_dependent, 2)
    ee.address = FactoryGirl.build(:address)

    family = er.employee_families.build(employee: ee)

    expect(family.valid?).to eq true
    expect(family.errors.messages.size).to eq 0
    expect(family.save).to eq true

  end
end

describe EmployerCensus::EmployeeFamily, '#clone', type: :model do
  it 'creates a copy of this instance' do
    # user - FactoryGirl.create(:user)
    er = FactoryGirl.create(:employer)
    ee = FactoryGirl.build(:employer_census_employee)
    ee.address = FactoryGirl.build(:address)

    family = er.employee_families.build(employee: ee)
    # family.link(user)
    family.employee.hired_on = Date.today - 1.year
    family.employee.terminated_on = Date.today - 10.days
    ditto = family.clone

    expect(ditto.employee).to eq ee
    expect(ditto.employee.hired_on).to be_nil
    expect(ditto.employee.terminated_on).to be_nil
    expect(ditto.employee.address).to eq ee.address
    expect(ditto.is_linked?).to eq false

  end
end
