# frozen_string_literal: true

require "rails_helper"
require File.join(Rails.root, 'spec/shared_contexts/dchbx_product_selection')
RSpec::Matchers.define_negated_matcher :not_include, :include

describe Operations::ProductSelectionEffects::DchbxProductSelectionEffects, "when:
- there is no current coverage
- there is no renewal
- the selection is IVL
- it is not open enrollment prior to plan year start
", dbclean: :after_each do

  let(:coverage_year) { Date.today.year + 1}

  let(:consumer_role) { FactoryBot.create(:consumer_role) }
  let(:hbx_profile) do
    FactoryBot.create(:hbx_profile,
                      :normal_ivl_open_enrollment,
                      coverage_year: coverage_year)
  end
  let(:benefit_package) { benefit_coverage_period.benefit_packages.first }
  let(:benefit_coverage_period) do
    hbx_profile.benefit_sponsorship.benefit_coverage_periods.detect do |bcp|
      (bcp.start_on.year == coverage_year) && bcp.start_on > bcp.open_enrollment_start_on
    end
  end
  let(:family) {FactoryBot.create(:family, :with_primary_family_member, person: consumer_role.person)}
  let(:product) do
    BenefitMarkets::Products::Product.find(benefit_package.benefit_ids.first)
  end
  let(:ivl_enrollment) do
    FactoryBot.create(:hbx_enrollment,
                      :individual_unassisted,
                      household: family.active_household,
                      effective_on: Date.new(coverage_year, 11, 1),
                      family: family)
  end

  let(:product_selection) do
    Entities::ProductSelection.new({:enrollment => ivl_enrollment, :product => product, :family => family})
  end

  subject do
    product_selection
    Operations::ProductSelectionEffects::DchbxProductSelectionEffects
  end

  it "does not create a renewal after purchase" do
    subject
    allow(TimeKeeper).to receive(:date_of_record).and_return(Date.new(coverage_year, 10, 31))
    subject.call(product_selection)
    family.reload
    expect(family.hbx_enrollments.count).to eq 1
  end
end

describe Operations::ProductSelectionEffects::DchbxProductSelectionEffects, "when:
- there is no current coverage
- there is no renewal
- the selection is IVL
- it is open enrollment prior to plan year start
", dbclean: :after_each do

  let(:coverage_year) { Date.today.year + 1}

  let(:consumer_role) { FactoryBot.create(:consumer_role) }
  let(:hbx_profile) do
    FactoryBot.create(:hbx_profile,
                      :normal_ivl_open_enrollment,
                      coverage_year: coverage_year)
  end
  let(:benefit_package) { benefit_coverage_period.benefit_packages.first }
  let(:benefit_coverage_period) do
    hbx_profile.benefit_sponsorship.benefit_coverage_periods.detect do |bcp|
      (bcp.start_on.year == coverage_year) && bcp.start_on > bcp.open_enrollment_start_on
    end
  end
  let(:family) do
    FactoryBot.create(:family,
                      :with_primary_family_member,
                      person: consumer_role.person)
  end
  let(:product) do
    BenefitMarkets::Products::Product.find(benefit_package.benefit_ids.first)
  end
  let(:renewal_benefit_coverage_period) {benefit_coverage_period.successor}
  let(:renewal_benefit_package) {renewal_benefit_coverage_period.benefit_packages.first}

  let(:start_on) { ivl_enrollment.effective_on }
  let(:address) { consumer_role.rating_address }
  let(:renewal_service_area) do
    ::BenefitMarkets::Locations::ServiceArea.service_areas_for(address, during: start_on.next_year).first || FactoryBot.create_default(:benefit_markets_locations_service_area, active_year: start_on.next_year.year)
  end

  let(:renewal_product) do
    r_product = BenefitMarkets::Products::Product.find(renewal_benefit_package.benefit_ids.first)
    r_product.service_area_id = renewal_service_area.id
    r_product.save
    product.renewal_product_id = r_product.id
    product.save!
    product.reload
    r_product
  end
  let(:rating_area) { FactoryBot.create(:benefit_markets_locations_rating_area) }
  let(:ivl_enrollment) do
    FactoryBot.create(:hbx_enrollment,
                      :individual_unassisted,
                      :with_enrollment_members,
                      enrollment_members: family.family_members,
                      household: family.active_household,
                      effective_on: Date.new(coverage_year, 11, 1),
                      family: family,
                      consumer_role_id: consumer_role.id,
                      rating_area_id: rating_area.id,
                      product: product)
  end

  let(:product_selection) do
    Entities::ProductSelection.new({:enrollment => ivl_enrollment, :product => product, :family => family})
  end

  subject do
    renewal_product
    product_selection
    Operations::ProductSelectionEffects::DchbxProductSelectionEffects
  end

  it "does creates a renewal after purchase" do
    subject
    allow(TimeKeeper).to receive(:date_of_record).and_return(Date.new(coverage_year, 11, 15))
    subject.call(product_selection)
    family.reload
    enrollments = family.hbx_enrollments.sort_by(&:effective_on)
    expect(enrollments.length).to eq 2
    renewal_enrollment = enrollments.last
    renewal_start_date = renewal_enrollment.effective_on
    expect(renewal_benefit_coverage_period.start_on).to eq renewal_start_date
    expect(renewal_enrollment.product_id).to eq renewal_product.id
  end
end

