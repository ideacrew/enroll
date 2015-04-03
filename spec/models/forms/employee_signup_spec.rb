# require 'rails_helper'

# describe Forms::EmployeeSignup, "given an invalid address " do

#   subject { Forms::EmployeeSignup.new(:addresses => [Forms::Address.new]) }

#   it "should not be valid" do
#     expect(subject.valid?).to be_falsey
#   end
# end

# describe Forms::EmployeeSignup, "for an employee who doesn't have a corresponding person yet" do

#   describe "given an ssn that collides with any person record" do
#     it "should have an invalid ssn"
#   end

# end

# describe Forms::EmployeeSignup, "for an employee who already has a corresponding person" do

#   describe "given the same SSN as the pre-existing person record" do
#     it "should not have an invalid ssn"
#   end

#   describe "given a different SSN from both the pre-existing employee and the pre-existing person record" do
#     it "should not have an invalid ssn"
#   end

#   describe "given an updated SSN that collides with a DIFFERENT person record" do
#     it "should have an invalid ssn"
#   end

# end
