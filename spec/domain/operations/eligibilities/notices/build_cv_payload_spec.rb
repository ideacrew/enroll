# frozen_string_literal: true

require 'rails_helper'
RSpec.describe ::Operations::Eligibilities::Notices::BuildCvPayload,
               type: :model,
               dbclean: :after_each do
  it 'should be a container-ready operation' do
    expect(subject.respond_to?(:call)).to be_truthy
  end

  describe 'build familuy cv payload' do
    let(:person) { create(:person, :with_consumer_role) }
    let(:family) do
      create(:family, :with_primary_family_member, person: person)
    end
    let(:issuer) do
      create(:benefit_sponsors_organizations_issuer_profile, abbrev: 'ANTHM')
    end
    let(:product) do
      create(
        :benefit_markets_products_health_products_health_product,
        :ivl_product,
        issuer_profile: issuer
      )
    end
    let(:enrollment) do
      create(
        :hbx_enrollment,
        :with_enrollment_members,
        :individual_unassisted,
        family: family,
        product_id: product.id,
        applied_aptc_amount: Money.new(44_500),
        consumer_role_id: person.consumer_role.id,
        enrollment_members: family.family_members
      )
    end

    context 'with invalid params' do
      let(:params) { {} }

      it 'should return failure' do
        result = subject.call(params)
        expect(result.failure?).to be_truthy
        expect(result.failure).to include 'family missing'
      end
    end

    context 'with valid params' do
      before :each do
        person.consumer_role.verification_types.each do |vt|
          vt.update_attributes(
            validation_status: 'outstanding',
            due_date: TimeKeeper.date_of_record - 1.day
          )
        end
      end

      let(:params) { { family: family } }

      it 'should return success' do
        result = subject.call(params)
        expect(result.success?).to be_truthy
      end
    end
  end
end
