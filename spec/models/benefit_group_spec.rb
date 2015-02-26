require 'rails_helper'

describe BenefitGroup, type: :model do

  it { should validate_presence_of :benefit_list }
  it { should validate_presence_of :effective_on_kind }
  it { should validate_presence_of :terminate_on_kind }
  it { should validate_presence_of :effective_on_offset }
  it { should validate_presence_of :reference_plan_id }
  it { should validate_presence_of :premium_pct_as_int }
  it { should validate_presence_of :employer_max_amt_in_cents }


end

describe BenefitGroup, "instance methods" do

  it "should return all employee families associated with this benefit_group" do
    pending "required spec missing in: #{__FILE__}"
  end

  it "should return the reference plan associated with this benefit group" do
    pending "required spec missing in: #{__FILE__}"
  end

  it "verifies the reference plan is included in the set of elected_plans" do
    pending "required spec missing in: #{__FILE__}"
  end

  it "verifies premium_pct_as_integer is > 50%" do
    pending "required spec missing in: #{__FILE__}"
  end

  it "verifies that premium_pct_as_integer is > 50%" do
    pending "required spec missing in: #{__FILE__}"
  end


end