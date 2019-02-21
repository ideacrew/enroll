RSpec.shared_context "set up broker agency profile for BQT, by using configuration settings", :shared_context => :metadata do
  
  let(:plan_design_organization) { FactoryGirl.create(:sponsored_benefits_plan_design_organization,
    owner_profile_id: owner_profile.id,
    sponsor_profile_id: sponsor_profile.id
  )}

  let(:prospect_plan_design_organization) { FactoryGirl.create(:sponsored_benefits_plan_design_organization,
    owner_profile_id: owner_profile.id,
    sponsor_profile_id: nil
  )}

  let(:plan_design_organization_with_assigned_ga) {
    plan_design_organization.general_agency_accounts.create(
      start_on: TimeKeeper.date_of_record,
      general_agency_profile_id: general_agency_profile.id,
      broker_agency_profile_id: owner_profile.id,
      broker_role_id: owner_profile.primary_broker_role.id
    )
    plan_design_organization
  }

  let(:plan_design_proposal) {
    FactoryGirl.create(:plan_design_proposal,
      :with_profile,
      plan_design_organization: plan_design_organization
    ).tap do |proposal|
      sponsorship = proposal.profile.benefit_sponsorships.first
      sponsorship.initial_enrollment_period = benefit_sponsorship_enrollment_period
      sponsorship.save
    end
  }

  let(:prospect_plan_design_proposal) {
    FactoryGirl.create(:plan_design_proposal,
      :with_profile,
      plan_design_organization: prospect_plan_design_organization
    ).tap do |proposal|
      sponsorship = proposal.profile.benefit_sponsorships.first
      sponsorship.initial_enrollment_period = benefit_sponsorship_enrollment_period
      sponsorship.save
    end
  }

  let(:proposal_profile) { plan_design_proposal.profile }
  let(:prospect_proposal_profile) {prospect_proposal_profile.profile}

  let(:benefit_sponsorship_enrollment_period) {
    begin_on = SponsoredBenefits::BenefitApplications::BenefitApplication.calculate_start_on_dates[0]
    end_on = begin_on + 1.year - 1.day
    begin_on..end_on
  }

  let(:benefit_sponsorship) { proposal_profile.benefit_sponsorships.first }
  let(:prospect_benefit_sponsorship) { prospect_proposal_profile.benefit_sponsorships.first}

  let(:benefit_application) { FactoryGirl.create(:plan_design_benefit_application,
    :with_benefit_group,
    benefit_sponsorship: benefit_sponsorship
  )}

  let(:prospect_benefit_application) { FactoryGirl.create(:plan_design_benefit_application,
    :with_benefit_group,
    benefit_sponsorship: benefit_sponsorship
  )}

  let(:benefit_group) { benefit_application.benefit_groups.first }
  let(:prospect_benefit_group) { prospect_benefit_application.benefit_groups.first }

  let(:owner_profile) { broker_agency_profile }
  let(:broker_agency) { owner_profile.organization }
  let(:general_agency_profile) { ga_profile }

  let(:employer_profile) { sponsor_profile }
  let(:benefit_sponsor) { sponsor_profile.organization }

  let(:plan_design_census_employee) { FactoryGirl.create(:plan_design_census_employee,
    benefit_sponsorship_id: benefit_sponsorship.id
  )}

  let(:prospect_plan_design_census_employee) { FactoryGirl.create(:plan_design_census_employee,
    benefit_sponsorship_id: prospect_benefit_sponsorship.id
  )}

  let(:organization) { plan_design_organization.sponsor_profile.organization }

  let(:health_reference_plan) { health_plan }
  let(:dental_reference_plan) { dental_plan }

  let(:health_reference_product) { health_product }
  let(:dental_reference_product) { dental_product }

  def health_plan
    FactoryGirl.create(:plan, :with_premium_tables, coverage_kind: "health")
  end

  def health_product
    FactoryGirl.create(:benefit_markets_products_health_products_health_product,
      :with_renewal_product,
      application_period: (current_effective_date.beginning_of_year..current_effective_date.end_of_year),
      product_package_kinds: [:single_issuer, :metal_level, :single_product],
      service_area: service_area,
      renewal_service_area: renewal_service_area,
      metal_level_kind: :gold
    )
  end

  def dental_plan
    FactoryGirl.create(:plan, :with_premium_tables, coverage_kind: "dental")
  end

  def dental_product
    FactoryGirl.create(:benefit_markets_products_dental_products_dental_product,
      :with_renewal_product,
      application_period: (current_effective_date.beginning_of_year..current_effective_date.end_of_year),
      product_package_kinds: [:single_product],
      service_area: service_area,
      renewal_service_area: renewal_service_area,
      metal_level_kind: :dental
    )
  end

  def service_area
    return @service_area if defined? @service_area
    @service_area = FactoryGirl.create(:benefit_markets_locations_service_area,
      county_zip_ids: [FactoryGirl.create(:benefit_markets_locations_county_zip, county_name: 'Middlesex', zip: '01754', state: 'MA').id],
      active_year: current_effective_date.year
    )
  end

  def renewal_service_area
    return @renewal_service_area if defined? @renewal_service_area

    @renewal_service_area = FactoryGirl.create(:benefit_markets_locations_service_area,
      county_zip_ids: service_area.county_zip_ids,
      active_year: service_area.active_year + 1
    )
  end

  def current_effective_date
    (TimeKeeper.date_of_record + 2.months).beginning_of_month.prev_year
  end

  def broker_agency_profile
    if Settings.aca.state_abbreviation == "DC" # toDo
      FactoryGirl.create(:broker_agency_profile)
    else
      FactoryGirl.create(:benefit_sponsors_organizations_general_organization,
        :with_site,
        :with_broker_agency_profile
      ).profiles.first
    end
  end

  def sponsor_profile
    if Settings.aca.state_abbreviation == "DC" # toDo
      FactoryGirl.create(:employer_profile)
    else
      FactoryGirl.create(:benefit_sponsors_organizations_general_organization,
        :with_site,
        :with_aca_shop_cca_employer_profile
      ).profiles.first
    end
  end

  def ga_profile
    FactoryGirl.create(:general_agency_profile)
  end
end
