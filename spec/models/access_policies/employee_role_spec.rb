require "rails_helper"

describe AccessPolicies::EmployeeRole, :dbclean => :after_each do
  subject { AccessPolicies::EmployeeRole.new(user) }
  let(:user) { FactoryGirl.create(:user, person: person)}
  let(:person) {FactoryGirl.create(:person, :with_employee_role) }
  let(:controller) { Insured::EmployeeRolesController.new }
  let(:another_employer) { FactoryGirl.create(:employer_profile) }

  context "user's person with id" do
    it "should be ok with the action" do
      expect(subject.authorize_employee_role(person.employee_roles.first, controller)).to be_truthy
    end
  end

  context "a user with a different id than the users person" do
    let(:foreign_employee) { EmployeeRole.new(employer_profile_id: BSON::ObjectId::new) }

    it "should redirect you to your bookmark employee role page or families home" do
      expect(controller).to receive(:redirect_to_check_employee_role)
      subject.authorize_employee_role(foreign_employee, controller)
    end
  end

  context "with admin user" do
    subject { AccessPolicies::EmployeeRole.new(admin_user) }
    let(:admin_user) { FactoryGirl.create(:user, person: admin_person) }
    let(:admin_person) {FactoryGirl.create(:person, :with_hbx_staff_role) }
    it "should be ok with the action" do
      expect(subject.authorize_employee_role(person.employee_roles.first, controller)).to be_truthy
    end
  end

  context "with has_csr_subrole user" do
    subject { AccessPolicies::EmployeeRole.new(csr_user) }
    let(:csr_user) { FactoryGirl.create(:user, person: csr_role_person) }
    let(:csr_role_person) {FactoryGirl.create(:person, :with_csr_role) }
    it "should be ok with the action" do
      expect(subject.authorize_employee_role(person.employee_roles.first, controller)).to be_truthy
    end
  end

  context "with broker role user" do
    subject { AccessPolicies::EmployeeRole.new(broker_user) }
    let(:broker_user) { FactoryGirl.create(:user, person: broker_person, roles: ["broker"]) }
    let(:broker_person) { FactoryGirl.create(:person) }
    let(:broker_role) { FactoryGirl.create(:broker_role, person: broker_person)}
    let(:broker_agency_profile) { FactoryGirl.create(:broker_agency_profile, primary_broker_role: broker_role) }

    before do
      broker_role.save
      broker_agency_account = BrokerAgencyAccount.create(employer_profile: person.employee_roles.first.employer_profile, start_on: TimeKeeper.date_of_record, broker_agency_profile_id: broker_agency_profile.id, writing_agent_id: broker_role.id )
    end

    context "who doesn't match employer_profile_id" do
      it "should redirect you to your bookmark employee role page or families home" do
        allow(::EmployerProfile).to receive(:find_by_writing_agent).and_return([another_employer])
        expect(controller).to receive(:redirect_to_check_employee_role)
        subject.authorize_employee_role(person.employee_roles.first, controller)
      end
    end

    context "who matches employer_profile_id by broker role" do
      it "should be ok with the action" do
        expect(subject.authorize_employee_role(person.employee_roles.first, controller)).to be_truthy
      end
    end
  end

  context "with broker agency staff role user" do
    subject { AccessPolicies::EmployeeRole.new(broker_user) }
    let(:broker_user) { FactoryGirl.create(:user, person: broker_person, roles: ["broker"]) }
    let(:broker_person) { FactoryGirl.create(:person) }
    let(:broker_agency_staff_role) { FactoryGirl.create(:broker_agency_staff_role, person: broker_person, broker_agency_profile_id: broker_agency_profile.id)}
    let(:broker_agency_profile) { FactoryGirl.create(:broker_agency_profile) }

    before do
      broker_agency_staff_role.save
      broker_agency_account = BrokerAgencyAccount.create(employer_profile: person.employee_roles.first.employer_profile, start_on: TimeKeeper.date_of_record, broker_agency_profile_id: broker_agency_profile.id)
    end

    context "who doesn't match employer_profile_id" do
      it "should redirect you to your bookmark employee role page or families home" do
        allow(::EmployerProfile).to receive(:find_by_broker_agency_profile).and_return([another_employer])
        expect(controller).to receive(:redirect_to_check_employee_role)
        subject.authorize_employee_role(person.employee_roles.first, controller)
      end
    end

    context "who matches employer_profile_id by broker role" do
      it "should be ok with the action" do
        expect(subject.authorize_employee_role(person.employee_roles.first, controller)).to be_truthy
      end
    end
  end
end
