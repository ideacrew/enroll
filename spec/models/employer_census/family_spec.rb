require 'rails_helper'

RSpec.describe EmployerCensus::Family, '.new', :type => :model do
  it { should validate_presence_of :employee }

  it 'properly intantiates the class' do
    family = EmployerCensus::Family.new
    employee = family.build_employee(
        first_name: "James",
        last_name: "Kirk",
        dob: Date.today - 26.years,
        gender: "male",
        ssn: "555-12-3452",
        date_of_hire: Date.today - 14.days,
        address: { kind: "home", address_1: "10 Main St", city: "Washington", state: "DC", zip: "20001"}
      )

    child = family.dependents.build(
      {
        first_name: "James",
        last_name: "Kirk",
        dob: Date.today - 26.years,
        gender: "male",
        employee_relationship: "dependent"
      }
    )

    expect(family.valid?).to eq true
    expect(family.errors.messages.size).to eq 0
  end

end
