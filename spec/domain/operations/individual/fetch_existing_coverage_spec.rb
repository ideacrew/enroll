# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Operations::Individual::FetchExistingCoverage do
  subject do
    described_class.new.call(params)
  end

  describe "Not passing params to call the operation" do
    let!(:person) { FactoryBot.create(:person)}
    let!(:family) { FactoryBot.create(:family, :with_primary_family_member_and_dependent, person: person)}
    let(:primary) { family.primary_family_member }
    let(:dependents) { family.dependents }
    let!(:household) { FactoryBot.create(:household, family: family) }
    let(:effective_on) {TimeKeeper.date_of_record.beginning_of_year - 1.year}
    let(:product) { FactoryBot.create(:benefit_markets_products_health_products_health_product, benefit_market_kind: :aca_individual, kind: :health, csr_variant_id: '01') }
    let(:product2) { FactoryBot.create(:benefit_markets_products_health_products_health_product, benefit_market_kind: :aca_individual, kind: :dental, csr_variant_id: '01') }

    let(:hbx_en_member1) do
      FactoryBot.build(:hbx_enrollment_member,
                       eligibility_date: effective_on,
                       coverage_start_on: effective_on,
                       applicant_id: dependents.first.id)
    end
    let(:hbx_en_member2) do
      FactoryBot.build(:hbx_enrollment_member,
                       eligibility_date: effective_on,
                       coverage_start_on: effective_on,
                       applicant_id: dependents.last.id)
    end
    let(:hbx_en_member3) do
      FactoryBot.build(:hbx_enrollment_member,
                       eligibility_date: effective_on + 6.months,
                       coverage_start_on: effective_on + 6.months,
                       applicant_id: dependents.last.id)
    end
    let!(:enrollment1) do
      FactoryBot.create(:hbx_enrollment,
                        family: family,
                        product: product,
                        household: family.active_household,
                        coverage_kind: "health",
                        effective_on: effective_on,
                        terminated_on: effective_on.next_month.end_of_month,
                        kind: 'individual',
                        hbx_enrollment_members: [hbx_en_member1, hbx_en_member2],
                        aasm_state: 'coverage_selected')
    end
    let!(:enrollment2) do
      FactoryBot.create(:hbx_enrollment,
                        family: family,
                        product: product,
                        kind: 'individual',
                        household: family.active_household,
                        coverage_kind: "health",
                        hbx_enrollment_members: [hbx_en_member2],
                        effective_on: effective_on + 2.months,
                        terminated_on: (effective_on + 5.months).end_of_month,
                        aasm_state: 'shopping')
    end
    let!(:enrollment3) do
      FactoryBot.create(:hbx_enrollment,
                        family: family,
                        product: product,
                        household: family.active_household,
                        coverage_kind: "health",
                        effective_on: effective_on + 6.months,
                        terminated_on: effective_on.end_of_year,
                        kind: 'individual',
                        hbx_enrollment_members: [hbx_en_member1, hbx_en_member2, hbx_en_member3],
                        aasm_state: 'coverage_selected')
    end
    let!(:enrollment4) do
      FactoryBot.create(:hbx_enrollment,
                        family: family,
                        product: product,
                        household: family.active_household,
                        coverage_kind: "health",
                        effective_on: effective_on + 6.months,
                        terminated_on: effective_on.end_of_year,
                        kind: 'employer_sponsored',
                        hbx_enrollment_members: [hbx_en_member1, hbx_en_member2],
                        aasm_state: 'coverage_selected')
    end

    let!(:enrollment5) do
      FactoryBot.create(:hbx_enrollment,
                        family: family,
                        product: product2,
                        household: family.active_household,
                        coverage_kind: "dental",
                        effective_on: effective_on,
                        terminated_on: effective_on.next_month.end_of_month,
                        kind: 'individual',
                        hbx_enrollment_members: [hbx_en_member1, hbx_en_member2],
                        aasm_state: 'coverage_selected')
    end
    let!(:enrollment6) do
      FactoryBot.create(:hbx_enrollment,
                        family: family,
                        product: product2,
                        kind: 'individual',
                        household: family.active_household,
                        coverage_kind: "dental",
                        hbx_enrollment_members: [hbx_en_member2],
                        effective_on: effective_on + 2.months,
                        terminated_on: (effective_on + 5.months).end_of_month,
                        aasm_state: 'shopping')
    end

    let(:params) do
      { :enrollment_id => enrollment2.id }
    end

    context "Not passing params to call the operation" do
      let(:params) { { } }

      it "fails" do
        expect(subject).not_to be_success
        expect(subject.failure).to eq "Given input is not a valid enrollment id"
      end
    end

    context "passing incorrect params to call the operation" do
      let(:params) { { :enrollment_id => 'abc123' } }

      it "fails" do
        expect(subject).not_to be_success
        expect(subject.failure).to eq "Given input is not a valid enrollment id"
      end
    end

    context "passing enrollment with no hbx enrollment members" do
      before :each do
        enrollment2.hbx_enrollment_members.destroy_all
        enrollment2.save!
      end

      it "returns failure" do
        expect(subject).not_to be_success
        expect(subject.failure).to eq "Enrollment does not include dependents"
      end
    end

    context "hbx enrollment members with shopping enrollment" do
      it "returns success" do
        expect(subject).to be_success
        expect(subject.success).to eq [enrollment1, enrollment3]
        # SHOP Enrollment not included
        expect(subject.success).not_to include [enrollment4]
      end
    end

    context "hbx enrollment members with dental shopping enrollment" do
      let(:params) { { :enrollment_id => enrollment6.id } }
      it "returns success" do
        expect(subject).to be_success
        expect(subject.success).to eq [enrollment5]
      end
    end
  end
end
