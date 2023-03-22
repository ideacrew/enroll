RSpec.describe SponsoredBenefits::Services::PlanCostService, type: :model, dbclean: :after_each do
  let!(:rating_area) do
    FactoryBot.create(:rating_area, zip_code: ofice_location.address.zip, county_name: ofice_location.address.county) if EnrollRegistry.feature_enabled?(:rating_area)
  end

  let(:plan_design_organization) do
    FactoryBot.create :sponsored_benefits_plan_design_organization,
      owner_profile_id: owner_profile.id,
      sponsor_profile_id: sponsor_profile.id
  end

  let(:plan_design_proposal) do
    FactoryBot.create(:plan_design_proposal,
      :with_profile,
      plan_design_organization: plan_design_organization
    ).tap do |proposal|
      sponsorship = proposal.profile.benefit_sponsorships.first
      sponsorship.initial_enrollment_period = benefit_sponsorship_enrollment_period
      sponsorship.save
    end
  end

  let(:ofice_location) { proposal_profile.office_locations.where(is_primary: true).first }

  let(:proposal_profile) { plan_design_proposal.profile }

  let(:benefit_sponsorship_enrollment_period) do
    begin_on = SponsoredBenefits::BenefitApplications::BenefitApplication.calculate_start_on_dates[0]
    end_on = begin_on + 1.year - 1.day
    begin_on..end_on
  end

  let(:benefit_sponsorship) { proposal_profile.benefit_sponsorships.first }

  let(:benefit_application) do
    FactoryBot.create :plan_design_benefit_application,
      :with_benefit_group,
      benefit_sponsorship: benefit_sponsorship
  end

  let(:reference_plan) { FactoryBot.create(:plan, :with_complex_premium_tables, :with_rating_factors) }

  let(:benefit_group) do
    benefit_application.benefit_groups.first.tap do |benefit_group|
      benefit_group.update_attributes(reference_plan_id: reference_plan.id, plan_option_kind: 'single_carrier')
    end
  end

  let(:owner_profile) { broker_agency_profile }
  let(:broker_agency) { owner_profile.organization }
  let(:general_agency_profile) { ga_profile }

  let(:employer_profile) { sponsor_profile }
  let(:benefit_sponsor) { sponsor_profile.organization }

  let!(:plan_design_census_employee) do
    FactoryBot.create_list :plan_design_census_employee, 2,
      :with_random_age,
      benefit_sponsorship_id: benefit_sponsorship.id
  end

  let(:census_dependent) { FactoryBot.create(:plan_design_census_employee, :with_random_age, benefit_sponsorship_id: benefit_sponsorship.id) }

  let(:organization) { plan_design_organization.sponsor_profile.organization }

  let!(:current_effective_date) do
    (TimeKeeper.date_of_record + 2.months).beginning_of_month.prev_year
  end

  let!(:broker_agency_profile) do
    if EnrollRegistry.feature_enabled?(:rating_area)
      FactoryBot.create(:benefit_sponsors_organizations_general_organization,
        :with_site,
        :with_broker_agency_profile
      ).profiles.first
    else
      FactoryBot.create(:broker_agency_profile)
    end
  end

  let!(:sponsor_profile) do
    if EnrollRegistry.feature_enabled?(:rating_area)
      FactoryBot.create(:benefit_sponsors_organizations_general_organization,
        :with_site,
        :with_aca_shop_cca_employer_profile
      ).profiles.first
    else
      FactoryBot.create(:employer_profile)
    end
  end

  let!(:relationship_benefit) { benefit_group.relationship_benefits.first }
  let(:subject) { SponsoredBenefits::Services::PlanCostService.new(benefit_group: benefit_group)}

  it "should have multiple_rating_areas instance variable" do
    expect(subject.instance_variable_get("@multiple_rating_areas")).to eq EnrollRegistry[:rating_area].settings(:areas).item.many?
  end

  context "#monthly_employer_contribution_amount" do
    before :each do
      allow(Caches::PlanDetails).to receive(:lookup_rate_with_area).and_return 78.0
      allow(Caches::PlanDetails).to receive(:lookup_rate).and_return 78.0
    end

    context "when broker_quote_hc4cc_subsidy is disabled" do
      before do
        allow(benefit_application).to receive(:osse_eligible?).and_return false
      end

      it "should return total monthly employer contribution amount" do
        # Er contribution 80%. No.of Employees = 2
        expect(subject.monthly_employer_contribution_amount).to eq(0.8 * 2 * 78.0)
      end

      context 'relationship_benefit premium pct change.' do
        before :each do
          benefit_group.relationship_benefits.each do |rb|
            rb.update_attributes(premium_pct: 50.0)
          end
        end

        it "should return total monthly employer contribution amount with 50%" do
          # Er contribution 50%. No.of Employees = 2
          expect(subject.monthly_employer_contribution_amount).to eq(0.5 * 2 * 78.0)
        end
      end
    end

    context "when broker_quote_hc4cc_subsidy is enabled" do
      before do
        allow(benefit_application).to receive(:osse_eligible?).and_return true
        allow(subject).to receive(:lcsp).and_return(reference_plan)
      end

      it "should return total monthly employer contribution amount" do
        # Er contribution 80%. No.of Employees = 2 && subsidy = 78.0 for each employee
        expect(subject.monthly_employer_contribution_amount).to eq 0.00
      end
    end
  end

  context "#osse_subsidy_amount" do
    before :each do
      allow(Caches::PlanDetails).to receive(:lookup_rate_with_area).and_return 78.0
      allow(Caches::PlanDetails).to receive(:lookup_rate).and_return 78.0
      allow(subject).to receive(:lcsp).and_return(reference_plan)
      allow(subject).to receive(:plan).and_return(reference_plan)
    end

    context "when broker_quote_hc4cc_subsidy is enabled" do
      before :each do
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:broker_quote_hc4cc_subsidy).and_return(true)
        allow(benefit_application).to receive(:osse_eligible?).and_return true
      end

      it "should return osse subsidy amount for each census employee" do
        plan_design_census_employee.each do |ce|
          expect(subject.osse_subsidy_amount(ce, ce)).to eq 78.00
        end
      end

      it "should return osse subsidy amount 0 for each census dependent" do
        plan_design_census_employee.each do |census_employee|
          expect(subject.osse_subsidy_amount(census_dependent, census_employee)).to eq 0.00
        end
      end
    end

    context "when broker_quote_hc4cc_subsidy is disabled" do
      before :each do
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:broker_quote_hc4cc_subsidy).and_return(false)
      end

      it "should return osse subsidy amount as 0 for each census employee" do
        plan_design_census_employee.each do |ce|
          expect(subject.osse_subsidy_amount(ce, ce)).to eq 0.00
        end
      end
    end
  end

  context "#monthly_employee_costs" do

    before :each do
      allow(Caches::PlanDetails).to receive(:lookup_rate_with_area).and_return 78.0
      allow(Caches::PlanDetails).to receive(:lookup_rate).and_return 78.0
      subject.plan = benefit_group.reference_plan
    end
    it "should return total monthly employee contribution amount" do
      # ER contribution is 80%. EE contribution is 20%
      expect(subject.monthly_employee_costs).to eq [0.2*78.0, 0.2*78.0]
    end
  end
end
