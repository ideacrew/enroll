require 'rails_helper'

describe ElectedPlan, type: :model do
  it { should validate_presence_of :plan_id }
end