describe Operations::ProductSelectionEffects::DchbxProductSelectionEffects, "when:
 - there is no current coverage
 - there is no prior coverage
 - there is open enrollment
 - the selection is IVL and sep is added for prior coverage year
  ", dbclean: :after_each do

  let(:consumer_role) { FactoryBot.create(:consumer_role) }
  let(:family) do
    FactoryBot.create(:family,
                      :with_primary_family_member,
                      person: consumer_role.person)
  end
  let(:prior_coverage_year) { Date.today.year - 1 }

  let(:product) do
    FactoryBot.create(:benefit_markets_products_health_products_health_product, benefit_market_kind: :aca_individual,
                                                                                application_period: Date.new(prior_coverage_year,1,1)..Date.new(prior_coverage_year,12,31),
                                                                                kind: :health, csr_variant_id: '01')
  end
  let(:qle) { FactoryBot.create(:qualifying_life_event_kind, market_kind: "individual") }
  let(:sep) {  FactoryBot.create(:special_enrollment_period, effective_on: Date.new(prior_coverage_year, 11, 1), family: family, coverage_renewal_flag: false, qualifying_life_event_kind_id: qle.id)}


  let(:prior_ivl_enrollment) do
    FactoryBot.create(:hbx_enrollment,
                      :individual_unassisted,
                      :with_enrollment_members,
                      enrollment_members: family.family_members,
                      special_enrollment_period_id: sep.id,
                      household: family.active_household,
                      effective_on: Date.new(prior_coverage_year, 11, 1),
                      family: family,
                      consumer_role_id: consumer_role.id,
                      product: product)
  end

  let(:product_selection) do
    Entities::ProductSelection.new({:enrollment => prior_ivl_enrollment, :product => product, :family => family})
  end

  let(:current_coverage_year) { Date.today.year }

  let!(:hbx_profile) do
    FactoryBot.create(:hbx_profile,
                      :current_oe_period_with_past_coverage_periods,
                      coverage_year: current_coverage_year)
  end

  subject do
    hbx_profile.benefit_sponsorship.benefit_coverage_periods.last.update(open_enrollment_start_on: Date.new(current_coverage_year, 11, 1),
                                                                         open_enrollment_end_on: Date.new(current_coverage_year, 12, 31))

    product_selection
    allow(TimeKeeper).to receive(:date_of_record).and_return(Date.new(current_coverage_year, 11, 15))
    allow(family).to receive(:current_sep).and_return sep
    Operations::ProductSelectionEffects::DchbxProductSelectionEffects
  end

  it "does not creates a continuous enrollment for future coverage period after purchase" do
    subject
    %i[prior_plan_year_ivl_sep fehb_market indian_alaskan_tribe_details].each do |feature|
      allow(EnrollRegistry[feature].feature).to receive(:is_enabled).and_return(false)
    end

    subject.call(product_selection)
    family.reload
    enrollments = family.hbx_enrollments.sort_by(&:effective_on)
    expect(enrollments.length).to eq 1
    expect(enrollments.last.effective_on.year).to eq prior_coverage_year
  end
end

describe Operations::ProductSelectionEffects::DchbxProductSelectionEffects, "when:
- there is current coverage in active state
- there is prior coverage in expired state
- there is a renewal coverage
- there is open enrollment
- the selection is IVL and sep is added for prior coverage year
- and prior_plan_year ivl sep feature is disabled
", dbclean: :after_each do

  include_context 'family has prior, current and renewal year coverage and in open enrollment and purchased new coverage in prior year via SEP'

  let(:product_selection) do
    Entities::ProductSelection.new({:enrollment => prior_ivl_enrollment, :product => prior_product, :family => family})
  end

  subject do
    current_product
    prior_ivl_enrollment_2
    current_ivl_enrollment
    renewal_ivl_enrollment
    product_selection
    allow(family).to receive(:current_sep).and_return sep
    Operations::ProductSelectionEffects::DchbxProductSelectionEffects
  end

  it 'prior coverage gets terminated and new prior coverage gets created with no change in current and renewal coverage' do
    sep.update_attributes(end_on: Date.new(current_coverage_year, 11, 15))
    subject
    prior_ivl_enrollment.generate_hbx_signature
    allow(TimeKeeper).to receive(:date_of_record).and_return(Date.new(current_coverage_year, 11, 15))
    %i[prior_plan_year_ivl_sep].each do |feature|
      EnrollRegistry[feature].feature.stub(:is_enabled).and_return(false)
    end
    subject.call(product_selection)
    family.reload
    enrollments = family.hbx_enrollments
    expect(enrollments.length).to eq 4
    expect(enrollments.by_year(prior_coverage_year).count).to eq 2
    expect(enrollments.by_year(current_coverage_year).count).to eq 1
    expect(enrollments.by_year(current_coverage_year + 1).count).to eq 1

  end
end

describe Operations::ProductSelectionEffects::DchbxProductSelectionEffects, "when:
- there is no current coverage
- there is no prior coverage
- there is no open enrollment
- the selection is IVL and sep is added for prior coverage year
", dbclean: :after_each do

  include_context 'family has no current year coverage and not in open enrollment and purchased coverage in prior year via SEP'

  let(:product_selection) do
    Entities::ProductSelection.new({:enrollment => prior_ivl_enrollment, :product => prior_product, :family => family})
  end

  subject do
    current_product
    product_selection
    allow(family).to receive(:current_sep).and_return sep
    Operations::ProductSelectionEffects::DchbxProductSelectionEffects
  end

  it "does creates a continuous enrollment for future coverage period after purchase" do
    subject
    %i[prior_plan_year_ivl_sep fehb_market indian_alaskan_tribe_details].each do |feature|
      allow(EnrollRegistry[feature].feature).to receive(:is_enabled).and_return(true)
    end

    subject.call(product_selection)
    family.reload
    enrollments = family.hbx_enrollments.sort_by(&:effective_on)
    expect(enrollments.length).to eq 2
    renewal_enrollment = enrollments.last
    renewal_start_date = renewal_enrollment.effective_on
    expect(current_benefit_coverage_period.start_on).to eq renewal_start_date
    expect(renewal_enrollment.product_id).to eq current_product.id
  end
