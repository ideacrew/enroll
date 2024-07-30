# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'
require 'rails_helper'
require 'rspec-benchmark'

RSpec.configure do |config|
  config.include RSpec::Benchmark::Matchers
end


RSpec.describe ::Operations::Transformers::FamilyTo::Cv3Family, dbclean: :around_each do
  let(:primary_applicant) { FactoryBot.create(:person, :with_consumer_role, hbx_id: "732020") }
  let(:dependent1) { FactoryBot.create(:person, hbx_id: "732021") }
  let(:dependent2) { FactoryBot.create(:person, hbx_id: "732022") }
  let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: primary_applicant) }
  let(:family_member2) { FactoryBot.create(:family_member, family: family, person: dependent1) }
  let(:family_member3) { FactoryBot.create(:family_member, family: family, person: dependent2) }
  let!(:application) { FactoryBot.create(:financial_assistance_application, family_id: family.id, aasm_state: 'determined', hbx_id: "830293", effective_date: TimeKeeper.date_of_record.beginning_of_year) }
  let!(:applicant1) do
    FactoryBot.create(:financial_assistance_applicant, :male, dob: TimeKeeper.date_of_record - 30.years, application: application, family_member_id: primary_applicant.id, is_primary_applicant: true, person_hbx_id: primary_applicant.hbx_id)
  end
  let!(:applicant2) { FactoryBot.create(:financial_assistance_applicant, :male, dob: TimeKeeper.date_of_record - 30.years, application: application, family_member_id: family_member2.id, person_hbx_id: dependent1.hbx_id) }
  let!(:applicant3) { FactoryBot.create(:financial_assistance_applicant, :female, dob: TimeKeeper.date_of_record - 30.years, application: application, family_member_id: family_member3.id, person_hbx_id: dependent2.hbx_id) }
  let(:create_instate_addresses) do
    application.applicants.each do |appl|
      appl.addresses = [FactoryBot.build(:financial_assistance_address,
                                         :address_1 => '1111 Awesome Street NE',
                                         :address_2 => '#111',
                                         :address_3 => '',
                                         :city => 'Washington',
                                         :country_name => '',
                                         :kind => 'home',
                                         :state => FinancialAssistanceRegistry[:enroll_app].setting(:state_abbreviation).item,
                                         :zip => '20001',
                                         county: '')]
      appl.save!
    end
    application.save!
  end
  let(:create_relationships) do
    application.applicants.first.update_attributes!(is_primary_applicant: true) unless application.primary_applicant.present?
    application.ensure_relationship_with_primary(applicant2, 'child')
    application.ensure_relationship_with_primary(applicant3, 'child')
    application.build_relationship_matrix
    application.save!
  end
  let(:benefit_sponsorship) { FactoryBot.build(:benefit_sponsorship) }
  let!(:hbx_profile) { FactoryBot.create :hbx_profile, benefit_sponsorship: benefit_sponsorship}

  context 'cv3 family generation' do
    let!(:applications) { FactoryBot.create_list(:financial_assistance_application, 20, :with_applicants, family_id: family.id, aasm_state: 'determined', effective_date: TimeKeeper.date_of_record.beginning_of_year) }
    let(:family) do
      family = FactoryBot.build(:family, person: primary)
      family.family_members = [
        FactoryBot.build(:family_member, is_primary_applicant: true, is_active: true, family: family, person: primary),
        FactoryBot.build(:family_member, is_primary_applicant: false, is_active: true, family: family, person: dependent)
      ]

      family.person.person_relationships.push PersonRelationship.new(relative_id: dependent.id, kind: 'spouse')
      family.save
      family
    end

    let(:dependent) { FactoryBot.create(:person) }
    let(:primary) { FactoryBot.create(:person) }
    let(:primary_applicant) { family.primary_applicant }
    let(:dependents) { family.dependents }
    let!(:eligibility_determination) do
      determination = family.create_eligibility_determination(effective_date: TimeKeeper.date_of_record.beginning_of_year)
      determination
    end

    let!(:primary_grant) do
      eligibility_determination.grants.create(
        key: "AdvancePremiumAdjustmentGrant",
        value: 110,
        start_on: TimeKeeper.date_of_record.beginning_of_year,
        end_on: TimeKeeper.date_of_record.end_of_year,
        assistance_year: TimeKeeper.date_of_record.year,
        member_ids: [primary_applicant.id.to_s],
        tax_household_id: primary_tax_household.id
      )
    end

    let!(:dependents_grant) do
      eligibility_determination.grants.create(
        key: "AdvancePremiumAdjustmentGrant",
        value: 120,
        start_on: TimeKeeper.date_of_record.beginning_of_year,
        end_on: TimeKeeper.date_of_record.end_of_year,
        assistance_year: TimeKeeper.date_of_record.year,
        member_ids: dependents.map(&:id).map(&:to_s),
        tax_household_id: dependents_tax_household.id
      )
    end

    let!(:tax_household_group) do
      family.tax_household_groups.create!(
        assistance_year: TimeKeeper.date_of_record.year,
        source: 'Admin',
        start_on: TimeKeeper.date_of_record.beginning_of_year,
        tax_households: [
          FactoryBot.build(:tax_household, household: family.active_household),
          FactoryBot.build(:tax_household, household: family.active_household)
        ]
      )
    end

    let(:primary_tax_household) do
      tax_household_group.tax_households.first
    end

    let(:dependents_tax_household) do
      tax_household_group.tax_households.second
    end

    let!(:hbx_enrollments) do
      FactoryBot.create_list(:hbx_enrollment, 20,
                             :individual_shopping,
                             :with_silver_health_product,
                             :with_enrollment_members,
                             enrollment_members: family.family_members,
                             effective_on: TimeKeeper.date_of_record.beginning_of_month,
                             aasm_state: 'coverage_canceled',
                             product_id: products.first.id,
                             family: family)
    end

    let!(:seps) { FactoryBot.create_list(:special_enrollment_period, 10, family: family)}
    let!(:payment_transactions) { FactoryBot.create_list(:payment_transaction, 5, family: family)}
    let!(:products) do
      products = FactoryBot.create_list(:benefit_markets_products_health_products_health_product, 20, :silver)
      rating_area = ::BenefitMarkets::Locations::RatingArea.rating_area_for(primary.rating_address, during: TimeKeeper.date_of_record.beginning_of_year)
      products.each do |product|
        product.premium_tables.each do |pt|
          pt.update_attributes(rating_area_id: rating_area.id)
        end
      end
    end

    it 'performs under 4 seconds' do
      ::BenefitMarkets::Products::ProductRateCache.initialize_rate_cache!

      expect do
        ::Operations::Transformers::FamilyTo::Cv3Family.new.call(family)
      end.to perform_under(4).sec
    end
  end

  context 'nested cv3 transform failures' do

    subject { Operations::Transformers::FamilyTo::Cv3Family.new.call(family) }

    context 'when cv3 Person transform fails' do
      before do
        allow(Operations::Transformers::PersonTo::Cv3Person).to receive_message_chain('new.call').with(primary_applicant).and_return(Dry::Monads::Result::Failure.new(primary_applicant))
      end

      it "should return a failure if cv3 person transform returns failure" do
        expect(subject).to be_a(Dry::Monads::Result::Failure)
      end
    end

    context 'when cv3 Application transform fails' do
      before do
        allow(::FinancialAssistance::Operations::Applications::Transformers::ApplicationTo::Cv3Application).to receive_message_chain('new.call').with(application).and_return(Dry::Monads::Result::Failure.new(application))
      end

      it "should return a failure if cv3 Application transform returns failure" do
        expect(subject).to be_a(Dry::Monads::Result::Failure)
      end
    end

    context 'when cv3 hbx enrollment transform fails' do
      let!(:enrollment) do
        create(
          :hbx_enrollment,
          :with_product,
          family: family
        )
      end

      before do
        enrollment.update(product_id: enrollment.product.id)
        allow(::FinancialAssistance::Operations::Applications::Transformers::ApplicationTo::Cv3Application).to receive_message_chain('new.call').with(application).and_return(Dry::Monads::Result::Success.new(application))
        allow(Operations::Transformers::HbxEnrollmentTo::Cv3HbxEnrollment).to receive_message_chain('new.call').with(enrollment, {}).and_return(Dry::Monads::Result::Failure.new(enrollment))
      end

      it "should return a failure if cv3 HbxEnrollment transform returns failure" do
        expect(subject).to be_a(Dry::Monads::Result::Failure)
      end
    end

    context 'when cv3 Tax Household Enrollment transform fails' do
      let!(:enrollment) do
        create(
          :hbx_enrollment,
          :with_product,
          family: family
        )
      end

      let!(:tax_household_enrollment) do
        create(:tax_household_enrollment, enrollment_id: enrollment.id)
      end

      before do
        allow(::FinancialAssistance::Operations::Applications::Transformers::ApplicationTo::Cv3Application).to receive_message_chain('new.call').with(application).and_return(Dry::Monads::Result::Success.new(application))
        allow(Operations::Transformers::TaxHouseholdEnrollmentTo::Cv3TaxHouseholdEnrollment).to receive_message_chain('new.call').with(tax_household_enrollment).and_return(Dry::Monads::Result::Failure.new(tax_household_enrollment))
      end

      it "should return a failure if cv3 Tax Household Enrollment transform returns failure" do
        expect(subject).to be_a(Dry::Monads::Result::Failure)
      end
    end
  end

  describe '#transform_applications' do

    subject { Operations::Transformers::FamilyTo::Cv3Family.new.transform_applications(family, false) }

    context "when application is invalid" do
      before do
        create_instate_addresses
        create_relationships
        application.save!
        allow(::FinancialAssistance::Operations::Applications::Transformers::ApplicationTo::Cv3Application).to receive_message_chain('new.call').with(application).and_return(Dry::Monads::Result::Failure.new(application))
      end

      it "should return a failure if cv3 application returns failure" do
        expect(subject).to be_a(Dry::Monads::Result::Failure)
      end
    end

    context "when applications are excluded" do
      before do
        create_instate_addresses
        create_relationships
        application.save!
        allow(::FinancialAssistance::Operations::Applications::Transformers::ApplicationTo::Cv3Application).to receive_message_chain('new.call').with(application).and_return(Dry::Monads::Result::Failure.new(application))
      end

      it "should return an empty array wrapped in Success when exclue applications true" do
        result = Operations::Transformers::FamilyTo::Cv3Family.new.transform_applications(family, true)
        expect(result).to be_a(Dry::Monads::Result::Success)
        expect(result.value!).to be_empty
      end

      it "should still be a valid cv3 family when exclude applications true" do
        result = Operations::Transformers::FamilyTo::Cv3Family.new.call(family, true)
        contract_result = ::AcaEntities::Contracts::Families::FamilyContract.new.call(result.value!)
        expect(contract_result.success?).to eq true
      end
    end

    context "when all applicants are valid" do
      before do
        create_instate_addresses
        create_relationships
        application.save!
        allow(::FinancialAssistance::Operations::Applications::Transformers::ApplicationTo::Cv3Application).to receive_message_chain('new.call').with(application).and_return(::Dry::Monads::Result::Success.new(application))
      end

      it "should successfully submit a cv3 application and get a response back" do
        expect(subject.value!).to include(application)
      end
    end
  end

  describe '#transform_households' do
    let(:aasm_state) { 'coverage_selected' }
    let!(:shopping_enrollment) do
      create(
        :hbx_enrollment,
        :with_enrollment_members,
        :individual_unassisted,
        family: family,
        aasm_state: aasm_state,
        product_id: product.id,
        applied_aptc_amount: Money.new(44_500),
        consumer_role_id: primary_applicant.consumer_role.id,
        enrollment_members: family.family_members
      )
    end
    let(:product) { create(:benefit_markets_products_health_products_health_product, :ivl_product, issuer_profile: issuer) }
    let(:issuer) { create(:benefit_sponsors_organizations_issuer_profile, abbrev: 'ANTHM') }

    subject { Operations::Transformers::FamilyTo::Cv3Family.new.transform_households(family.households, {exclude_seps: false}) }

    context 'when enrollment is in shopping state' do
      let(:aasm_state) { 'shopping' }
      it 'should not include hbx_enrollments in the hash' do
        expect(subject.value![0][:hbx_enrollments]).to be_nil
      end
    end

    context 'when enrollment is coverage_selected state' do
      let(:aasm_state) { 'coverage_selected' }
      it 'should include hbx_enrollments in the household hash' do
        expect(subject.value![0][:hbx_enrollments]).to be_present
      end
    end
  end

  describe '#transform_hbx_enrollments' do
    let(:aasm_state) { 'coverage_selected' }
    let!(:coverage_selected_enrollment) do
      create(
        :hbx_enrollment,
        :with_enrollment_members,
        :individual_unassisted,
        family: family,
        aasm_state: aasm_state,
        product_id: product.id,
        applied_aptc_amount: Money.new(44_500),
        consumer_role_id: primary_applicant.consumer_role.id,
        enrollment_members: family.family_members,
        enrollment_kind: "special_enrollment",
        submitted_at: submitted_at
      )
    end

    let(:submitted_at) { TimeKeeper.date_of_record }
    let(:start_on) { submitted_at.prev_day }
    let(:special_enrollment_period) do
      build(
        :special_enrollment_period,
        family: family,
        qualifying_life_event_kind_id: qle.id,
        market_kind: "ivl",
        start_on: start_on,
        end_on: start_on,
        created_at: submitted_at,
        updated_at: submitted_at
      )
    end

    let!(:add_special_enrollment_period) do
      family.special_enrollment_periods = [special_enrollment_period]
      family.save
    end
    let!(:qle)  { FactoryBot.create(:qualifying_life_event_kind, market_kind: "individual") }

    let(:product) { create(:benefit_markets_products_health_products_health_product, :ivl_product, issuer_profile: issuer) }
    let(:issuer) { create(:benefit_sponsors_organizations_issuer_profile, abbrev: 'ANTHM') }
    let(:enrollments) do
      # this matches the current selection logic in the CV3 Family transformer
      family.households.first.hbx_enrollments.where(:aasm_state.ne => "shopping", :product_id.ne => nil)
    end

    context 'when enrollment is outside of sep periods and exclude_seps is true' do
      let(:aasm_state) { 'coverage_selected' }

      subject do
        Operations::Transformers::FamilyTo::Cv3Family.new.transform_hbx_enrollments(enrollments, {exclude_seps: true})
      end

      it 'should not return special_enrollment_period_reference' do
        expect(subject.value![0][:special_enrollment_period_reference]).to be_nil
      end
    end

    context "when enrollment fails transform" do
      before do
        allow(Operations::Transformers::HbxEnrollmentTo::Cv3HbxEnrollment).to receive_message_chain('new.call').with(coverage_selected_enrollment, {}).and_return(Dry::Monads::Result::Failure.new("failed to transform enrollment"))
      end

      subject do
        Operations::Transformers::FamilyTo::Cv3Family.new.transform_hbx_enrollments(enrollments, {})
      end

      it "should return a failure if cv3 hbx enrollment returns failure" do
        expect(subject).to be_a(Dry::Monads::Result::Failure)
      end
    end
  end

  describe '#transform_tax_household_groups' do
    let!(:tax_household_group) do
      family.tax_household_groups.create!(
        assistance_year: TimeKeeper.date_of_record.year,
        source: 'Admin',
        start_on: TimeKeeper.date_of_record.beginning_of_year
      )
    end

    let!(:tax_household) do
      tax_household_group.tax_households.create!(
        effective_starting_on: TimeKeeper.date_of_record.beginning_of_year,
        yearly_expected_contribution: 100.00,
        max_aptc: 50.00
      )
    end

    let!(:tax_household_member) do
      tax_household.tax_household_members.create!(
        applicant_id: family.primary_applicant.id,
        is_ia_eligible: true,
        is_medicaid_chip_eligible: true,
        is_subscriber: true,
        magi_medicaid_monthly_household_income: 50_000
      )
    end

    before do
      family.person.person_relationships << [
        PersonRelationship.new(relative_id: primary_applicant.id, kind: 'self'),
        PersonRelationship.new(relative_id: dependent1.id, kind: 'child'),
        PersonRelationship.new(relative_id: dependent2.id, kind: 'child')
      ]
      family.save!
    end

    subject { Operations::Transformers::FamilyTo::Cv3Family.new.transform_tax_household_groups([tax_household_group]) }

    it 'should include hbx_enrollments in the hash' do
      contract_result = AcaEntities::Contracts::Households::TaxHouseholdGroupContract.new.call(subject.first)
      result = AcaEntities::Households::TaxHouseholdGroup.new(contract_result.to_h)
      expect(result).to be_a AcaEntities::Households::TaxHouseholdGroup
    end

    context 'member has csr kind value of csr_limited' do
      before do
        member = family.tax_household_groups.first.tax_households.first.tax_household_members.first
        member.update(csr_percent_as_integer: -1)
      end

      it 'should remove csr prefix in the hash' do
        expect(family.tax_household_groups.first.tax_households.first.tax_household_members.first.csr_eligibility_kind).to eq 'csr_limited'
        expect(subject.first[:tax_households].first[:tax_household_members].first[:product_eligibility_determination][:csr]).to eq 'limited'
      end

      it 'should validate the contract successfully' do
        expect(AcaEntities::Contracts::Households::TaxHouseholdGroupContract.new.call(subject.first).success?).to be_truthy
      end
    end
  end

  describe '#fetch_slcsp_benchmark_premium_for_member' do
    let(:slcsp_info) do
      {
        "732020" => {:health_only_slcsp_premiums => {:cost => 986.26, :product_id => BSON::ObjectId('615640c688753f0b86eba985'), :member_identifier => "732021", :monthly_premium => 986.26}},
        "732021" => {:health_only_slcsp_premiums => {:cost => 986.26, :product_id => BSON::ObjectId('615640c688753f0b86eba985'), :member_identifier => "732021", :monthly_premium => 986.26}},
        "732022" => {:health_only_slcsp_premiums => {:cost => 986.26, :product_id => BSON::ObjectId('615640c688753f0b86eba985'), :member_identifier => "732022", :monthly_premium => 986.26}}
      }
    end

    let(:cv3_family) { Operations::Transformers::FamilyTo::Cv3Family.new }

    it 'should return slcsp_info for each family_member' do
      family.family_members.each do |member|
        person_hbx_id = member.person.hbx_id
        member_slcsp_info = cv3_family.fetch_slcsp_benchmark_premium_for_member(person_hbx_id, slcsp_info)
        expect(member_slcsp_info).to eq slcsp_info.dig(person_hbx_id, :health_only_slcsp_premiums, :cost)&.to_money&.to_hash
      end
    end
  end

  context 'tax household member is missing matching family member' do
    let(:family_member_id) { family.family_members.first.id.to_s }
    let(:silver_product_premiums) do
      {
        family_member_id => [
          { :cost => 200.0, :product_id => BSON::ObjectId.new },
          { :cost => 300.0, :product_id => BSON::ObjectId.new },
          { :cost => 400.0, :product_id => BSON::ObjectId.new }
        ]
      }
    end
    let!(:list_products) { FactoryBot.create_list(:benefit_markets_products_health_products_health_product, 5, :silver) }
    let(:products) { ::BenefitMarkets::Products::Product.all }
    let(:products_payload) do
      {
        rating_area_id: BSON::ObjectId.new,
        products: products
      }
    end
    let(:effective_on) { TimeKeeper.date_of_record.next_month.beginning_of_month }
    let!(:tax_household) {FactoryBot.create(:tax_household, household: family.active_household, effective_ending_on: nil, effective_starting_on: effective_on)}
    let!(:tax_household_member1) {FactoryBot.create(:tax_household_member, applicant_id: family.family_members.first.id, tax_household: tax_household)}
    let!(:tax_household_member2) {FactoryBot.create(:tax_household_member, tax_household: tax_household)}

    before do
      allow(::FinancialAssistance::Operations::Applications::Transformers::ApplicationTo::Cv3Application).to receive_message_chain('new.call').with(application).and_return(::Dry::Monads::Result::Success.new(application))
      allow(Operations::Products::FetchSilverProducts).to receive(:new).and_return double(call: ::Dry::Monads::Result::Success.new(products_payload))
      allow(Operations::Products::FetchSilverProductPremiums).to receive(:new).and_return double(call: ::Dry::Monads::Result::Success.new(silver_product_premiums))
      allow(Operations::Products::FetchSlcsp).to receive(:new).and_return double(call: ::Dry::Monads::Result::Success.new({}))
    end

    it 'should not include the tax household member with the missing family member' do
      result = subject.call(family).value!
      tax_household_members = result[:households].first[:tax_households].first[:tax_household_members]
      expect(tax_household_members.count).to eq(1)
    end
  end

  context 'include family eligibility determination' do
    before do
      Operations::Eligibilities::BuildFamilyDetermination.new.call({effective_date: Date.today, family: family})
      result = subject.call(family, true).value!
      @eligibility_determination = result[:eligibility_determination]
    end

    it 'should have eligibility determination in the cv3 family' do
      expect(@eligibility_determination).to be_present
      expect(@eligibility_determination[:effective_date]).to eq Date.today
    end

    it 'determination should have subjects' do
      expect(@eligibility_determination[:subjects].count).to eq 3
    end

    it 'subject should have eligibility states' do
      expect(@eligibility_determination[:subjects].first.last[:eligibility_states]).to be_present
    end

    it 'eligibility states should have evidence states' do
      ivl_evidence_state = @eligibility_determination[:subjects].first.last[:eligibility_states][:aca_individual_market_eligibility][:evidence_states]
      expect(ivl_evidence_state).to be_present
      expect(ivl_evidence_state[:citizenship][:evidence_item_key]).to eq :citizenship
    end
  end
end
