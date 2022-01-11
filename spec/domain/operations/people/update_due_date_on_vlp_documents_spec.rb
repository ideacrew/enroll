# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Operations::People::UpdateDueDateOnVlpDocuments, dbclean: :after_each do

  let!(:person) { FactoryBot.create(:person, :with_consumer_role)}
  let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person)}
  let(:issuer) { FactoryBot.create(:benefit_sponsors_organizations_issuer_profile, abbrev: 'ANTHM') }
  let(:product) { FactoryBot.create(:benefit_markets_products_health_products_health_product, :ivl_product, issuer_profile: issuer) }
  let(:aasm_state) { 'coverage_selected' }
  let!(:enrollment) do
    FactoryBot.create(
      :hbx_enrollment,
      :with_enrollment_members,
      :individual_unassisted,
      family: family,
      aasm_state: aasm_state,
      product_id: product.id,
      applied_aptc_amount: Money.new(44_500),
      consumer_role_id: person.consumer_role.id,
      enrollment_members: family.family_members
    )
  end
  let(:due_date) { TimeKeeper.date_of_record + 95.days }


  describe 'when invalid params are passed in' do
    let(:valid_params) { { due_date: due_date, family: family } }
    let(:invalid_params) { { due_date: nil, family: nil } }

    it 'should throw an error' do
      result = subject.call(invalid_params)

      expect(result.success?).to be_falsey
      expect(result.failure).to eq(["due date missing", "family missing"])
    end
  end

  describe 'when valid params are passed in' do
    let(:valid_params) { { due_date: due_date, family: family } }

    before :each do
      allow(family).to receive(:contingent_enrolled_active_family_members).and_return(family.family_members)
      person.consumer_role.verification_types.each { |vt| vt.update_attributes(validation_status: 'outstanding', due_date: nil) }
    end

    it 'should update due date on outstanding verification types' do
      result = subject.call(valid_params)

      expect(result.success?).to be_truthy
      expect(person.reload.consumer_role.verification_types.all?{ |vt| vt.due_date == due_date }).to be_truthy
    end
  end
end
