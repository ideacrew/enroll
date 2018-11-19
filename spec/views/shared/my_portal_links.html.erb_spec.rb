require 'rails_helper'

describe "shared/_my_portal_links.html.haml" do
  before :each do
    DatabaseCleaner.clean
  end

  context "with employee role" do
    let(:user) { FactoryGirl.create(:user, person: person, roles: ["employee"]) }
    let(:person) { FactoryGirl.create(:person, :with_employee_role)}

    it "should have portal link and dropdown" do
      all_er_profile = FactoryGirl.create(:employer_profile)
      all_census_ee = FactoryGirl.create(:census_employee, employer_profile: all_er_profile)
      person.employee_roles.first.census_employee = all_census_ee
      person.employee_roles.first.save!
      sign_in(user)
      render 'shared/my_portal_links'
      expect(rendered).to have_selector('.dropdown-menu')
      expect(rendered).to have_content('My Insured Portal')
      expect(rendered).to have_content('Add Consumer Role')
    end

  end

  context "with employer role & employee role" do
    let(:user) { FactoryGirl.create(:user, person: person, roles: ["employee", "employer_staff"]) }
    let(:person) { FactoryGirl.create(:person, :with_employee_role, :with_employer_staff_role)}

    it "should have portal link and dropdown" do
      all_er_profile = FactoryGirl.create(:employer_profile)
      all_census_ee = FactoryGirl.create(:census_employee, employer_profile: all_er_profile)
      person.employee_roles.first.census_employee = all_census_ee
      person.employee_roles.first.save!
      sign_in(user)
      render 'shared/my_portal_links'
      expect(rendered).to have_content('My Insured Portal')
      expect(rendered).to have_content(all_er_profile.legal_name)
      expect(rendered).to have_content('Add Consumer Role')
      expect(rendered).to have_selector('.dropdown-menu')
      expect(rendered).to match(/Insured/)
    end

  end

  context "with employer roles & employee role" do
    let(:user) { FactoryGirl.create(:user, person: person, roles: ["employee", "employer_staff"]) }
    let(:person) { FactoryGirl.create(:person, :with_employee_role, :with_employer_staff_role)}

    it "should have one portal link and dropdown" do
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
      expect(rendered).to have_content('Add Consumer Role')
      expect(rendered).to match(/Insured/)
    end

    it "should have Add Employee Role link" do
      sign_in(user)
      allow(user).to receive(:person).and_return(person)
      render 'shared/my_portal_links'
      expect(rendered).to have_content('Add Employee Role')
    end
  end

  context "with employer_staff role" do
    # let(:user) { FactoryGirl.create(:user) }
    let(:user) { FactoryGirl.create(:user, person: person, roles: ["employer_staff"]) }
    let(:person) { FactoryGirl.create(:person, :with_employer_staff_role)}

    before :each do
      sign_in(user)
      allow(user).to receive(:person).and_return(person)
      render 'shared/my_portal_links'
    end

    it "should have Add Employee Role link" do
      expect(rendered).to have_selector('.dropdown-menu')
      expect(rendered).to have_content('Add Consumer Role')
      expect(rendered).to have_content('Add Employee Role')
    end

  end

  context "with broker role" do
    # let(:user) { FactoryGirl.create(:user) }
    let(:user) { FactoryGirl.create(:user, person: person, roles: ["broker_agency_staff"]) }
    let!(:person) { FactoryGirl.create(:person, :with_broker_role)}

    before :each do
      sign_in(user)
      allow(user).to receive(:person).and_return(person)
      render 'shared/my_portal_links'
    end

    it "should have portal links and dropdown" do
      expect(rendered).to have_selector('.dropdown-menu')
      expect(rendered).to have_content('Add Consumer Role')
      expect(rendered).to have_content('My Broker Agency Portal')
    end

  end

  context "with broker role and Consumer role" do
    # let(:user) { FactoryGirl.create(:user) }
    let(:user) { FactoryGirl.create(:user, person: person, identity_verified_date: TimeKeeper.date_of_record, roles: ["broker_agency_staff", "consumer"]) }
    let!(:person) { FactoryGirl.create(:person, :with_broker_role, :with_consumer_role)}

    before :each do
      sign_in(user)
      allow(user).to receive(:person).and_return(person)
      render 'shared/my_portal_links'
    end

    it "should have portal links and dropdown" do
      expect(rendered).to have_selector('.dropdown-menu')
      expect(rendered).to have_content('My Insured Portal')
      expect(rendered).to have_content('My Broker Agency Portal')
    end

  end

  context "with General Agency role" do
    let(:user) { FactoryGirl.create(:user, person: person, roles: ["general_agency_staff"]) }
    let!(:person) { FactoryGirl.create(:person, :with_general_agency_staff_role)}

    before :each do
      sign_in(user)
      allow(user).to receive(:person).and_return(person)
      render 'shared/my_portal_links'
    end

    it "should have portal links and dropdown" do
      expect(rendered).to have_selector('.dropdown-menu')
      expect(rendered).to have_content('Add Consumer Role')
      expect(rendered).to have_content('My General Agency Portal')
    end

  end

  context "with General Agency role and Consumer role" do
    let(:user) { FactoryGirl.create(:user, person: person, identity_verified_date: TimeKeeper.date_of_record, roles: ["general_agency_staff", "consumer"]) }
    let!(:person) { FactoryGirl.create(:person, :with_general_agency_staff_role, :with_consumer_role)}

    before :each do
      allow(user).to receive(:person).and_return(person)
      sign_in(user)
      render 'shared/my_portal_links'
    end

    it "should have portal links and dropdown" do
      expect(rendered).to have_selector('.dropdown-menu')
      expect(rendered).to have_content('My Insured Portal')
      expect(rendered).to have_content('My General Agency Portal')
    end

  end


end