end

describe Operations::ProductSelectionEffects::DchbxProductSelectionEffects, "when:
- there is no current coverage
- there is no prior coverage
- there is no open enrollment
- the selection is IVL and admin sep is added for prior coverage year with renewal flag set to false
", dbclean: :after_each do

  include_context 'family has no current year coverage and not in open enrollment and purchased coverage in prior year via admin SEP'

  let(:product_selection) do
    Entities::ProductSelection.new({:enrollment => prior_ivl_enrollment, :product => prior_product, :family => family})
  end

  subject do
    current_product
    product_selection
    allow(family).to receive(:current_sep).and_return sep
    Operations::ProductSelectionEffects::DchbxProductSelectionEffects
  end

  it "does not create a continuous enrollment for future coverage period after purchase" do
    subject
    %i[prior_plan_year_ivl_sep fehb_market indian_alaskan_tribe_details].each do |feature|
      EnrollRegistry[feature].feature.stub(:is_enabled).and_return(true)
    end
    subject.call(product_selection)
    family.reload
    enrollments = family.hbx_enrollments.sort_by(&:effective_on)
    expect(enrollments.length).to eq 1
  end
end

describe Operations::ProductSelectionEffects::DchbxProductSelectionEffects, "when:
- there is current coverage
- there is no prior coverage
- there is no open enrollment
- the selection is IVL and sep is added for prior coverage year
", dbclean: :after_each do

  include_context 'family has current year coverage and not in open enrollment and purchased coverage in prior year via SEP'

  let(:product_selection) do
    Entities::ProductSelection.new({:enrollment => prior_ivl_enrollment, :product => prior_product, :family => family})
  end

  subject do
    current_product
    current_ivl_enrollment
    product_selection
    allow(family).to receive(:current_sep).and_return sep
    Operations::ProductSelectionEffects::DchbxProductSelectionEffects
  end

  it 'the current coverage gets canceled and new enrollment gets generated for current coverage year' do
    subject
    %i[prior_plan_year_ivl_sep fehb_market indian_alaskan_tribe_details].each do |feature|
      EnrollRegistry[feature].feature.stub(:is_enabled).and_return(true)
    end
    subject.call(product_selection)
    family.reload
    enrollments = family.hbx_enrollments.sort_by(&:effective_on)
    expect(enrollments.length).to eq 3
    expect(enrollments.pluck(:aasm_state)).to include('coverage_canceled')
    current_enrollment = enrollments.sort_by(&:created_at).select{|enr| enr.aasm_state == 'coverage_selected'}.last
    renewal_start_date = current_enrollment.effective_on
    expect(current_benefit_coverage_period.start_on).to eq renewal_start_date
    expect(current_enrollment.product_id).to eq current_product.id
  end
end

describe Operations::ProductSelectionEffects::DchbxProductSelectionEffects, "when:
- there is current coverage in active state
- there is prior coverage in expired state
- there is no open enrollment
- the selection is IVL and sep is added for prior coverage year
", dbclean: :after_each do

  include_context 'family has current year and prior year coverage and not in open enrollment and purchased new coverage in prior year via SEP'

  let(:product_selection) do
    Entities::ProductSelection.new({:enrollment => prior_ivl_enrollment, :product => prior_product, :family => family})
  end

  subject do
    current_product
    prior_ivl_enrollment_2
    current_ivl_enrollment
    product_selection
    allow(family).to receive(:current_sep).and_return sep
    Operations::ProductSelectionEffects::DchbxProductSelectionEffects
  end

  it 'prior coverage gets terminated and current coverage gets canceled and new enrollment gets generated for current and prior coverage year' do
    subject
    prior_ivl_enrollment.generate_hbx_signature
    %i[prior_plan_year_ivl_sep fehb_market indian_alaskan_tribe_details].each do |feature|
      EnrollRegistry[feature].feature.stub(:is_enabled).and_return(true)
    end
    subject.call(product_selection)
    family.reload
    enrollments = family.hbx_enrollments.sort_by(&:effective_on)
    expect(enrollments.length).to eq 4
    expect(enrollments.pluck(:aasm_state)).to include('coverage_terminated')
    terminated_enrollment = enrollments.select{|enr| enr.aasm_state == 'coverage_terminated'}.last
    expect(terminated_enrollment.terminated_on).to eq(prior_ivl_enrollment.effective_on - 1.day)
  end
end

