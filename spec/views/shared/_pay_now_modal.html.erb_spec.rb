# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe "shared/_pay_now_modal.html.erb", dbclean: :after_each do

  after :all do
    DatabaseCleaner.clean
  end

  let(:family) { FactoryBot.create(:family, :with_primary_family_member)}
  let(:hbx_enrollment) do
    FactoryBot.create(:hbx_enrollment,
                      product: health_product,
                      enrollment_members: family.family_members,
                      household: family.active_household,
                      family: family)
  end
  let(:health_product) { FactoryBot.create(:benefit_markets_products_health_products_health_product, :with_issuer_profile_kaiser) }
  let(:generic_redirect_double) { double }
  let(:strict_tile_check_double) { double }
  let(:kaiser_permanente_pay_now_double) { double }
  let(:enrollment_tile_setting_double) { double }
  let(:plan_shopping_setting_double) { double }
  let(:generic_redirect_url) do
    carrier_legal_name = hbx_enrollment.product.issuer_profile.legal_name
    Insured::PlanShopping::PayNowHelper::LINK_URL[carrier_legal_name.to_s]
  end

  before do
    allow(EnrollRegistry).to receive(:feature_enabled?).and_call_original
    allow(EnrollRegistry).to receive(:feature_enabled?).with(:kaiser_permanente_pay_now).and_return(true)
    allow(EnrollRegistry).to receive(:[]).and_call_original
    allow(EnrollRegistry).to receive(:[]).with(:generic_redirect).and_return(generic_redirect_double)
    allow(generic_redirect_double).to receive(:setting).with(:strict_tile_check).and_return(strict_tile_check_double)
    allow(strict_tile_check_double).to receive(:item).and_return(true)
  end

  context 'when called from the enrollment tile dropdown' do
    context 'and the plan shopping setting is enabled' do
      before do
        allow(kaiser_permanente_pay_now_double).to receive(:setting).with(:plan_shopping).and_return(plan_shopping_setting_double)
        allow(plan_shopping_setting_double).to receive(:item).and_return(true)
      end

      context 'and the enrollment tile setting is disabled' do
        before do
          allow(EnrollRegistry).to receive(:[]).with(:kaiser_permanente_pay_now).and_return(kaiser_permanente_pay_now_double)
          allow(kaiser_permanente_pay_now_double).to receive(:setting).with(:enrollment_tile).and_return(enrollment_tile_setting_double)
          allow(enrollment_tile_setting_double).to receive(:item).and_return(false)
        end

        context 'and the generic redirect feature is enabled' do
          before do
            allow(EnrollRegistry).to receive(:feature_enabled?).with(:generic_redirect).and_return(true)
          end

          context 'and the strict tile check feature is disabled' do
            before do
              allow(strict_tile_check_double).to receive(:item).and_return(false)
            end

            it 'should render with a link to the generic redirect' do
              render template: "shared/_pay_now_modal.html.erb", locals: {hbx_enrollment: hbx_enrollment, source: 'Enrollment Tile'}
              expect(rendered).to match(generic_redirect_url)
            end
          end
        end
      end
    end
  end
end