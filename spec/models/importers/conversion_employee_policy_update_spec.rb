require 'rails_helper'

describe Imports::ConversionEmployeePolicy do
  describe "given an existing employee and valid employer" do
    context "and the employee's plan HIOS ID is changed" do
      context "and the employee's enrollment is not auto-renewed" do
        it "should change the employee enrollment plan HIOS ID"
      end

      context "and the employee's enrollment is auto-renewed" do
        context "and the employee has not changed renewal enrollment" do
          it "should change the employee enrollment plan HIOS ID"
          it "should change the employee auto-renewed enrollment to mapped plan HIOS ID"
        end

        context "and the employee has changed renewal enrollment" do
          it "adds an 'update inconsistancy: employee enrollment record changed' error"
          it "adds the error to the instance's error[:base] array"
        end
      end
    end
  end
end
