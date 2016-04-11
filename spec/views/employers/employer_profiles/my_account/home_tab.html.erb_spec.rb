require "rails_helper"

RSpec.describe "employers/employer_profiles/my_account/_home_tab.html.erb" do
  context "employer profile dashboard" do

    let(:start_on){TimeKeeper.date_of_record.beginning_of_year}
    let(:end_on){TimeKeeper.date_of_record.end_of_year}

    def new_organization
      instance_double(
        "Organization",
        office_locations: new_office_locations
      )
    end

    def office_location
      random_value = rand(999_999_999)
      instance_double(
        "OfficeLocation",
        address: new_address(random_value),
        phone: new_phone(random_value),
        )
    end

    def new_address(random_value)
      double(
        "Address",
        kind: "test#{random_value}",
        to_html: "test"
        )
    end

    def new_phone(random_value)
      double(
        "Phone",
        kind: "test#{random_value}"
        )
    end

    def broker_agency_account
      instance_double(
        "BrokerAgencyAccount",
        is_active: true,
        writing_agent: broker_role
        )
    end

    def employer_profile
      instance_double(
        "EmployerProfile",
        legal_name: "My silly name",
        organization: new_organization,
        fein: "098111000",
        entity_kind: "my entity kind",
        broker_agency_profile: new_broker_agency_profile,
        published_plan_year: plan_year
        )
    end

    def new_broker_agency_profile
      instance_double(
        "BrokerAgencyProfile",
        legal_name: "my broker legal name",
        primary_broker_role: broker_role
        )
    end

    def carrier_profile
      random_value = rand(999_999_999)
      double(
        "CarrierProfile",
        legal_name: "legal_name#{random_value}"
        )
    end

    def reference_plan_1
      double(
        "Plan",
        name: "name_1",
        active_year: 2016,
        coverage_kind: "health",
        plan_type: "ppo",
        metal_level: "metal_level_1",
        carrier_profile: carrier_profile,
        id: "12312312312323",
        )
    end

    def reference_plan_2
      double(
        "Plan",
        name: "name_2",
        active_year: 2016,
        coverage_kind: "health",
        plan_type: "",
        metal_level: "metal_level_2",
        carrier_profile: carrier_profile,
        id: "12312312312323",

        )
    end

    def benefit_group_1
      double(
        "BenefitGroup",
        id: "someotherid",
        title: "title_1",
        effective_on_kind: "first_of_month",
        effective_on_offset: "30",
        plan_option_kind: "plan_option_kind_1",
        relationship_benefits: [relationship_benefits],
        dental_relationship_benefits: [dental_relationship_benefits],
        reference_plan: reference_plan_1,
        reference_plan_id: double("id"),
        monthly_employer_contribution_amount: "monthly_employer_contribution_amount_1",
        monthly_min_employee_cost: "monthly_min_employee_cost_1",
        monthly_max_employee_cost: "monthly_max_employee_cost_1",
        dental_reference_plan_id: double("id"),
        dental_reference_plan: reference_plan_1,
        dental_plan_option_kind: 'single_plan',
        elected_dental_plan_ids: [:dental_reference_plan_id, :dental_reference_plan_id],
        elected_dental_plans: [reference_plan_1]


        )
    end

    def benefit_group_2
      double(
        "BenefitGroup",
        id: "someid",
        title: "title_2",
        effective_on_kind: "date_of_hire",
        effective_on_offset: "0",
        plan_option_kind: "plan_option_kind_2",
        relationship_benefits: [relationship_benefits],
        dental_relationship_benefits: [dental_relationship_benefits],
        reference_plan: reference_plan_2,
        reference_plan_id: double("id"),
        monthly_employer_contribution_amount: "monthly_employer_contribution_amount_2",
        monthly_min_employee_cost: "monthly_min_employee_cost_2",
        monthly_max_employee_cost: "monthly_max_employee_cost_2",
        dental_reference_plan_id: double("id"),
        dental_reference_plan: reference_plan_2,
        dental_plan_option_kind: 'single_plan',
        elected_dental_plan_ids: [:dental_reference_plan_id, :dental_reference_plan_id],
        elected_dental_plans: [reference_plan_2]
        )
    end

    def relationship_benefits
      random_value = rand(999_999_999)
      double(
        "RelationshipBenefit",
        offered: "offered;#{random_value}",
        relationship: "relationship;#{random_value}",
        premium_pct: "premium_pct;#{random_value}"
        )
    end

    def dental_relationship_benefits
      random_value = rand(999_999_999)
      double(
        "RelationshipBenefit",
        offered: "offered;#{random_value}",
        relationship: "relationship;#{random_value}",
        premium_pct: "premium_pct;#{random_value}"
        )
    end

    def plan_year
      instance_double(
        "PlanYear",
        start_on: start_on,
        end_on: end_on,
        open_enrollment_start_on: PlanYear.calculate_open_enrollment_date(start_on)[:open_enrollment_start_on],
        open_enrollment_end_on: PlanYear.calculate_open_enrollment_date(start_on)[:open_enrollment_end_on],
        eligible_to_enroll_count: 4,
        covered_count: 4,
        waived_count: 4,
        total_enrolled_count: 10,
        employee_participation_percent: 40,
        non_business_owner_enrollment_count: 10,
        hbx_enrollments: [hbx_enrollment],
        additional_required_participants_count: 5,
        benefit_groups: benefit_groups,
        aasm_state: 'draft'
        )
    end

    def broker_role
      instance_double(
        "BrokerRole",
        person: new_person,
        npn: 7232323
        )
    end

    def new_person
      random_value = rand(999_999_999)
      instance_double(
        "Person",
        full_name: "my full name",
        phones: [new_phone(random_value)],
        emails: [new_email]
        )
    end

    def new_email
      instance_double(
        "Email",
        address: "test@example.com"
        )
    end

    def hbx_enrollment
      instance_double(
        "HbxEnrollment",
        total_premium: double("total_premium"),
        total_employer_contribution: double("total_employer_contribution"),
        total_employee_cost: double("total_employee_cost")
        )
    end

    let(:new_office_locations){[office_location,office_location]}
    let(:current_plan_year){employer_profile.published_plan_year}
    let(:benefit_groups){ [benefit_group_1, benefit_group_2] }

    before :each do
      # allow(benefit_group_2).to receive(:elected_dental_plans).and_return(benefit_group_2.elected_dental_plan_ids)
      assign :employer_profile, employer_profile
      assign :hbx_enrollments, [hbx_enrollment]
      assign :current_plan_year, employer_profile.published_plan_year
      assign :participation_minimum, 0
      assign :broker_agency_accounts, [ broker_agency_account ]
      controller.request.path_parameters[:id] = "11111111"
      render partial: "employers/employer_profiles/my_account/home_tab"
    end

    it "should display title" do
      expect(rendered).to have_selector("h1", text: "My Health Benefits Program")
    end

    it "should display benefit groups" do
      current_plan_year.benefit_groups.each do |bg|
        expect(rendered).to match(/.*#{bg.title}.*/mi)
        expect(rendered).to match(/.*#{bg.reference_plan.plan_type}.*/mi)
      end
    end

    it "should display a link to custom dental plans modal" do
      expect(rendered).to have_selector("a", text: "View Plans")
    end

  end
end
