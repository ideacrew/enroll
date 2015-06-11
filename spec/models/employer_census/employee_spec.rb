require 'rails_helper'

describe EmployerCensus::Employee, '.new', dbclean: :after_each do
  it { should validate_presence_of :ssn }
  it { should validate_presence_of :dob }
  it { should validate_presence_of :hired_on }

  let(:census_family) { FactoryGirl.build(:employer_census_family) }
  let(:census_employee) { census_family.census_employee }

  let(:first_name){ "Lynyrd" }
  let(:middle_name){ "Rattlesnake" }
  let(:last_name){ "Skynyrd" }
  let(:name_sfx){ "PhD" }
  let(:ssn){ "230987654" }
  let(:dob){ Date.today }
  let(:gender){ "male" }
  let(:address) { Address.new(kind: "home", address_1: "address 1", city: "new city", state: "new state", zip: "11111") }

  let(:employee_params){
    {
      first_name: first_name,
      middle_name: middle_name,
      last_name: last_name,
      name_sfx: name_sfx,
      ssn: ssn,
      dob: dob,
      gender: gender,
      hired_on: Date.today - 14.days,
      address: address
    }
  }
  it 'properly intantiates the class' do
    employee = EmployerCensus::Employee.new(**employee_params)

    expect(employee.first_name).to eq first_name
    expect(employee.middle_name).to eq middle_name
    expect(employee.last_name).to eq last_name
    expect(employee.name_sfx).to eq name_sfx
    expect(employee.ssn).to eq ssn
    expect(employee.dob).to eq dob
    expect(employee.gender).to eq gender

    # Class should set this attribute
    expect(employee.employee_relationship).to eq "self"

    # expect(employee.inspect).to eq 0
    expect(employee.valid?).to eq true
    expect(employee.is_linkable?).to be_falsey
    expect(employee.errors.messages.size).to eq 0
  end

  it "checks if employee is_linkable? " do
    census_employee.save
    expect(census_employee.is_linkable?).to be_truthy
  end

end