describe Operations::ProductSelectionEffects::DchbxProductSelectionEffects, "when:
- there is current coverage in active state
- there is prior coverage in expired state
- there is a renewal coverage
- there is open enrollment
- the selection is IVL and sep is added for prior coverage year
", dbclean: :after_each do

  include_context 'family has prior, current and renewal year coverage and in open enrollment and purchased new coverage in prior year via SEP'

  let(:product_selection) do
    Entities::ProductSelection.new({:enrollment => prior_ivl_enrollment, :product => prior_product, :family => family})
  end

  subject do
    current_product
    prior_ivl_enrollment_2
    current_ivl_enrollment
    renewal_ivl_enrollment
    product_selection
    allow(family).to receive(:current_sep).and_return sep
    Operations::ProductSelectionEffects::DchbxProductSelectionEffects
  end

  it 'prior coverage gets terminated and current coverage gets canceled and new enrollment gets generated for renewal, current and prior coverage year' do
    sep.update_attributes(end_on: Date.new(current_coverage_year, 11, 15))
    subject
    prior_ivl_enrollment.generate_hbx_signature
    allow(TimeKeeper).to receive(:date_of_record).and_return(Date.new(current_coverage_year, 11, 15))
    %i[prior_plan_year_ivl_sep fehb_market indian_alaskan_tribe_details].each do |feature|
      EnrollRegistry[feature].feature.stub(:is_enabled).and_return(true)
    end
    subject.call(product_selection)
    family.reload
    enrollments = family.hbx_enrollments.sort_by(&:effective_on)
    expect(enrollments.length).to eq 6
    expect(enrollments.pluck(:aasm_state)).to include('auto_renewing')
    renewal_enrollment = enrollments.select{|enr| enr.aasm_state == 'auto_renewing'}.last
    renewal_start_date = renewal_enrollment.effective_on
    expect(renewal_benefit_coverage_period.start_on).to eq renewal_start_date
  end
end

RSpec.describe Operations::ProductSelectionEffects::DchbxProductSelectionEffects, type: :model do
  let(:current_year) { TimeKeeper.date_of_record.year }

  before do
    allow(TimeKeeper).to receive(:date_of_record).and_return(Date.new(current_year, 11, 1))
  end

  include_context 'family with one member and one enrollment'

  before do
    enrollment.update_attributes(effective_on: Date.new(current_year - 3))
    product_selection = Entities::ProductSelection.new({:enrollment => enrollment, :product => enrollment.product, :family => family})
    @result = subject.call(product_selection)
  end

  it 'should not create a renewal enrollment' do
    expect(family.hbx_enrollments.count).to eq(1)
  end
end

