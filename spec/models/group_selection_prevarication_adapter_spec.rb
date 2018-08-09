require 'rails_helper'

RSpec.describe GroupSelectionPrevaricationAdapter, dbclean: :after_each do

  let(:employee_role) { double(id: nil) }
  let(:employee) { double(id: nil) }
  let(:params) {{
      "coverage_kind" => "dental",
      "person_id" => employee.id,
      "employee_role_id" => employee_role.id,
      "market_kind" => "shop"
    }
  }

  subject { GroupSelectionPrevaricationAdapter.new(params) }

  describe ".is_eligible_for_dental?" do

    context "when employee making changes to existing enrollment" do 

      it "should check dental offered or not using existing enrollment benefit package" do 
      end
    end

    context "when employee has special enrollment period" do 

      it "should check dental offered or not using SEP effective to date" do 
      end
    end

    context "when employee has new hire enrollment period" do 

      it "should check dental offered or not using new hire effective date" do 
      end
    end

    context "when employee has open enrollment available" do 

      it "should return dental offered or not" do 
      end
    end
  end

  describe ".is_dental_offered?" do
    context "when employer is offering dental coverage" do

      it "should return true" do

      end
    end 
  end
end