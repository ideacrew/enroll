require 'rails_helper'

describe PlanYear, :type => :model do
  it { should validate_presence_of :start_on }
  it { should validate_presence_of :end_on }
  it { should validate_presence_of :open_enrollment_start_on }
  it { should validate_presence_of :open_enrollment_end_on }
end

describe PlanYear do
  describe "" do

  end
end