RSpec.describe Operations::ProductSelectionEffects::DchbxProductSelectionEffects, type: :model do
  before { DatabaseCleaner.clean }

  context 'Prospective' do
    let(:current_year) { TimeKeeper.date_of_record.year }

    before do
      allow(TimeKeeper).to receive(:date_of_record).and_return(Date.new(current_year, 11, 1))
    end

    include_context 'family with one member and one enrollment and one renewal enrollment'

    context 'new enrollment in existing plan year' do
      let(:rating_area) do
        ::BenefitMarkets::Locations::RatingArea.rating_area_for(address, during: start_on) || FactoryBot.create_default(:benefit_markets_locations_rating_area)
      end
      let(:service_area) do
        ::BenefitMarkets::Locations::ServiceArea.service_areas_for(address, during: start_on).first || FactoryBot.create_default(:benefit_markets_locations_service_area)
      end

      let(:address) { enrollment.consumer_role.rating_address }

      let(:start_on) { enrollment.effective_on.beginning_of_year }

      let!(:renewal_rating_area) do
        ::BenefitMarkets::Locations::RatingArea.rating_area_for(address, during: start_on.next_year) || FactoryBot.create_default(:benefit_markets_locations_rating_area, active_year: start_on.next_year.year)
      end
      let!(:renewal_service_area) do
        ::BenefitMarkets::Locations::ServiceArea.service_areas_for(address, during: start_on.next_year).first || FactoryBot.create_default(:benefit_markets_locations_service_area, active_year: start_on.next_year.year)
      end

      before do
        enrollment.update_attributes(rating_area_id: rating_area.id)
        enrollment.product.update_attributes(service_area_id: service_area.id)
        enrollment.product.renewal_product.update_attributes(service_area_id: renewal_service_area.id)
        product_selection = Entities::ProductSelection.new({:enrollment => enrollment, :product => enrollment.product, :family => family})
        @result = subject.call(product_selection)
      end

      it 'should create a renewal enrollment' do
        expect(family.hbx_enrollments.count).to eq(3)
      end

      it 'should renew enrollment with start_on of successor bcp' do
        expect(@result.success.effective_on).to eq(current_bcp.successor.start_on)
      end

      it 'should generate renewal in auto_renewing state' do
        expect(@result.success.aasm_state).to eq('auto_renewing')
      end

      it 'should cancel existing renewel enrollment' do
        successor_enrollment.reload
        expect(successor_enrollment.aasm_state).to eq('coverage_canceled')
      end
    end

    context 'new enrollment in renewal plan year' do
      before do
        enrollment.update_attributes!(effective_on: enrollment.effective_on + 1.year)
        product_selection = Entities::ProductSelection.new({:enrollment => enrollment, :product => enrollment.product, :family => family})
        @result = subject.call(product_selection)
      end

      it 'should not create renewal enrollment' do
        expect(family.hbx_enrollments.count).to eq(2)
      end

      it 'should return ok as success' do
        expect(@result.success).to eq(:ok)
      end
    end
  end

  context 'Retrospective' do
    let(:current_year) { TimeKeeper.date_of_record.year + 1 }

    before do
      allow(TimeKeeper).to receive(:date_of_record).and_return(Date.new(current_year, 1, 1))
    end

    include_context 'family with one member and one enrollment and one predecessor enrollment'

    context 'new enrollment in prior plan year' do

      before do
        predecessor_enrollment.expire_coverage!
        product_selection = Entities::ProductSelection.new({:enrollment => predecessor_enrollment, :product => predecessor_product, :family => family})
        @result = subject.call(product_selection)
      end

      it 'should create a renewal enrollment' do
        expect(family.hbx_enrollments.count).to eq(3)
      end

      it 'should renew enrollment with start_on of successor bcp' do
        expect(@result.success.effective_on).to eq(predecessor_bcp.successor.start_on)
      end

      it 'should generate renewal in coverage_selected state' do
        expect(@result.success.aasm_state).to eq('coverage_selected')
      end

      it 'should cancel existing renewel enrollment' do
        enrollment.reload
        expect(enrollment.aasm_state).to eq('coverage_canceled')
      end
    end

    context 'new enrollment in prior plan year for dependent add' do
      include_context 'family with two members and one enrollment and one predecessor enrollment'

      before do
        predecessor_enrollment.expire_coverage!
        product_selection = Entities::ProductSelection.new({:enrollment => predecessor_enrollment, :product => predecessor_product, :family => family})
        @result = subject.call(product_selection)
      end

      it 'should create a renewal enrollment with all the eligible enrollment members' do
        expect(predecessor_enrollment.hbx_enrollment_members.size).to eq 2
        expect(family.hbx_enrollments.count).to eq(3)
        expect(family.hbx_enrollments.last.hbx_enrollment_members.size).to eq 2
      end
    end

    context 'new enrollment in prior plan year for dependent drop with previous year active coverage' do
      include_context 'family with two members and one enrollment and one predecessor enrollment with one member with previous year active coverage'

      before do
        expired_enrollment.generate_hbx_signature
        predecessor_enrollment.update_attributes(enrollment_signature: expired_enrollment.enrollment_signature)
        product_selection = Entities::ProductSelection.new({:enrollment => predecessor_enrollment, :product => predecessor_product, :family => family})
        @result = subject.call(product_selection)
        expired_enrollment.reload
      end

      it 'should create a renewal enrollment with all the eligible enrollment members' do
        expect(expired_enrollment.hbx_enrollment_members.size).to eq 2
        expect(expired_enrollment.aasm_state).to eq "coverage_terminated"
        expect(predecessor_enrollment.hbx_enrollment_members.size).to eq 1
        expect(family.hbx_enrollments.count).to eq(4)
        expect(family.hbx_enrollments.to_a.last.hbx_enrollment_members.count).to eq 1
      end
    end

    context 'new enrollment in prior plan year for dependent add with previous year active coverage' do
      include_context 'family with two members and one enrollment and one predecessor enrollment with two members with previous year active coverage'

      let(:second_person) { family.family_members[1].person }
      let!(:consumer_role) { FactoryBot.create(:consumer_role, person: second_person) }
      let!(:ivl_transition) { FactoryBot.create(:individual_market_transition, person: second_person) }

      before do
        second_person.update_attributes(dob: predecessor_enrollment.effective_on - 10.years)
        expired_enrollment.generate_hbx_signature
        predecessor_enrollment.update_attributes(enrollment_signature: expired_enrollment.enrollment_signature)
        product_selection = Entities::ProductSelection.new({:enrollment => predecessor_enrollment, :product => predecessor_product, :family => family})
        @result = subject.call(product_selection)
        expired_enrollment.reload
      end

      it 'should create a renewal enrollment with all the eligible enrollment members' do
        expect(expired_enrollment.hbx_enrollment_members.size).to eq 1
        expect(expired_enrollment.aasm_state).to eq "coverage_terminated"
        expect(predecessor_enrollment.hbx_enrollment_members.size).to eq 2
        expect(family.hbx_enrollments.count).to eq(4)
        expect(family.hbx_enrollments.to_a.last.hbx_enrollment_members.count).to eq 2
      end
    end

    context 'new enrollment in prior plan year for dependent add with previous year active coverage' do
      include_context 'family with two members and one enrollment and one predecessor enrollment with carrier switch'

      before do
        product_selection = Entities::ProductSelection.new({:enrollment => predecessor_enrollment, :product => predecessor_product, :family => family})
        @result = subject.call(product_selection)
      end

      it 'should create a renewal enrollment with all the eligible enrollment members' do
        expect(family.hbx_enrollments.count).to eq(3)
        expect(family.hbx_enrollments.second.product.renewal_product.id).to eq(family.hbx_enrollments.last.product.id)
        expect(family.hbx_enrollments.first.product.renewal_product.id).not_to eq(family.hbx_enrollments.last.product.id)
      end
    end

    context 'new enrollment in prior plan year with previous year active coverage to switch plan with same carrier' do
      include_context 'family with two members and one enrollment and one predecessor enrollment with plan switch'

      before do
        product_selection = Entities::ProductSelection.new({:enrollment => predecessor_enrollment, :product => predecessor_product, :family => family})
        @result = subject.call(product_selection)
      end

      it 'should create a renewal enrollment with all the eligible enrollment members' do
        expect(family.hbx_enrollments.count).to eq(3)
        expect(family.hbx_enrollments.second.product.renewal_product.id).to eq(family.hbx_enrollments.last.product.id)
        expect(family.hbx_enrollments.second.product.renewal_product.title).to eq(family.hbx_enrollments.last.product.title)
        expect(family.hbx_enrollments.first.product.renewal_product.id).not_to eq(family.hbx_enrollments.last.product.id)
        expect(family.hbx_enrollments.first.product.renewal_product.title).not_to eq(family.hbx_enrollments.last.product.title)
      end
    end

    context 'new enrollment in prior plan year for dependent add with previous year active coverage' do
      include_context 'family with one members and one enrollment and one predecessor enrollment with carrier switch and existing coverage'

      before do
        product_selection = Entities::ProductSelection.new({:enrollment => predecessor_enrollment, :product => predecessor_product, :family => family})
        @result = subject.call(product_selection)
      end

      it 'should create a renewal enrollment with all the eligible enrollment members' do
        expect(family.hbx_enrollments.count).to eq(4)
        expect(family.hbx_enrollments.second.product.renewal_product.id).to eq(family.hbx_enrollments.last.product.id)
        expect(family.hbx_enrollments.first.product.renewal_product.id).not_to eq(family.hbx_enrollments.last.product.id)
      end
    end

    context 'new enrollment in prior plan year for dependent add for age off with previous year active coverage' do
      include_context 'family with two members and one enrollment and one predecessor enrollment with two members with previous year active coverage'

      before do
        expired_enrollment.generate_hbx_signature
        predecessor_enrollment.update_attributes(enrollment_signature: expired_enrollment.enrollment_signature)
        product_selection = Entities::ProductSelection.new({:enrollment => predecessor_enrollment, :product => predecessor_product, :family => family})
        @result = subject.call(product_selection)
        expired_enrollment.reload
      end

      it 'should create a renewal enrollment with all the eligible enrollment members excluding aged of dependent.' do
        expect(expired_enrollment.hbx_enrollment_members.size).to eq 1
        expect(expired_enrollment.aasm_state).to eq "coverage_terminated"
        expect(predecessor_enrollment.hbx_enrollment_members.size).to eq 2
        expect(family.hbx_enrollments.count).to eq(4)
        expect(family.hbx_enrollments.to_a.last.hbx_enrollment_members.count).to eq 1
      end
    end

    context 'new enrollment in prior plan year for dependent drop' do
      let!(:enr_member1) do
        FactoryBot.create(:hbx_enrollment_member,
                          hbx_enrollment: family.hbx_enrollments.first,
                          applicant_id: family.family_members[1].id)
      end
      before do
        predecessor_enrollment.expire_coverage!
        product_selection = Entities::ProductSelection.new({:enrollment => predecessor_enrollment, :product => predecessor_product, :family => family})
        @result = subject.call(product_selection)
      end

      it 'should create a renewal enrollment with all the eligible enrollment members for dependent drop' do
        expect(family.hbx_enrollments.first.hbx_enrollment_members.count).to eq(2)
        expect(predecessor_enrollment.hbx_enrollment_members.size).to eq 1
        expect(family.hbx_enrollments.count).to eq(3)
        expect(family.hbx_enrollments.last.hbx_enrollment_members.size).to eq 1
      end
    end

    context 'new enrollment in prior plan year for dependent drop' do
      let!(:enr_member1) do
        FactoryBot.create(:hbx_enrollment_member,
                          hbx_enrollment: family.hbx_enrollments.first,
                          applicant_id: family.family_members[1].id)
      end
      before do
        predecessor_enrollment.expire_coverage!
        product_selection = Entities::ProductSelection.new({:enrollment => predecessor_enrollment, :product => predecessor_product, :family => family})
        @result = subject.call(product_selection)
      end

      it 'should create a renewal enrollment with all the eligible enrollment members for dependent drop' do
        expect(family.hbx_enrollments.first.hbx_enrollment_members.count).to eq(2)
        expect(predecessor_enrollment.hbx_enrollment_members.size).to eq 1
        expect(family.hbx_enrollments.count).to eq(3)
        expect(family.hbx_enrollments.last.hbx_enrollment_members.size).to eq 1
      end
    end

    context 'new enrollment in current plan year' do
      before do
        predecessor_enrollment.update_attributes!(effective_on: predecessor_enrollment.effective_on + 1.year)
        product_selection = Entities::ProductSelection.new({:enrollment => predecessor_enrollment, :product => predecessor_product, :family => family})
        @result = subject.call(product_selection)
      end

      it 'should not create renewal enrollment' do
        expect(family.hbx_enrollments.count).to eq(2)
      end

      it 'should return ok as success' do
        expect(@result.success).to eq(:ok)
      end
    end
  end
