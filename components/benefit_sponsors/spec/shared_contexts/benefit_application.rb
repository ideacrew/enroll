RSpec.shared_context "setup initial benefit application", :shared_context => :metadata do
  
  let(:aasm_state)                { :active }
  let(:benefit_sponsorship_state) { :active }
  let(:package_kind)              { :single_issuer }
  let(:effective_period)          { current_effective_date..(current_effective_date.next_year.prev_day) }
  let(:open_enrollment_start_on)  { current_effective_date.prev_month }
  let(:open_enrollment_period)    { open_enrollment_start_on..(open_enrollment_start_on+5.days) }
  let!(:abc_organization)         { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
  let(:abc_profile)               { abc_organization.employer_profile }
  
  let!(:benefit_sponsorship)    { 
    benefit_sponsorship = abc_profile.add_benefit_sponsorship
    benefit_sponsorship.aasm_state = benefit_sponsorship_state
    benefit_sponsorship.save
    benefit_sponsorship
  }
  
  let(:dental_sponsored_benefit) { false }
  let!(:rating_area) { create_default(:benefit_markets_locations_rating_area) }
  let!(:service_areas) { 
    benefit_sponsorship.service_areas_on(effective_period.min)
  }

  let(:benefit_sponsor_catalog) { benefit_sponsorship.benefit_sponsor_catalog_for(service_areas, effective_period.min) }
  let(:initial_application)     { BenefitSponsors::BenefitApplications::BenefitApplication.new(
                                      benefit_sponsor_catalog: benefit_sponsor_catalog,
                                      effective_period: effective_period,
                                      aasm_state: aasm_state,
                                      open_enrollment_period: open_enrollment_period,
                                      recorded_rating_area: rating_area,
                                      recorded_service_areas: service_areas,
                                      fte_count: 5,
                                      pte_count: 0,
                                      msp_count: 0
                                  ) }

  let(:product_package)           { initial_application.benefit_sponsor_catalog.product_packages.detect { |package| package.package_kind == package_kind } }
  let(:dental_product_package)    { initial_application.benefit_sponsor_catalog.product_packages.detect { |package| package.product_kind == :dental } }
  let(:current_benefit_package)   { build(:benefit_sponsors_benefit_packages_benefit_package, health_sponsored_benefit: true, dental_sponsored_benefit: dental_sponsored_benefit, product_package: product_package, dental_product_package: dental_product_package, benefit_application: initial_application) }

  before do
    initial_application.benefit_packages = [current_benefit_package]
    benefit_sponsorship.benefit_applications = [initial_application]
    benefit_sponsorship.save!
    benefit_sponsor_catalog.save!
  end
end

RSpec.shared_context "setup employees", :shared_context => :metadata do
  let!(:census_employees) { create_list(:census_employee, 5, benefit_sponsorship: benefit_sponsorship, employer_profile: benefit_sponsorship.profile, benefit_group: current_benefit_package) }
end

RSpec.shared_context "setup employees with benefits", :shared_context => :metadata do
  # include_context "setup employees"
  let(:roster_size) { 5 }
  let(:enrollment_kinds) { ['health'] }
  let!(:census_employees) { create_list(:census_employee, roster_size, :with_active_assignment, benefit_sponsorship: benefit_sponsorship, employer_profile: benefit_sponsorship.profile, benefit_group: current_benefit_package) }

end

RSpec.shared_context "setup renewal application", :shared_context => :metadata do

  let(:predecessor_state)       { :active }
  let(:renewal_state)           { :draft }

  let(:package_kind)            { :single_issuer }
  let(:dental_package_kind)     { :single_product }
  let(:renewal_effective_date)  { (TimeKeeper.date_of_record + 2.months).beginning_of_month }
  let(:current_effective_date)  { renewal_effective_date.prev_year }
  let(:effective_period)        { renewal_effective_date..renewal_effective_date.next_year.prev_day }
  let(:open_enrollment_period)  { effective_period.min.prev_month..(effective_period.min - 10.days) }

  let(:abc_organization)       { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
  let(:abc_profile)            { abc_organization.employer_profile }
  let!(:benefit_sponsorship)    { abc_profile.add_benefit_sponsorship }

  let(:recorded_service_areas) { benefit_sponsorship.service_areas_on(effective_period.min) }

  let(:dental_sponsored_benefit) { false }
  let(:current_dental_product_package)    { renewal_benefit_market_catalog.product_packages.detect { |package| package.product_kind == :dental } }
  let(:predeccesor_dental_product_package)    { current_benefit_market_catalog.product_packages.detect { |package| package.product_kind == :dental } }

  let(:predecessor_application_catalog) { false }

  let!(:renewal_application)  { create(:benefit_sponsors_benefit_application, :with_benefit_sponsor_catalog,
                                      :with_benefit_package, :with_predecessor_application,
                                      predecessor_application_state: predecessor_state,
                                      benefit_sponsorship: benefit_sponsorship,
                                      effective_period: effective_period,
                                      aasm_state: renewal_state,
                                      open_enrollment_period: open_enrollment_period,
                                      recorded_rating_area: benefit_sponsorship.rating_area,
                                      recorded_service_areas: recorded_service_areas,
                                       package_kind: package_kind,
                                       dental_package_kind: dental_package_kind,
                                       dental_sponsored_benefit: dental_sponsored_benefit,
                                       predecessor_application_catalog: predecessor_application_catalog
                                    ) }

  let(:predecessor_application) { renewal_application.predecessor }

  let(:product_package)           { renewal_application.benefit_sponsor_catalog.product_packages.detect { |package| package.package_kind == package_kind } }
  let(:benefit_package)           { renewal_application.benefit_packages[0] }
  let(:current_benefit_package)   { predecessor_application.benefit_packages[0] }
end
