require 'rails_helper'

RSpec.describe EmployerCensusMember, type: :model do
  it { should validate_presence_of :first_name }
  it { should validate_presence_of :last_name }
  it { should validate_presence_of :dob }
  it { should validate_presence_of :gender }
  it { should validate_presence_of :employee_relationship }

  it 'properly intantiates the class' do
  end

  it 'fails unless provided with a first and last name' do
  end

  it 'fails unless provided with a proper dob' do
  end

  it 'fails unless provided with a proper gender' do
  end

end
