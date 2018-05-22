RSpec.shared_context "setup initial benefit application", :shared_context => :metadata do
  
  let(:package_kind) { :single_issuer }
  let(:benefit_sponsorship) { create(:benefit_sponsors_benefit_sponsorship, :with_organization_cca_profile, benefit_market: benefit_market) }
  let(:initial_application) { create(:benefit_sponsors_benefit_application, :with_benefit_sponsor_catalog, benefit_sponsorship: benefit_sponsorship, effective_period: effective_period) }
  let(:product_package) { initial_application.benefit_sponsor_catalog.product_packages.detect { |package| package.package_kind == package_kind } }
  let(:current_benefit_package) { create(:benefit_sponsors_benefit_packages_benefit_package, product_package: product_package, benefit_application: initial_application) }

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
  let(:census_employees) { create_list(:census_employee, 5, :with_active_assignment, benefit_sponsorship: benefit_sponsorship, employer_profile: benefit_sponsorship.profile, benefit_group: current_benefit_package) }
end

RSpec.shared_context "setup employees with benefits", :shared_context => :metadata do
  include_context "setup employees"

  let(:census_employees) { create_list(:census_employee, 5, :with_active_assignment, benefit_sponsorship: benefit_sponsorship, employer_profile: benefit_sponsorship.profile, benefit_group: current_benefit_package) }
end