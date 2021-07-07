# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Operations::Notices::IvlEnrNoticeTrigger, dbclean: :after_each do

  it 'should be a container-ready operation' do
    expect(subject.respond_to?(:call)).to be_truthy
  end

  describe 'ivl enrollment notice trigger' do
    let(:person) { FactoryBot.create(:person, :with_consumer_role)}
    let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person)}
    let(:issuer) { FactoryBot.create(:benefit_sponsors_organizations_issuer_profile, abbrev: 'ANTHM') }
    let(:product) { FactoryBot.create(:benefit_markets_products_health_products_health_product, :ivl_product, issuer_profile: issuer) }
    let(:enrollment) do
      FactoryBot.create(:hbx_enrollment, :with_enrollment_members, :individual_unassisted, family: family, product_id: product.id, consumer_role_id: person.consumer_role.id)
    end

    context 'with invalid params' do
      let(:params) {{}}

      it 'should return failure' do
        result = subject.call(params)
        expect(result.failure?).to eq true
        expect(result.failure).to eq 'Missing Enrollment'
      end
    end

    context 'with valid params' do
      before :each do
        allow_any_instance_of(Events::Individual::Enrollments::Submitted).to receive(:publish).and_return true
      end

      let(:params) {{enrollment: enrollment}}

      it 'should return success' do
        result = subject.call(params)
        expect(result.success?).to eq true
      end
    end
  end
end
