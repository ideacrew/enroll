# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Operations::Individual::ExtractPersonRecord, dbclean: :after_each do

 subject do
    described_class.new.call(enrollment_id: '620d1eea83d00d8892ad21c9')
  end

  describe "Not passing params to call the operation" do
    let(:params) { { } }

    it "fails" do
      expect(subject).not_to be_success
      expect(subject.failure).to eq "Given object is not a valid enrollment object"
    end
  end

  let(:user) { FactoryBot.create(:user, roles: ["hbx_staff"]) }
    let!(:person) { FactoryBot.create(:person)}
    let!(:family) { FactoryBot.create(:family, :with_primary_family_member_and_dependent, person: person)}
    let(:primary) { family.primary_family_member }
    let(:dependents) { family.dependents }
    let!(:household) { FactoryBot.create(:household, family: family) }
    let(:effective_on) {TimeKeeper.date_of_record.beginning_of_year - 1.year}
    let(:product) { FactoryBot.create(:benefit_markets_products_health_products_health_product, benefit_market_kind: :aca_individual, kind: :health, csr_variant_id: '01') }
    let(:hbx_en_member1) { FactoryBot.build(:hbx_enrollment_member,
                                              eligibility_date: effective_on,
                                              coverage_start_on: effective_on,
                                              applicant_id: dependents.first.id) }
    let(:hbx_en_member2) { FactoryBot.build(:hbx_enrollment_member,
                                          eligibility_date: effective_on + 2.months,
                                          coverage_start_on: effective_on + 2.months,
                                          applicant_id: dependents.first.id) }

    let!(:enrollment1) {
      FactoryBot.create(:hbx_enrollment,
                         family: family,
                         product: product,
                         household: family.active_household,
                         coverage_kind: "health",
                         effective_on: effective_on,
                         terminated_on: effective_on.next_month.end_of_month,
                         kind: 'individual',
                         hbx_enrollment_members: [hbx_en_member1],
                         aasm_state: 'coverage_terminated'
      )}
    let!(:enrollment2) {
      FactoryBot.create(:hbx_enrollment,
                         family: family,
                         product: product,
                         kind: 'individual',
                         household: family.active_household,
                         coverage_kind: "health",
                         hbx_enrollment_members: [hbx_en_member2],
                         effective_on: effective_on + 2.months,
                         terminated_on: (effective_on + 5.months).end_of_month,
                         aasm_state: 'coverage_terminated'
      )}

end
