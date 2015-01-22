require 'rails_helper'

RSpec.describe EmployerCensus::Member, type: :model do
  it { should validate_presence_of :first_name }
  it { should validate_presence_of :last_name }
  it { should validate_presence_of :dob }
  it { should validate_presence_of :gender }

end
