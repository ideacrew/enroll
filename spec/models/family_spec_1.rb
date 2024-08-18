# frozen_string_literal: true

require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"
require "#{Rails.root}/spec/shared_contexts/enrollment.rb"

describe ".current_enrolled_or_termed_products_by_subscriber", dbclean: :after_each do
  let!(:person) { FactoryBot.create(:person)}
  let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person)}
  let!(:household) { FactoryBot.create(:household, family: family) }
  let!(:product) {FactoryBot.create(:benefit_markets_products_health_products_health_product, benefit_market_kind: :aca_individual, kind: :health, csr_variant_id: '01')}
  let!(:effective_on) { TimeKeeper.date_of_record.beginning_of_month}
  let!(:subscriber_enrollment_member) { FactoryBot.build(:hbx_enrollment_member, applicant_id: family.primary_applicant.id) }

  let!(:active_enrollment) do
    FactoryBot.create(:hbx_enrollment,
                      family: family,
                      household: family.active_household,
                      coverage_kind: "health",
                      product: product,
                      aasm_state: 'coverage_selected',
                      hbx_enrollment_members: [subscriber_enrollment_member])
  end

  let!(:shopping_enrollment) do
    FactoryBot.create(:hbx_enrollment,
                      family: family,
                      effective_on: effective_on,
                      household: family.active_household,
                      coverage_kind: "health",
                      aasm_state: 'shopping',
                      hbx_enrollment_members: [subscriber_enrollment_member])
  end

  context "when consumer has active enrollment" do
    it "should return current active enrolled product" do
      expect(family.current_enrolled_or_termed_products_by_subscriber(shopping_enrollment)).to eq [active_enrollment.product]
    end
  end

  context "when consumer has contionus coverage" do

    let!(:term_enrollment) do
      FactoryBot.create(:hbx_enrollment,
                        family: family,
                        household: family.active_household,
                        coverage_kind: "health",
                        product: product,
                        terminated_on: effective_on - 1.day,
                        aasm_state: 'coverage_terminated',
                        hbx_enrollment_members: [subscriber_enrollment_member])
    end

    before do
      active_enrollment.cancel_coverage!
    end

    it "should return contionus coverage product" do
      expect(family.current_enrolled_or_termed_products_by_subscriber(shopping_enrollment)).to eq [term_enrollment.product]
    end
  end

  context "when consumer no contionus coverage" do

    let!(:term_enrollment) do
      FactoryBot.create(:hbx_enrollment,
                        family: family,
                        household: family.active_household,
                        coverage_kind: "health",
                        product: product,
                        terminated_on: effective_on - 2.day,
                        aasm_state: 'coverage_terminated',
                        hbx_enrollment_members: [subscriber_enrollment_member])
    end

    before do
      active_enrollment.cancel_coverage!
    end

    it "should return []" do
      expect(family.current_enrolled_or_termed_products_by_subscriber(shopping_enrollment)).to eq []
    end
  end
end

