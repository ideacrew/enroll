require 'rails_helper'

RSpec.describe CensusDependent, :type => :model do
  it { should validate_presence_of :employee_relationship }

  it 'properly intantiates the class' do
    first_name = "Lynyrd"
    middle_name = "R"
    last_name = "Skynyrd"
    name_sfx = "PhD"
    ssn = "230987654"
    dob = Date.today
    gender = "male"
    employee_relationship = "spouse"

    dependent = CensusDependent.new(
        first_name: first_name,
        middle_name: middle_name,
        last_name: last_name,
        name_sfx: name_sfx,
        ssn: ssn,
        dob: dob,
        gender: gender,
        employee_relationship: employee_relationship
      )

    expect(dependent.first_name).to eq first_name
    expect(dependent.middle_name).to eq middle_name
    expect(dependent.last_name).to eq last_name
    expect(dependent.name_sfx).to eq name_sfx
    expect(dependent.ssn).to eq ssn
    expect(dependent.dob).to eq dob
    expect(dependent.gender).to eq gender
    expect(dependent.employee_relationship).to eq employee_relationship

    expect(dependent.errors.messages.size).to eq 0
  end

  it 'fails unless provided with a proper gender'

  it 'fails unless provided with a proper employee_relationship'
end
