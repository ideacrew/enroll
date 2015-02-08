require 'rails_helper'

describe EmployerCensus::Family, '.new', type: :model do
  it { should validate_presence_of :employee }

  it 'properly intantiates the class' do
    er = FactoryGirl.create(:employer)
    ee = FactoryGirl.build(:employer_census_employee)
    ee.address = FactoryGirl.build(:address)

    family = er.employer_census_families.build(employee: ee)

    expect(family.valid?).to eq true
    expect(family.errors.messages.size).to eq 0
    expect(family.save).to eq true

  end
end

describe EmployerCensus::Family, '#clone', type: :model do
  it 'creates a copy of this instance' do
    er = FactoryGirl.create(:employer)
    ee = FactoryGirl.build(:employer_census_employee)
    ee.address = FactoryGirl.build(:address)

    family = er.employer_census_families.build(employee: ee)
    family.matched_at = Time.now
    family.employee.date_of_hire = Date.today - 1.year
    family.employee.date_of_termination = Date.today - 10.days
    ditto = family.clone

    expect(ditto.employee).to eq ee
    expect(ditto.employee.date_of_hire).to be_nil
    expect(ditto.employee.date_of_termination).to be_nil
    expect(ditto.employee.address).to eq ee.address
    expect(ditto.is_active?).to be_true
    expect(ditto.matched_at).to be_nil

  end
end
