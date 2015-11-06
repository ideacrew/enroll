require "rails_helper"

describe AccessPolicies::EmployeeRole, :dbclean => :after_each do
  subject { AccessPolicies::EmployeeRole.new(user) }
  let(:user) { FactoryGirl.create(:user, person: person)}
  let(:person) {FactoryGirl.create(:person, :with_employee_role) }
  let(:controller) { Insured::EmployeeRolesController.new}

  context "user's person with id" do
    it "should be ok with the action" do
      expect(subject.authorize_employee_role(person.employee_roles.first, controller)).to be_truthy
    end
  end

  context "a user with a different id than the users person" do
    let(:foreign_employee) { EmployeeRole.new}
    it "should redirect you to your bookmark employee role page or families home" do
      expect(controller).to receive(:redirect_to_check_employee_role)
      subject.authorize_employee_role(foreign_employee, controller)
    end
  end
end