describe ".current_enrolled_or_termed_products", dbclean: :after_each do
  let!(:effective_on) { TimeKeeper.date_of_record.beginning_of_month}

  let!(:person) { FactoryBot.create(:person)}
  let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person)}
  let!(:household) { FactoryBot.create(:household, family: family) }
  let!(:product) {FactoryBot.create(:benefit_markets_products_health_products_health_product, benefit_market_kind: :aca_individual, kind: :health, csr_variant_id: '01')}
  let!(:subscriber_enrollment_member) { FactoryBot.build(:hbx_enrollment_member, applicant_id: family.primary_applicant.id) }

  let!(:person2) { FactoryBot.create(:person)}
  let!(:dependent_family_member) { FactoryBot.create(:family_member, family: family, person: person2) }
  let!(:dependent_enrollment_member) { FactoryBot.build(:hbx_enrollment_member, applicant_id: dependent_family_member.id) }

  let!(:active_enrollment) do
    FactoryBot.create(:hbx_enrollment,
                      family: family,
                      household: family.active_household,
                      coverage_kind: "health",
                      product: product,
                      aasm_state: 'coverage_selected',
                      hbx_enrollment_members: [subscriber_enrollment_member, dependent_enrollment_member])
  end

  let!(:shopping_enrollment) do
    FactoryBot.create(:hbx_enrollment,
                      family: family,
                      effective_on: effective_on,
                      household: family.active_household,
                      coverage_kind: "health",
                      aasm_state: 'shopping',
                      hbx_enrollment_members: [dependent_enrollment_member])
  end

  context "when dependent has active enrollment" do

    it "should return current active enrolled product for dependent" do
      expect(family.current_enrolled_or_termed_products(shopping_enrollment)).to eq [active_enrollment.product]
    end
  end

  context "when dependent has contionus coverage" do

    let!(:term_enrollment) do
      FactoryBot.create(:hbx_enrollment,
                        family: family,
                        household: family.active_household,
                        coverage_kind: "health",
                        product: product,
                        terminated_on: effective_on - 1.day,
                        aasm_state: 'coverage_terminated',
                        hbx_enrollment_members: [subscriber_enrollment_member, dependent_enrollment_member])
    end

    before do
      active_enrollment.cancel_coverage!
    end

    it "should return contionus coverage product" do
      expect(family.current_enrolled_or_termed_products(shopping_enrollment)).to eq [term_enrollment.product]
    end
  end

  context "when dependent or consumer has no contionus coverage" do

    let!(:term_enrollment) do
      FactoryBot.create(:hbx_enrollment,
                        family: family,
                        household: family.active_household,
                        coverage_kind: "health",
                        product: product,
                        terminated_on: effective_on - 2.day,
                        aasm_state: 'coverage_terminated',
                        hbx_enrollment_members: [subscriber_enrollment_member])
    end

    before do
      active_enrollment.cancel_coverage!
    end

    it "should return []" do
      expect(family.current_enrolled_or_termed_products(shopping_enrollment)).to eq []
    end
  end
end

describe ".current_enrolled_or_termed_coverages", dbclean: :after_each do
  let(:spec_date) { Date.new(TimeKeeper.date_of_record.year, 10, 5) }
  let(:new_coverage_effective_on) { spec_date.beginning_of_month }

  after :all do
    TimeKeeper.set_date_of_record_unprotected!(Date.today)
  end

  context 'when A and B enrolled effective 1/1 with enrollment_1' do
    let(:person_A) { FactoryBot.create(:person)}
    let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person_A)}
    let(:household) { FactoryBot.create(:household, family: family) }
    let(:enrollment_member_A) { FactoryBot.build(:hbx_enrollment_member, applicant_id: family.primary_applicant.id) }

    let(:person_B) { FactoryBot.create(:person)}
    let(:family_member_B) { FactoryBot.create(:family_member, family: family, person: person_B) }
    let(:enrollment_member_B) { FactoryBot.build(:hbx_enrollment_member, applicant_id: family_member_B.id) }

    let(:product) {FactoryBot.create(:benefit_markets_products_health_products_health_product, benefit_market_kind: :aca_individual, kind: :health, csr_variant_id: '01')}

    context 'when B termed with 9/30 and A continued coverage beyond 9/30 with enrollment_2' do
      let!(:enrollment_1) do
        FactoryBot.create(:hbx_enrollment,
                          family: family,
                          household: family.active_household,
                          effective_on: spec_date.beginning_of_year,
                          coverage_kind: "health",
                          kind: "individual",
                          product: product,
                          terminated_on: new_coverage_effective_on.prev_day,
                          aasm_state: 'coverage_terminated',
                          hbx_enrollment_members: [enrollment_member_A, enrollment_member_B])
      end

      let!(:enrollment_2) do
        FactoryBot.create(:hbx_enrollment,
                          family: family,
                          household: family.active_household,
                          effective_on: new_coverage_effective_on,
                          coverage_kind: "health",
                          kind: "individual",
                          product: product,
                          aasm_state: 'coverage_selected',
                          hbx_enrollment_members: [enrollment_member_A])
      end

      context 'when B tried to get enrolled using SEP on 10/1 with continuous coverage using enrollment_3' do
        let!(:enrollment_3) do
          FactoryBot.create(:hbx_enrollment,
                            family: family,
                            effective_on: new_coverage_effective_on,
                            household: family.active_household,
                            product: product,
                            coverage_kind: "health",
                            kind: "individual",
                            aasm_state: 'shopping',
                            hbx_enrollment_members: [enrollment_member_A, enrollment_member_B])
        end

        before do
          TimeKeeper.set_date_of_record_unprotected!(spec_date)
        end

        context 'when include_matching_effective_date is false' do
          it 'should return enrollment_1' do
            current_coverages = family.current_enrolled_or_termed_coverages(enrollment_3).to_a

            expect(current_coverages).to include(enrollment_1)
            expect(current_coverages).not_to include(enrollment_2)
            expect(current_coverages).not_to include(enrollment_3)
          end
        end

        context 'when include_matching_effective_date is true' do
          it 'should return enrollment_1 & enrollment_2' do
            current_coverages = family.current_enrolled_or_termed_coverages(enrollment_3, true).to_a

            expect(current_coverages).to include(enrollment_1)
            expect(current_coverages).to include(enrollment_2)
            expect(current_coverages).not_to include(enrollment_3)
          end
        end
      end
    end
  end
