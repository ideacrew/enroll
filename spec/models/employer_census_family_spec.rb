require 'rails_helper'

RSpec.describe EmployerCensusFamily, '.new', :type => :model do
  it { should validate_presence_of :employer_census_employee }

  it 'properly intantiates the class' do
    family = EmployerCensusFamily.new
    employee = family.build_employer_census_employee(
        
      )
    child = family.employer_census_dependents.build(
      )

    expect(family.errors.messages.size).to eq 0
    expect(family.save).to eq true
  end

end
