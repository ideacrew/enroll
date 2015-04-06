require 'rails_helper'

describe ShopPremiumMatrix, type: :model do
  context "when no data has been loaded" do
    include_context "BradyWork"

    def create_hbx_enrollment
      HbxEnrollment.new_from(employer_profile: carols_employer,
                             coverage_household: carols_coverage_household,
                             benefit_group: carols_benefit_group)
    end

    let(:plans) {carols_benefit_group.elected_plans}
    let!(:improper_hbx_enrollment) do
      HbxEnrollment.skip_callback(:save, :after, :initialize_shop_premium_matrix)
      enrollment = create_hbx_enrollment
      HbxEnrollment.set_callback(:save, :after, :initialize_shop_premium_matrix)
      enrollment
    end

    before do
      ShopPremiumMatrix.destroy_all
    end

    it "should not have a value for a plan and member" do
      member_id = improper_hbx_enrollment.hbx_enrollment_members.first.id.to_s
      plan_id = carols_benefit_group.reference_plan_id.to_s
      expect(ShopPremiumMatrix.fetch_cost(member_id, [plan_id], "family-total")).to be_blank
    end

    context "and a combination of plans and members is added" do
      # this is expected to load the premium matrix with data to support this hbx_enrollment
      let!(:hbx_enrollment) {create_hbx_enrollment}

      it "should have a value for a plan and member" do
        member_id = hbx_enrollment.hbx_enrollment_members.first.id.to_s
        plan_id = carols_benefit_group.reference_plan_id.to_s
        expect(ShopPremiumMatrix.fetch_cost(member_id, [plan_id], "family-total")).to be_present
      end

      context "and the same combination of plans and members is added" do
        # this is expected to try to load the premium matrix with data again
        let!(:another_hbx_enrollment) {create_hbx_enrollment}

        it "shouldn't put the data in again" do
          pending
        end
      end
    end
  end
end

describe ShopPremiumMatrix, :type => :model do
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