end

describe ".checkbook_enrollments", dbclean: :after_each do
  include_context "setup families enrollments"
  let!(:person) { FactoryBot.create(:person)}
  let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person)}
  let!(:household) { FactoryBot.create(:household, family: family) }
  let!(:product) do
    FactoryBot.create(:benefit_markets_products_health_products_health_product, :with_renewal_product,
                      benefit_market_kind: :aca_individual,
                      kind: :health,
                      csr_variant_id: '01',
                      service_area: service_area,
                      renewal_service_area: renewal_service_area)
  end
  let(:renewal_product) { product.renewal_product }
  let!(:effective_on) { TimeKeeper.date_of_record.beginning_of_month}
  let!(:subscriber_enrollment_member) { FactoryBot.build(:hbx_enrollment_member, applicant_id: family.primary_applicant.id) }

  let!(:active_enrollment) do
    FactoryBot.create(:hbx_enrollment,
                      family: family,
                      household: family.active_household,
                      coverage_kind: "health",
                      product: product,
                      aasm_state: 'coverage_selected',
                      hbx_enrollment_members: [subscriber_enrollment_member])
  end

  let!(:shopping_enrollment) do
    FactoryBot.create(:hbx_enrollment,
                      family: family,
                      effective_on: effective_on,
                      household: family.active_household,
                      coverage_kind: "health",
                      aasm_state: 'shopping',
                      hbx_enrollment_members: [subscriber_enrollment_member])
  end

  context "when consumer has has existing enrollment" do
    it 'should return renewal_enrollment' do
      current_coverages = family.checkbook_enrollments(shopping_enrollment)

      expect(current_coverages).to include(active_enrollment.product)
      expect(current_coverages).not_to include(shopping_enrollment)
    end
  end

  context "when consumer has has a renewal" do
    let!(:renewal_enrollment) do
      FactoryBot.create(:hbx_enrollment,
                        family: family,
                        effective_on: effective_on,
                        household: family.active_household,
                        product: renewal_product,
                        coverage_kind: "health",
                        aasm_state: 'auto_renewing',
                        hbx_enrollment_members: [subscriber_enrollment_member])
    end

    it 'should return renewal_enrollment' do
      current_coverages = family.checkbook_enrollments(shopping_enrollment)

      expect(current_coverages).to include(renewal_enrollment.product)
      expect(current_coverages).not_to include(shopping_enrollment)
    end
  end

  context "when consumer no contionus coverage" do
    let!(:term_enrollment) do
      FactoryBot.create(:hbx_enrollment,
                        family: family,
                        household: family.active_household,
                        coverage_kind: "health",
                        product: product,
                        terminated_on: effective_on - 2.day,
                        aasm_state: 'coverage_terminated',
                        hbx_enrollment_members: [subscriber_enrollment_member])
    end

    before do
      active_enrollment.cancel_coverage!
    end

    it "should return nil" do
      expect(family.checkbook_enrollments(shopping_enrollment)).to be_nil
    end
  end

  context "when consumer has terminated covage that ends after new enrollment effective date" do
    let!(:term_enrollment) do
      FactoryBot.create(:hbx_enrollment,
                        family: family,
                        household: family.active_household,
                        coverage_kind: "health",
                        product: product,
                        terminated_on: effective_on + 2.day,
                        aasm_state: 'coverage_terminated',
                        hbx_enrollment_members: [subscriber_enrollment_member])
    end

    it "should return the terminated enrollment" do
      current_coverages = family.checkbook_enrollments(shopping_enrollment)

      expect(current_coverages).to include(term_enrollment.product)
    end
  end

  context "when consumer has expired covage with an effective date greater than the beginning of the new enrollments effective on year" do
    let!(:expired_enrollment) do
      FactoryBot.create(:hbx_enrollment,
                        family: family,
                        household: family.active_household,
                        coverage_kind: "health",
                        product: product,
                        effective_on: shopping_enrollment.effective_on.beginning_of_year + 2.day,
                        aasm_state: 'coverage_expired',
                        hbx_enrollment_members: [subscriber_enrollment_member])
    end

    it "should return the expired enrollment" do
      current_coverages = family.checkbook_enrollments(shopping_enrollment)

      expect(current_coverages).to include(expired_enrollment.product)
    end
  end

  context "when consumer has expired covage with an effective date greater than the end of the new enrollments effective on year" do
    let!(:expired_enrollment) do
      FactoryBot.create(:hbx_enrollment,
                        family: family,
                        household: family.active_household,
                        coverage_kind: "health",
                        product: product,
                        effective_on: shopping_enrollment.effective_on.end_of_year + 2.day,
                        aasm_state: 'coverage_expired',
                        hbx_enrollment_members: [subscriber_enrollment_member])
    end

    before do
      active_enrollment.cancel_coverage!
    end

    it "should not return the expired enrollment" do
      current_coverages = family.checkbook_enrollments(shopping_enrollment)

      expect(current_coverages).to be_nil
    end
  end
