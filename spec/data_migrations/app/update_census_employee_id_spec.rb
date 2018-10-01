require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "update_census_employee_id")

describe UpdateCensusEmployeeId, dbclean: :after_each do

  let(:given_task_name) { "update_census_employee_id" }
  subject { UpdateCensusEmployeeId.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "update census employee id" do

    let!(:employee_role) { FactoryGirl.create(:employee_role, census_employee_id: census_employee.id )}
    let(:census_employee) { FactoryGirl.create(:census_employee)}
    let(:census_employee2) { FactoryGirl.create(:census_employee)}


    before(:each) do
      allow(ENV).to receive(:[]).with("employee_role_id").and_return(employee_role.id.to_s)
      allow(ENV).to receive(:[]).with("input_id").and_return(census_employee.id.to_s)
      # employee_role.update_attributes!(census_employee_id: census_employee2.id)
      employee_role.unset(:census_employee_id)
    end

    it "should update bookmark url associated with employee role" do
      # expect(employee_role.census_employee_id.to_s).to eq census_employee2.id.to_s
      puts employee_role.census_employee_id
      subject.migrate
      employee_role.reload
      puts employee_role.census_employee_id
      expect(employee_role.census_employee_id.to_s).to eq census_employee.id.to_s
    end
  end
end

# require "rails_helper"
# require File.join(Rails.root, "app", "data_migrations", "update_census_employee_id")

# describe UpdateCensusEmployeeId do
#   let(:given_task_name) { "update_census_employee_id" }
#   subject { UpdateCensusEmployeeId.new(given_task_name, double(:current_scope => nil)) }

#   describe "given a task name" do
#     it "has the given task name" do
#       expect(subject.name).to eql given_task_name
#     end
#   end

#   describe "changing census_employee_id within employee_role" do
#     let!(:employee_role) { FactoryGirl.create(:employee_role, census_employee: census_employee) }
#     let!(:census_employee) { FactoryGirl.create(:census_employee) }

#     before(:each) do
#       allow(ENV).to receive(:[]).with("employee_role_id").and_return(employee_role.id.to_s)
#       allow(ENV).to receive(:[]).with("census_employee_id").and_return("1234567")
#     end

#     it "should change census_employee_id" do
#       subject.migrate
#       employee_role.reload
#       expect(employee_role.census_employee_id.to_s).to eq "1234567"
#     end

#     # it "should not change census_employee_id if any census_employee_id is nil" do
#     #   allow(ENV).to receive(:[]).with("census_employee_id").and_return(nil)
#     #   subject.migrate
#     #   employee_role.reload
#     #   expect(employee_role.census_employee_id.to_s).to be_nil
#     # end
#   end
# end






