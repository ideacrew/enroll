require "rails_helper"

RSpec.describe "insured/group_selection/new.html.erb" do
  context "coverage selection" do
    let(:person) { FactoryGirl.create(:person, is_incarcerated: false, us_citizen: true) }
    let(:employee_role) { FactoryGirl.create(:employee_role) }
    let(:benefit_group) { FactoryGirl.create(:benefit_group) }
    let(:family_member1) { double(id: "family_member", primary_relationship: "self", dob: Date.new(1990,10,10), full_name: "member") }
    let(:family_member2) { double(id: "family_member", primary_relationship: "parent", dob: Date.new(1990,10,10), full_name: "member") }
    let(:family_member3) { double(id: "family_member", primary_relationship: "spouse", dob: Date.new(1990,10,10), full_name: "member") }
    let(:coverage_household) { double(family_members: [family_member1, family_member2, family_member3]) }
    let(:hbx_enrollment) {HbxEnrollment.new}
    let(:current_user) {FactoryGirl.create(:user)}

    before(:each) do
      assign(:person, person)
      assign(:employee_role, employee_role)
      assign(:coverage_household, coverage_household)
      assign(:market_kind, 'shop')
      assign(:hbx_enrollment, hbx_enrollment)
      sign_in current_user
      allow(employee_role).to receive(:benefit_group).and_return(benefit_group)
      allow(family_member1).to receive(:is_primary_applicant?).and_return(true)
      allow(family_member2).to receive(:is_primary_applicant?).and_return(false)
      allow(family_member3).to receive(:is_primary_applicant?).and_return(false)
      allow(person).to receive(:has_active_employee_role?).and_return(false)
      allow(hbx_enrollment).to receive(:effective_on).and_return(TimeKeeper.date_of_record.end_of_month + 1.day)
      allow(hbx_enrollment).to receive(:can_terminate_coverage?).and_return(true)

      allow(family_member1).to receive(:person).and_return(person)
      allow(family_member2).to receive(:person).and_return(person)
      allow(family_member3).to receive(:person).and_return(person)
      #@eligibility = InsuredEligibleForBenefitRule.new(employee_role,'shop')
      #allow(@eligibility).to receive(:satisfied?).and_return([true, true, false])
      controller.request.path_parameters[:person_id] = person.id
      controller.request.path_parameters[:employee_role_id] = employee_role.id
      render :template => "insured/group_selection/new.html.erb"
    end

    it "should show the title of family members" do
      expect(rendered).to match /Choose Coverage for your Household/
    end

    it "should have three checkbox option" do
      expect(rendered).to have_selector("input[type='checkbox']", count: 3)
    end

    it "should have two checked checkbox option and a checked radio button" do
      expect(rendered).to have_selector("input[checked='checked']", count: 3)
    end

    it "should have a disabled checkbox option" do
      expect(rendered).to have_selector("input[disabled='disabled']", count: 1)
    end

    it "should have a readonly checkbox option" do
      expect(rendered).to have_selector("input[readonly='readonly']", count: 1)
    end

    it "should have a 'not eligible'" do
      expect(rendered).to have_selector('td', text: 'ineligible relationship')
    end

  end
  context "coverage selection with incarcerated" do
    let(:jail_person) { FactoryGirl.create(:person, is_incarcerated: true, us_citizen: true) }
    let(:person2) { FactoryGirl.create(:person, us_citizen: true, is_incarcerated: false) }
    let(:person3) { FactoryGirl.create(:person, us_citizen: true, is_incarcerated: false) }
    let(:consumer_role) { FactoryGirl.create(:consumer_role, person: jail_person) }
    let(:consumer_role2) { FactoryGirl.create(:consumer_role, person: person2) }
    let(:consumer_role3) { FactoryGirl.create(:consumer_role, person: person3) }

    let(:benefit_package) { FactoryGirl.build(:benefit_package,
      title: "individual_health_benefits_2015",
      elected_premium_credit_strategy: "unassisted",
      benefit_eligibility_element_group: BenefitEligibilityElementGroup.new(
        market_places:        ["individual"],
        enrollment_periods:   ["open_enrollment", "special_enrollment"],
        family_relationships: BenefitEligibilityElementGroup::INDIVIDUAL_MARKET_RELATIONSHIP_CATEGORY_KINDS,
        benefit_categories:   ["health"],
        incarceration_status: ["unincarcerated"],
        age_range:            0..0,
        citizenship_status:   ["us_citizen", "naturalized_citizen", "alien_lawfully_present", "lawful_permanent_resident"],
        residency_status:     ["state_resident"],
        ethnicity:            ["any"]
    ))}

    let(:family_member2) { instance_double("FamilyMember",id: "family_member", primary_relationship: "child", dob: Date.new(2010,11,18), full_name: "cgukd", is_primary_applicant: false, person: person2) }
    let(:family_member3) { instance_double("FamilyMember",id: "family_member", primary_relationship: "spouse", dob: Date.new(1991,9,21), full_name: "spouse", is_primary_applicant: false, person: person3) }
    let(:family_member4) { instance_double("FamilyMember",id: "family_member", primary_relationship: "self", dob: Date.new(1990,10,28), full_name: "inmsr", is_primary_applicant: true, person: jail_person) }
    let(:coverage_household_jail) { instance_double("CoverageHousehold",family_members: [family_member4, family_member2, family_member3]) }
    let(:hbx_enrollment) {HbxEnrollment.new}
    let(:benefit_sponsorship) {double(earliest_effective_date: TimeKeeper.date_of_record.beginning_of_year)}
    let(:current_hbx) {double(benefit_sponsorship: benefit_sponsorship, under_open_enrollment?: true)}
    let(:current_user) {FactoryGirl.create(:user)}
    before(:each) do
      assign(:person, jail_person)
      assign(:consumer_role, consumer_role)
      assign(:coverage_household, coverage_household_jail)
      assign(:market_kind, 'individual')
      assign(:benefit, benefit_package)
      assign(:hbx_enrollment, hbx_enrollment)
      allow(HbxProfile).to receive(:current_hbx).and_return(current_hbx)
      allow(jail_person).to receive(:consumer_role).and_return(consumer_role)
      allow(person2).to receive(:consumer_role).and_return(consumer_role2)
      allow(consumer_role2).to receive(:is_incarcerated?).and_return(false)
      allow(person3).to receive(:consumer_role).and_return(consumer_role3)
      allow(consumer_role3).to receive(:is_incarcerated?).and_return(false)
      allow(hbx_enrollment).to receive(:effective_on).and_return(TimeKeeper.date_of_record.end_of_month + 1.day)
      allow(hbx_enrollment).to receive(:can_terminate_coverage?).and_return(true)
      controller.request.path_parameters[:person_id] = jail_person.id
      controller.request.path_parameters[:consumer_role_id] = consumer_role.id
      allow(family_member4).to receive(:first_name).and_return('joey')
      allow(family_member4).to receive(:gender).and_return('female')
      sign_in current_user
      render :template => "insured/group_selection/new.html.erb"
    end

    it "should show the title of family members" do
      expect(rendered).to match /Choose Coverage for your Household/
    end

    it "should have three checkbox option" do
      expect(rendered).to have_selector("input[type='checkbox']", count: 3)
    end

    it "should have one ineligible row" do
      expect(rendered).to have_selector("tr[class='ineligible_row']", count: 1)
    end

    it "should have coverage_kinds area" do
      expect(rendered).to match /Coverage Type/
    end

    it "should have health radio button" do
      expect(rendered).to have_selector('input[value="health"]')
      expect(rendered).to have_selector('label', text: 'Health')
    end

    #it "should have dental radio button" do
    #  expect(rendered).to have_selector('input[value="dental"]')
    #  expect(rendered).to have_selector('label', text: 'Dental')
    #end

    it "should have an incarceration warning with more text" do
      expect(rendered).to match /Other family members may still be eligible to enroll/
    end

    it "should match the pronoun in the text" do
      expect(rendered).to match /, she is not eligible/
    end

  end

  context "family member" do
    def new_benefit_group
      instance_double(
        "BenefitGroup",
        relationship_benefits: new_relationship_benefit
      )
    end

    def new_relationship_benefit
      random_value=rand(999_999_999)
      double(
        "RelationshipBenefit",
        offered: "offered:#{random_value}",
        select: double(map: "test")
      )
    end

    def new_family_member
      random_value=rand(999_999_999)
      instance_double(
        "FamilyMember",
        id: "id_#{random_value}",
        dob: 25.years.ago,
        full_name: "full_name_#{random_value}",
        is_primary_applicant?: true,
        primary_relationship: "self",
        person:  FactoryGirl.create(:person, is_incarcerated: false, us_citizen: true)
      )
    end

    def new_family_member_1
      random_value=rand(999_999_999)
      instance_double(
        "FamilyMember",
        id: "id_#{random_value}",
        dob: 3.years.ago,
        full_name: "full_name_#{random_value}",
        is_primary_applicant?: false,
        primary_relationship: "child",
        person:  FactoryGirl.create(:person, is_incarcerated: false, us_citizen: true)
      )
    end

    let(:family_members){[new_family_member, new_family_member_1]}
    let(:person) { instance_double("Person", id: "Person.id") }
    let(:coverage_household) { instance_double("CoverageHousehold", family_members: family_members) }
    let(:employee_role) { instance_double("EmployeeRole", id: "EmployeeRole.id", benefit_group: new_benefit_group) }
    let(:hbx_enrollment) {HbxEnrollment.new}

    before :each do
      assign :person, person
      assign :employee_role, employee_role
      assign :coverage_household, coverage_household
      assign :eligibility, instance_double("InsuredEligibleForBenefitRule", :satisfied? => true)
      assign :hbx_enrollment, hbx_enrollment
      allow(person).to receive(:has_active_employee_role?).and_return(false)
      allow(employee_role).to receive(:is_under_open_enrollment?).and_return(true)
      allow(hbx_enrollment).to receive(:effective_on).and_return(TimeKeeper.date_of_record.end_of_month + 1.day)
      allow(hbx_enrollment).to receive(:can_terminate_coverage?).and_return(true)
      render file: "insured/group_selection/new.html.erb"
    end

    it "should display family members" do
      family_members.each do |member|
        expect(rendered).to match(/#{member.full_name}/m)

      end
    end
  end

  context "change plan" do
    let(:person) { FactoryGirl.create(:person) }
    let(:employee_role) { FactoryGirl.create(:employee_role) }
    let(:benefit_group) { FactoryGirl.create(:benefit_group) }
    let(:coverage_household) { double(family_members: []) }
    let(:hbx_enrollment) {HbxEnrollment.new}

    before :each do
      allow(employee_role).to receive(:benefit_group).and_return(benefit_group)
      assign :person, person
      assign :employee_role, employee_role
      assign :coverage_household, coverage_household
      assign :market_kind, 'individual'
      assign :change_plan, true
      assign :hbx_enrollment, hbx_enrollment
      allow(hbx_enrollment).to receive(:effective_on).and_return(TimeKeeper.date_of_record.end_of_month + 1.day)
      allow(hbx_enrollment).to receive(:coverage_selected?).and_return(true)
      allow(hbx_enrollment).to receive(:can_terminate_coverage?).and_return(true)
    end

    it "should display title" do
      render file: "insured/group_selection/new.html.erb"
      expect(rendered).to match(/What would you like to do/)
    end

    it "should show shop for new plan submit" do
      allow(benefit_group).to receive(:plan_option_kind).and_return("metal_level")
      render file: "insured/group_selection/new.html.erb"
      expect(rendered).to have_selector("input[value='Shop for new plan']")
    end

    it "should not show shop for new plan submit when single_plan" do
      allow(benefit_group).to receive(:plan_option_kind).and_return("single_plan")
      render file: "insured/group_selection/new.html.erb"
      expect(rendered).to have_selector("input[value='Shop for new plan']", count: 0)
    end

    it "when hbx_enrollment not terminated" do
      allow(view).to receive(:show_keep_existing_plan).and_return true
      render file: "insured/group_selection/new.html.erb"
      expect(rendered).to have_selector("input[value='Keep existing plan']", count: 1)
      expect(rendered).to have_selector("a", text: "Select Plan to Terminate",  count: 1)
    end

    it "when hbx_enrollment not terminated and not shop_for_plans" do
      assign(:shop_for_plans, "shop_for_plans")
      render file: "insured/group_selection/new.html.erb"
      expect(rendered).to have_selector("input[value='Keep existing plan']", count: 0)
      expect(rendered).to have_selector("a", text: "Select Plan to Terminate",  count: 1)
    end

    it "when hbx_enrollment is terminated" do
      allow(hbx_enrollment).to receive(:coverage_selected?).and_return(false)
      allow(hbx_enrollment).to receive(:auto_renewing?).and_return(false)
      render file: "insured/group_selection/new.html.erb"
      expect(rendered).to have_selector("input[value='Keep existing plan']", count: 0)
    end

    it "should have back to my account link" do
      render file: "insured/group_selection/new.html.erb"
      expect(rendered).to have_selector("a[href='/families/home']", text: 'Back to my account')
    end
  end

  context "market_kind" do
    let(:person) { FactoryGirl.create(:person) }
    let(:employee_role) { FactoryGirl.create(:employee_role) }
    let(:benefit_group) { FactoryGirl.create(:benefit_group) }
    let(:coverage_household) { double(family_members: []) }
    let(:hbx_enrollment) {HbxEnrollment.new}

    before :each do
      allow(employee_role).to receive(:benefit_group).and_return(benefit_group)
      assign :person, person
      assign :employee_role, employee_role
      assign :coverage_household, coverage_household
      assign :change_plan, true
      assign :hbx_enrollment, hbx_enrollment
      allow(hbx_enrollment).to receive(:effective_on).and_return(TimeKeeper.date_of_record.end_of_month + 1.day)
      allow(hbx_enrollment).to receive(:coverage_selected?).and_return(true)
      allow(hbx_enrollment).to receive(:can_terminate_coverage?).and_return(true)
    end

    it "when present" do
      assign :market_kind, "shop"
      render file: "insured/group_selection/new.html.erb"
      expect(rendered).to have_selector("input[type='hidden']")
      expect(rendered).to have_selector("input[value='shop']")
    end

    context "when blank" do
      before :each do
        assign :market_kind, ""
        render file: "insured/group_selection/new.html.erb"
      end

      # it "should have title" do
      #   expect(rendered).to match /Market Kind/
      # end
      #
      # it "should have options" do
      #   Plan::MARKET_KINDS.each do |kind|
      #     expect(rendered).to have_selector("input[value='#{kind}']")
      #   end
      # end
    end
  end
end
