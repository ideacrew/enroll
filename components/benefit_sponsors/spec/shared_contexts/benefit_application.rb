RSpec.shared_context "setup initial benefit application", :shared_context => :metadata do
  let(:aasm_state)              { :active }
  let(:package_kind)            { :single_issuer }
  let(:effective_period)        { current_effective_date..current_effective_date.next_year.prev_day }
  let(:open_enrollment_period)  { effective_period.min.prev_month..(effective_period.min - 10.days) }

  let!(:abc_organization)       { create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
  let(:abc_profile)             { abc_organization.employer_profile }
  let(:abc_benefit_sponsorship)     { abc_profile.add_benefit_sponsorhip }

  # let!(:abc_benefit_sponsorship) { BenefitSponsors::BenefitSponsorships::BenefitSponsorship.new(profile: abc_organization.employer_profile) }

  # let!(:initial_application)     { BenefitSponsors::BenefitApplications::BenefitApplication.new(

  let!(:initial_application)     { BenefitSponsors::BenefitApplications::BenefitApplication.new(
                                      benefit_sponsorship: abc_benefit_sponsorship,
                                      effective_period: effective_period,
                                      aasm_state: aasm_state,
                                      open_enrollment_period: open_enrollment_period,
                                      fte_count: 5,
                                      pte_count: 0,
                                      msp_count: 0
                                  ) }


  let!(:benefit_sponsor_catalog)  { initial_application.benefit_sponsor_catalog}
  let(:product_package)           { initial_application.benefit_sponsor_catalog.product_packages.detect { |package| package.package_kind == package_kind } }
  let(:current_benefit_package)   { build(:benefit_sponsors_benefit_packages_benefit_package, product_package: product_package, benefit_application: initial_application) }

  # let(:health_sponsored_benefit)  { build(:benefit_sponsors_sponsored_benefits_health_sponsored_benefit, product_package: product_package, benefit_package: current_benefit_package) }
  # before { binding.pry; benefit_sponsorship.save!; initial_application.save! }

  before do
    # current_benefit_package.sponsored_benefits = [health_sponsored_benefit]
    initial_application.benefit_packages = [current_benefit_package]
    benefit_sponsorship.benefit_applications = [initial_application]
    benefit_sponsorship.save!
  end

  it 'should create a valid benefit sponsorship' do
    expect(benefit_sponsorship).to be_valid
  end

  it 'should create a valid benefit application' do
    expect(initial_application).to be_valid
  end

  it 'should create a valid package with sponsored benefit' do
    expect(current_benefit_package).to be_valid
    expect(current_benefit_package.sponsored_benefits).to be_present
    expect(current_benefit_package.sponsored_benefits.first.product_package).to eq product_package
  end
end

RSpec.shared_context "setup employees", :shared_context => :metadata do
  let!(:census_employees) { create_list(:census_employee, 5, :with_active_assignment, benefit_sponsorship: benefit_sponsorship, employer_profile: benefit_sponsorship.profile, benefit_group: current_benefit_package) }
end

RSpec.shared_context "setup employees with benefits", :shared_context => :metadata do
  include_context "setup employees"

  let!(:census_employees) { create_list(:census_employee, 5, :with_active_assignment, benefit_sponsorship: benefit_sponsorship, employer_profile: benefit_sponsorship.profile, benefit_group: current_benefit_package) }
end

RSpec.shared_context "setup application with benefit package and sponsored benefits", shared_context: :metadata do
end