end

describe Operations::ProductSelectionEffects::DchbxProductSelectionEffects, "when:
  - there is a current coverage for primary
  - there is a renewal coverage for primary
  - the selection is IVL for spouse for current year
  - it is SEP shopping
  ", dbclean: :after_each do
  let(:current_year) { previous_oe_year + 1 }
  let(:previous_oe_year) { TimeKeeper.date_of_record.year }
  before do
    allow(TimeKeeper).to receive(:date_of_record).and_return(Date.new(current_year, 1, 1))
  end

  include_context 'family with two members and one enrollment and one predecessor enrollment'

  let(:primary_enrollment_2022) {family.hbx_enrollments[1]}
  let(:product_id_2022) {primary_enrollment_2022.product.id}
  let(:product_selection) do
    Entities::ProductSelection.new({:enrollment => dependent_enrollment, :product => dependent_enrollment.product, :family => family})
  end

  subject do
    family.hbx_enrollments[0].update_attributes(aasm_state: :auto_renewing)
    primary_enrollment_2022.hbx_enrollment_members[1].delete
    renewal_product
    product_selection
    Operations::ProductSelectionEffects::DchbxProductSelectionEffects
  end
  let!(:dependent_person){ family.family_members[1].person}
  let!(:primary_person) do
    p = family.family_members[0].person
    p.person_relationships.where(relative_id:  dependent_person.id).first.update_attributes(kind: "spouse")
    p.save
    p
  end
  let!(:dependent_consumer_role) {FactoryBot.create(:consumer_role, person: dependent_person)}
  let!(:dependent_enrollment) do
    FactoryBot.create(:hbx_enrollment,
                      product_id: product_id_2022,
                      kind: 'individual',
                      family: family,
                      consumer_role_id: dependent_consumer_role.id,
                      effective_on: primary_enrollment_2022.effective_on)
  end

  let!(:dependent_enrollment_member) do
    FactoryBot.create(:hbx_enrollment_member,
                      coverage_start_on: dependent_enrollment.effective_on,
                      hbx_enrollment: dependent_enrollment,
                      applicant_id: family.family_members[1].id)
  end



  it "should not cancel non-signature enrollments" do
    family.hbx_enrollments.map(&:generate_hbx_signature)
    subject.call(product_selection)
    family.reload
    enrollments = family.hbx_enrollments.sort_by(&:effective_on)
    expect(enrollments.size).to eq 4
    expect(enrollments.pluck(:aasm_state)).to not_include("coverage_canceled")
  end
