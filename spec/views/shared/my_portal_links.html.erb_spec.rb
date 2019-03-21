require 'rails_helper'

describe "shared/_my_portal_links.html.haml" do
  before :each do
    DatabaseCleaner.clean
  end

  context "with employee role" do
    let(:user) { FactoryGirl.create(:user, person: person, roles: ["employee"]) }
    let(:person) { FactoryGirl.create(:person, :with_employee_role)}

    it "should have one portal link" do
      all_er_profile = FactoryGirl.create(:employer_profile)
      all_census_ee = FactoryGirl.create(:census_employee, employer_profile: all_er_profile)
      person.employee_roles.first.census_employee = all_census_ee
      person.employee_roles.first.save!
      sign_in(user)
      render 'shared/my_portal_links'
      expect(rendered).to have_content('My Insured Portal')
      expect(rendered).to_not have_selector('dropdownMenu1')
    end

  end

  context "with employer role & employee role" do
    let(:user) { FactoryGirl.create(:user, person: person, roles: ["employee", "employer_staff"]) }
    let(:person) { FactoryGirl.create(:person, :with_employee_role, :with_employer_staff_role)}

    it "should have one portal links and popover" do
      all_er_profile = FactoryGirl.create(:employer_profile)
      all_census_ee = FactoryGirl.create(:census_employee, employer_profile: all_er_profile)
      person.employee_roles.first.census_employee = all_census_ee
      person.employee_roles.first.save!
      sign_in(user)
      render 'shared/my_portal_links'
      expect(rendered).to have_content('My Insured Portal')
      expect(rendered).to have_content(all_er_profile.legal_name)
      expect(rendered).to have_selector('.dropdown-menu')
      expect(rendered).to have_selector('.dropdown-menu')
      expect(rendered).to match(/Insured/)
    end
  end

  context "with employer roles & employee role" do
    let(:user) { FactoryGirl.create(:user, person: person, roles: ["employee", "employer_staff"]) }
    let(:person) { FactoryGirl.create(:person, :with_employee_role, :with_employer_staff_role)}

    it "should have one portal links and popover" do
      all_er_profile = FactoryGirl.create(:employer_profile)
      all_er_profile.organization.update_attributes(legal_name: 'Second Company') # not always Turner
      all_census_ee = FactoryGirl.create(:census_employee, employer_profile: all_er_profile)
      EmployerStaffRole.create(person:person, employer_profile_id: all_er_profile.id)
      person.employee_roles.first.census_employee = all_census_ee
      person.employee_roles.first.save!
      sign_in(user)
      render 'shared/my_portal_links'
      expect(rendered).to have_content('My Insured Portal')
      expect(rendered).to have_content(all_er_profile.legal_name)
      expect(rendered).to have_content('Second Company')
      expect(rendered).to have_selector('.dropdown-menu')
      expect(rendered).to have_selector('.dropdown-menu')
      expect(rendered).to match(/Insured/)
    end
  end

  context 'with broker staff role' do
    let(:user) { FactoryGirl.create(:user, person: person, roles: ['broker_agency_staff']) }
    let!(:person) { FactoryGirl.create(:person, :with_broker_role)}
    let!(:broker_agency_staff_role) { FactoryGirl.create(:broker_agency_staff_role, aasm_state: 'active', person: person)}


    before :each do
      sign_in(user)
      allow(user).to receive(:person).and_return(person)
      render 'shared/my_portal_links'
    end

    it 'should have broker portal link' do
      expect(rendered).to have_content('My Broker Agency Portal')
    end

  end

  context 'with broker staff role and Consumer role' do
    let(:user) { FactoryGirl.create(:user, person: person, identity_verified_date: TimeKeeper.date_of_record, roles: ['broker_agency_staff', 'consumer']) }
    let!(:person) { FactoryGirl.create(:person, :with_broker_role, :with_consumer_role)}
    let!(:broker_agency_staff_role) { FactoryGirl.create(:broker_agency_staff_role, aasm_state: 'active', person: person)}

    before :each do
      sign_in(user)
      allow(user).to receive(:person).and_return(person)
      render 'shared/my_portal_links'
    end

    it 'should have portal links and dropdown' do
      expect(rendered).to have_selector('.dropdown-menu')
      expect(rendered).to have_content('My Insured Portal')
      expect(rendered).to have_content("#{broker_agency_staff_role.broker_agency_profile.legal_name}")
    end

  end

  context 'with multiple broker staff roles' do
    let(:user) { FactoryGirl.create(:user, person: person, identity_verified_date: TimeKeeper.date_of_record, roles: ['broker_agency_staff']) }
    let!(:person) { FactoryGirl.create(:person, :with_broker_role)}
    let!(:broker_agency_staff_role) { FactoryGirl.create(:broker_agency_staff_role, aasm_state: 'active', person: person)}
    let!(:broker_agency_staff_role2) { FactoryGirl.create(:broker_agency_staff_role, aasm_state: 'active', person: person)}

    before :each do
      sign_in(user)
      allow(user).to receive(:person).and_return(person)
      render 'shared/my_portal_links'
    end

    it 'should have portal links and dropdown' do
      expect(rendered).to have_selector('.dropdown-menu')
      expect(rendered).to have_content(broker_agency_staff_role.broker_agency_profile.legal_name.to_s)
      expect(rendered).to have_content(broker_agency_staff_role2.broker_agency_profile.legal_name.to_s)
    end
  end

  context 'with multiple broker staff roles and Consumer role' do
    let(:user) { FactoryGirl.create(:user, person: person, identity_verified_date: TimeKeeper.date_of_record, roles: ['broker_agency_staff', 'consumer']) }
    let!(:person) { FactoryGirl.create(:person, :with_broker_role, :with_consumer_role)}
    let!(:broker_agency_staff_role) { FactoryGirl.create(:broker_agency_staff_role, aasm_state: 'active', person: person)}
    let!(:broker_agency_staff_role2) { FactoryGirl.create(:broker_agency_staff_role, aasm_state: 'active', person: person)}

    before :each do
      sign_in(user)
      allow(user).to receive(:person).and_return(person)
      render 'shared/my_portal_links'
    end

    it 'should have portal links and dropdown' do
      expect(rendered).to have_selector('.dropdown-menu')
      expect(rendered).to have_content('My Insured Portal')
      expect(rendered).to have_content(broker_agency_staff_role.broker_agency_profile.legal_name.to_s)
      expect(rendered).to have_content(broker_agency_staff_role2.broker_agency_profile.legal_name.to_s)
    end

  end

  context 'with employer roles, employee role and broker staff role' do
    let(:user) { FactoryGirl.create(:user, person: person, roles: ['employee', 'employer_staff', 'broker_agency_staff']) }
    let(:person) { FactoryGirl.create(:person, :with_employee_role, :with_employer_staff_role)}
    let!(:broker_agency_staff_role) { FactoryGirl.create(:broker_agency_staff_role, aasm_state: 'active', person: person)}

    it "should have one portal links and popover" do
      all_er_profile = FactoryGirl.create(:employer_profile)
      all_er_profile.organization.update_attributes(legal_name: 'Second Company') # not always Turner
      all_census_ee = FactoryGirl.create(:census_employee, employer_profile: all_er_profile)
      EmployerStaffRole.create(person: person, employer_profile_id: all_er_profile.id)
      person.employee_roles.first.census_employee = all_census_ee
      person.employee_roles.first.save!
      sign_in(user)
      render 'shared/my_portal_links'
      expect(rendered).to have_content('My Insured Portal')
      expect(rendered).to have_content(all_er_profile.legal_name)
      expect(rendered).to have_content('Second Company')
      expect(rendered).to have_selector('.dropdown-menu')
      expect(rendered).to have_selector('.dropdown-menu')
      expect(rendered).to match(/Insured/)
      expect(rendered).to have_content(broker_agency_staff_role.broker_agency_profile.legal_name.to_s)
    end
  end

end