end

describe ".current_coverage_expired_coverages", dbclean: :after_each do
  let(:spec_date) { Date.new(TimeKeeper.date_of_record.year - 1, 1, 1) }
  let(:new_coverage_effective_on) { spec_date.beginning_of_month }

  let(:current_year_date) { Date.new(TimeKeeper.date_of_record.year, 1, 1) }
  let(:current_coverage_effective_on) { current_year_date.beginning_of_month }


  after :all do
    TimeKeeper.set_date_of_record_unprotected!(Date.today)
  end

  context 'when A is enrolled effective 1/1 with enrollment_1' do
    let(:person_A) { FactoryBot.create(:person)}
    let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person_A)}
    let(:household) { FactoryBot.create(:household, family: family) }
    let(:enrollment_member_A) { FactoryBot.build(:hbx_enrollment_member, applicant_id: family.primary_applicant.id) }

    let(:product) {FactoryBot.create(:benefit_markets_products_health_products_health_product, benefit_market_kind: :aca_individual, kind: :health, csr_variant_id: '01')}

    context 'when A coverage expired enrollment & active enrollment' do
      let!(:enrollment_1) do
        FactoryBot.create(:hbx_enrollment,
                          family: family,
                          household: family.active_household,
                          effective_on: spec_date.beginning_of_year,
                          coverage_kind: "health",
                          kind: "individual",
                          product: product,
                          terminated_on: nil,
                          aasm_state: 'coverage_expired',
                          hbx_enrollment_members: [enrollment_member_A])
      end

      let!(:enrollment_2) do
        FactoryBot.create(:hbx_enrollment,
                          family: family,
                          household: family.active_household,
                          effective_on: current_coverage_effective_on,
                          coverage_kind: "health",
                          kind: "individual",
                          product: product,
                          aasm_state: 'coverage_selected',
                          hbx_enrollment_members: [enrollment_member_A])
      end

      context 'when A tried to get enrolled using SEP on 12/1 with continuous coverage using enrollment_2' do
        let!(:enrollment_3) do
          FactoryBot.create(:hbx_enrollment,
                            family: family,
                            effective_on: Date.new(TimeKeeper.date_of_record.year - 1,12, 1),
                            household: family.active_household,
                            product: product,
                            coverage_kind: "health",
                            kind: "individual",
                            aasm_state: 'shopping',
                            hbx_enrollment_members: [enrollment_member_A])
        end

        before do
          TimeKeeper.set_date_of_record_unprotected!(spec_date)
        end

        context 'when include_matching_effective_date is false' do
          it 'should return enrollment_1' do
            current_coverages = family.current_enrolled_or_termed_coverages(enrollment_3).to_a

            expect(current_coverages).to include(enrollment_1)
            expect(current_coverages).not_to include(enrollment_2)
            expect(current_coverages).not_to include(enrollment_3)
          end
        end
      end
    end
  end
end