end

describe Operations::ProductSelectionEffects::DchbxProductSelectionEffects, "when:
  - there is a current coverage for primary
  - there is a renewal coverage for primary
  - the selection is IVL for primary for current year
  - it is SEP shopping
  ", dbclean: :after_each do
  let(:current_year) { previous_oe_year + 1 }
  let(:previous_oe_year) { TimeKeeper.date_of_record.year }
  before do
    allow(TimeKeeper).to receive(:date_of_record).and_return(Date.new(current_year, 1, 1))
  end

  include_context 'family with two members and one enrollment and one predecessor enrollment'

  let(:primary_enrollment_2022) {family.hbx_enrollments[1]}
  let(:product_id_2022) {primary_enrollment_2022.product.id}
  let(:product_selection) do
    Entities::ProductSelection.new({:enrollment => primary_enrollment, :product => primary_enrollment.product, :family => family})
  end

  subject do
    family.hbx_enrollments[0].update_attributes(aasm_state: :auto_renewing)
    primary_enrollment_2022.hbx_enrollment_members[1].delete
    renewal_product
    product_selection
    Operations::ProductSelectionEffects::DchbxProductSelectionEffects
  end
  let!(:dependent_person){ family.family_members[1].person}
  let!(:primary_person) do
    p = family.family_members[0].person
    p.person_relationships.where(relative_id:  dependent_person.id).first.update_attributes(kind: "spouse")
    p.save
    p
  end
  let!(:dependent_consumer_role) {FactoryBot.create(:consumer_role, person: dependent_person)}
  let!(:primary_enrollment) do
    FactoryBot.create(:hbx_enrollment,
                      product_id: product_id_2022,
                      kind: 'individual',
                      family: family,
                      consumer_role_id: primary_person.consumer_role.id,
                      effective_on: primary_enrollment_2022.effective_on)
  end

  let!(:primary_enrollment_member) do
    FactoryBot.create(:hbx_enrollment_member,
                      coverage_start_on: primary_enrollment.effective_on,
                      hbx_enrollment: primary_enrollment,
                      applicant_id: family.family_members[0].id)
  end



  it "should cancel signature enrollments" do
    family.hbx_enrollments.map(&:generate_hbx_signature)
    family.hbx_enrollments.map(&:save)
    subject.call(product_selection)
    family.reload
    enrollments = family.hbx_enrollments
    expect(enrollments.size).to eq 4
    expect(enrollments.where(:aasm_state.nin => ["coverage_canceled", "coverage_terminated"]).count).to eq(2)
  end
end


describe Operations::ProductSelectionEffects::DchbxProductSelectionEffects, "when:
  - there is a current year coverage for primary
  - there is a terminated renewal current year coverage for primary
  - all these enrollments have different plans
  - it is SEP shopping for prior year
  ", dbclean: :after_each do

  let(:previous_oe_year) { current_year - 1 }
  let(:current_year) { TimeKeeper.date_of_record.year }
  before do
    allow(TimeKeeper).to receive(:date_of_record).and_return(Date.new(current_year, 1, 20))
  end

  include_context 'family with two members and one enrollment and one predecessor enrollment'

  let!(:dependent_person){ family.family_members[1].person}
  let!(:primary_person) do
    p = family.family_members[0].person
    p.person_relationships.where(relative_id:  dependent_person.id).first.update_attributes(kind: "spouse")
    p.save
    p
  end

  let(:prior_year_product) do
    product = BenefitMarkets::Products::Product.all.by_year(2023).first
    product.update_attributes(hios_id: "41842DC0400026-01", hios_base_id: "41842DC0400026", csr_variant_id: "01")
    product
  end

  let(:renewal_year_product) do
    product = prior_year_product.renewal_product
    product.update_attributes(hios_id: "41842DC0400026-01", hios_base_id: "41842DC0400026", csr_variant_id: "01")
    product
  end

  let(:product_2024_1) {BenefitMarkets::Products::Product.all.by_year(2024).where(:hios_id.nin => [prior_year_product.hios_id])[0]}
  let(:product_2024_2) {BenefitMarkets::Products::Product.all.by_year(2024).where(:hios_id.nin => [prior_year_product.hios_id])[1]}

  let!(:current_enrollment_2_1) do
    FactoryBot.create(:hbx_enrollment,
                      product_id: product_2024_1.id,
                      kind: 'individual',
                      family: family,
                      consumer_role_id: primary_person.consumer_role.id,
                      effective_on: Date.new(current_year, 2,1))
  end

  let!(:current_enrollment_member_2_1) do
    FactoryBot.create(:hbx_enrollment_member,
                      coverage_start_on: current_enrollment_2_1.effective_on,
                      hbx_enrollment: current_enrollment_2_1,
                      applicant_id: family.family_members[0].id)
  end

  let!(:delete_enrollment){family.hbx_enrollments.by_year(2023).delete_all}

  let!(:terminated_enrollment_current_year) do
    enrollment = family.hbx_enrollments.by_year(2024)[0]
    enrollment.update_attributes(aasm_state: "coverage_terminated", terminated_on: Date.new(current_year,1,31))
    enrollment.product = product_2024_2
    enrollment.save!
    enrollment
  end

  let!(:active_enrollment_current_year) {family.hbx_enrollments.by_year(2024)[1]}
  let!(:product_selection) do
    Entities::ProductSelection.new({:enrollment => primary_enrollment, :product => primary_enrollment.product, :family => family})
  end

  let!(:dependent_consumer_role) {FactoryBot.create(:consumer_role, person: dependent_person)}
  let!(:primary_enrollment) do
    FactoryBot.create(:hbx_enrollment,
                      product_id: prior_year_product.id,
                      kind: 'individual',
                      family: family,
                      consumer_role_id: primary_person.consumer_role.id,
                      effective_on: Date.new(previous_oe_year, 11,1))
  end

  let!(:primary_enrollment_member) do
    FactoryBot.create(:hbx_enrollment_member,
                      coverage_start_on: primary_enrollment.effective_on,
                      hbx_enrollment: primary_enrollment,
                      applicant_id: family.family_members[0].id)
  end

  subject do
    family.reload
    renewal_year_product
    product_selection
    Operations::ProductSelectionEffects::DchbxProductSelectionEffects
  end

  it "should cancel signature enrollments" do
    family.hbx_enrollments.map(&:generate_hbx_signature)
    family.hbx_enrollments.map(&:save)
    subject.call(product_selection)
    family.reload
    enrollments = family.hbx_enrollments
    expect(enrollments.size).to eq 4
    expect(enrollments.by_year(current_year).where(:aasm_state.in => ["coverage_canceled", "coverage_selected"]).count).to eq(3)
  end
