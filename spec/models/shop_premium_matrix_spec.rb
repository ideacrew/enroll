require 'rails_helper'
RSpec.describe ShopPremiumMatrix, :type => :model do
  let(:premium_matrix) do
    { hbx_enrollment_member_id: 1,
      relationship: 'employee',
      age_on_effective_date: 50,
      employer_max_contribution: 370.43,
      select_plan_id: 'plan_b',
      plan_premium_total: 550.00,
      employee_responsible_amount: 179.57
    }
  end

  let(:premium_matrix2) do
    { hbx_enrollment_member_id: 1,
      relationship: 'spouse',
      age_on_effective_date: 22,
      employer_max_contribution: 215.73,
      select_plan_id: 'plan_b',
      plan_premium_total: 197.13,
      employee_responsible_amount: 0.00
    }
  end

  let(:premium_matrix3) do
    { hbx_enrollment_member_id: 1,
      relationship: 'child_under_26',
      age_on_effective_date: 12,
      employer_max_contribution: 0.00,
      select_plan_id: 'plan_a',
      plan_premium_total: 125.30,
      employee_responsible_amount: 125.30
    }
  end

  let(:sum_plan) do 
    {
      'plan_b' => {
        'sum_plan_premium_total' => 747.13, 
        'sum_employer_max_contribution' => 586.16,
        'sum_employee_responsible_amount' => 179.57
      },

      "plan_a" => {
        "sum_plan_premium_total" => 125.3, 
        "sum_employer_max_contribution" => 0.0, 
        "sum_employee_responsible_amount" => 125.3
      }
    }
  end

  let(:detail_plan) do
    {"plan_b" => [
      {"hbx_enrollment_member_id"=>1, 
       "relationship"=>"employee",
       "age_on_effective_date"=>50,
       "employer_max_contribution"=>370.43,
       "select_plan_id"=>"plan_b",
       "plan_premium_total"=>550.0,
       "employee_responsible_amount"=>179.57}, 
      
       {"hbx_enrollment_member_id"=>1,
       "relationship"=>"spouse", 
       "age_on_effective_date"=>22, 
       "employer_max_contribution"=>215.73, 
       "select_plan_id"=>"plan_b", 
       "plan_premium_total"=>197.13,
       "employee_responsible_amount"=>0.0}]
    }
  end

  before do 
    [premium_matrix, premium_matrix2, premium_matrix3].each{|pm| ShopPremiumMatrix.new(pm)}
    ShopPremiumMatrix.cache_sum_family(1, 'plan_b')
    ShopPremiumMatrix.cache_sum_family(1, 'plan_a')
    ShopPremiumMatrix.cache_family_detail(1, 'plan_b')
  end

  after do
    ShopPremiumMatrix.destroy_all
  end

  it 'able to cache and fetch family total cost' do
    expect(ShopPremiumMatrix.fetch_cost(1, ['plan_b', 'plan_a'], 'family-total')).to eq sum_plan
  end

  it 'able to cache and fetch family total cost' do
    expect(ShopPremiumMatrix.fetch_cost(1, ['plan_b'], 'family-detail')).to eq detail_plan
  end
end
