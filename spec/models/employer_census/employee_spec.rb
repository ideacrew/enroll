require 'rails_helper'

RSpec.describe EmployerCensus::Employee, '.new', type: :model do
  it { should validate_presence_of :ssn }
  it { should validate_presence_of :hired_on }
  it { should validate_presence_of :address }

  it 'properly intantiates the class' do
    first_name = "Lynyrd"
    middle_name = "Rattlesnake"
    last_name = "Skynyrd"
    name_sfx = "PhD"
    ssn = "230987654"
    dob = Date.today
    gender = "male"

    employee = EmployerCensus::Employee.new(
        first_name: first_name,
        middle_name: middle_name,
        last_name: last_name,
        name_sfx: name_sfx,
        ssn: ssn,
        dob: dob,
        gender: gender,
        hired_on: Date.today - 14.days,
        address: { kind: "home", address_1: "10 Main St", city: "Washington", state: "DC", zip: "20001"}
      )

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
    expect(employee.errors.messages.size).to eq 0
  end

end