end


describe Operations::ProductSelectionEffects::DchbxProductSelectionEffects, "when:
  - there is a current year coverage for primary
  - there is a terminated renewal current year coverage for primary
  - all these enrollments have same plans
  - it is SEP shopping for prior year
  ", dbclean: :after_each do

  let(:previous_oe_year) { current_year - 1 }
  let(:current_year) { TimeKeeper.date_of_record.year }
  before do
    allow(TimeKeeper).to receive(:date_of_record).and_return(Date.new(current_year, 1, 20))
  end

  include_context 'family with two members and one enrollment and one predecessor enrollment'

  let!(:dependent_person){ family.family_members[1].person}
  let!(:primary_person) do
    p = family.family_members[0].person
    p.person_relationships.where(relative_id:  dependent_person.id).first.update_attributes(kind: "spouse")
    p.save
    p
  end

  let!(:prior_year_product) do
    product = BenefitMarkets::Products::Product.all.by_year(2023).first
    product.update_attributes(hios_id: "41842DC0400026-01", hios_base_id: "41842DC0400026", csr_variant_id: "01")
    product
  end

  let!(:renewal_year_product) do
    product = prior_year_product.renewal_product
    product.update_attributes(hios_id: "41842DC0400026-01", hios_base_id: "41842DC0400026", csr_variant_id: "01")
    product
  end

  let!(:product_2024_1) {BenefitMarkets::Products::Product.all.by_year(2024).where(:hios_id.in => [prior_year_product.hios_id])[0]}
  let!(:current_enrollment_2_1) do
    FactoryBot.create(:hbx_enrollment,
                      product_id: product_2024_1.id,
                      kind: 'individual',
                      family: family,
                      consumer_role_id: primary_person.consumer_role.id,
                      effective_on: Date.new(current_year, 2,1))
  end

  let!(:current_enrollment_member_2_1) do
    FactoryBot.create(:hbx_enrollment_member,
                      coverage_start_on: current_enrollment_2_1.effective_on,
                      hbx_enrollment: current_enrollment_2_1,
                      applicant_id: family.family_members[0].id)
  end

  let!(:delete_enrollment){family.hbx_enrollments.by_year(2023).delete_all}

  let!(:terminated_enrollment_current_year) do
    enrollment = family.hbx_enrollments.by_year(2024)[0]
    enrollment.update_attributes(aasm_state: "coverage_terminated", terminated_on: Date.new(current_year,1,31))
    enrollment.product = product_2024_1
    enrollment.save!
    enrollment
  end

  let!(:active_enrollment_current_year) {family.hbx_enrollments.by_year(2024)[1]}
  let!(:product_selection) do
    Entities::ProductSelection.new({:enrollment => primary_enrollment, :product => primary_enrollment.product, :family => family})
  end

  let!(:dependent_consumer_role) {FactoryBot.create(:consumer_role, person: dependent_person)}
  let!(:primary_enrollment) do
    FactoryBot.create(:hbx_enrollment,
                      product_id: prior_year_product.id,
                      kind: 'individual',
                      family: family,
                      consumer_role_id: primary_person.consumer_role.id,
                      effective_on: Date.new(previous_oe_year, 11,1))
  end

  let!(:primary_enrollment_member) do
    FactoryBot.create(:hbx_enrollment_member,
                      coverage_start_on: primary_enrollment.effective_on,
                      hbx_enrollment: primary_enrollment,
                      applicant_id: family.family_members[0].id)
  end

  subject do
    family.reload
    renewal_year_product
    product_selection
    Operations::ProductSelectionEffects::DchbxProductSelectionEffects
  end

  it "should cancel signature enrollments" do
    family.hbx_enrollments.map(&:generate_hbx_signature)
    family.hbx_enrollments.map(&:save)
    subject.call(product_selection)
    family.reload
    enrollments = family.hbx_enrollments
    expect(enrollments.size).to eq 4
    expect(enrollments.by_year(current_year).where(:aasm_state.in => ["coverage_canceled", "coverage_selected"]).count).to eq(3)
  end
end