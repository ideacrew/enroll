# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe "shared/_pay_now_modal.html.erb", dbclean: :after_each do
  include Insured::PlanShopping::PayNowHelper

  after :all do
    DatabaseCleaner.clean
  end

  let(:family) { FactoryBot.create(:family, :with_primary_family_member)}
  let(:hbx_enrollment) do
    enrollment = FactoryBot.create(:hbx_enrollment,
                                   product: health_product,
                                   enrollment_members: family.family_members,
                                   household: family.active_household,
                                   family: family)
    enrollment.workflow_state_transitions << WorkflowStateTransition.new(
      from_state: :shopping,
      to_state: :coverage_selected,
      event: :select_coverage
    )
    enrollment
  end
  let(:health_product) { FactoryBot.create(:benefit_markets_products_health_products_health_product, :with_issuer_profile_kaiser) }
  let(:generic_redirect_double) { double }
  let(:strict_tile_check_double) { double }
  let(:kaiser_permanente_pay_now_double) { double }
  let(:enrollment_tile_setting_double) { double }
  let(:plan_shopping_setting_double) { double }
  let(:pay_now_portal_url) { pay_now_url(carrier_legal_name) }
  let(:generic_redirect_url) { Insured::PlanShopping::PayNowHelper::LINK_URL[carrier_legal_name.to_s] }
  let(:carrier_legal_name) { hbx_enrollment.product.issuer_profile.legal_name }

  before do
    allow(EnrollRegistry).to receive(:feature_enabled?).and_call_original
    allow(EnrollRegistry).to receive(:feature_enabled?).with(:kaiser_permanente_pay_now).and_return(true)
    allow(EnrollRegistry).to receive(:[]).and_call_original
    allow(EnrollRegistry).to receive(:[]).with(:generic_redirect).and_return(generic_redirect_double)
    allow(generic_redirect_double).to receive(:setting).with(:strict_tile_check).and_return(strict_tile_check_double)
    allow(strict_tile_check_double).to receive(:item).and_return(true)
    allow(kaiser_permanente_pay_now_double).to receive(:setting).with(:plan_shopping).and_return(plan_shopping_setting_double)
    allow(plan_shopping_setting_double).to receive(:item).and_return(true)
    allow(EnrollRegistry).to receive(:[]).with(:kaiser_permanente_pay_now).and_return(kaiser_permanente_pay_now_double)
    allow(kaiser_permanente_pay_now_double).to receive(:setting).with(:enrollment_tile).and_return(enrollment_tile_setting_double)
    allow(enrollment_tile_setting_double).to receive(:item).and_return(true)
  end

  context 'when called from the plan shopping flow' do
    let(:pay_now_partial_options) do
      { template: "shared/_pay_now_modal.html.erb", locals: {hbx_enrollment: hbx_enrollment, source: 'Plan Shopping'} }
    end

    context 'and the plan shopping setting is enabled' do
      it 'should render with a link to the pay now portal' do
        render pay_now_partial_options
        expect(rendered).to match(pay_now_portal_url)
      end

      it 'should render three bullet points' do
        render pay_now_partial_options
        expect(rendered.scan(/<li>/).count).to eq(3)
      end

      context 'and the enrollment effective date is in the past' do

        it 'should not include the link info text' do
          render pay_now_partial_options
          expect(rendered).not_to match(l10n("plans.issuer.pay_now.link_info"))
        end

        it 'should include the processing text' do
          render pay_now_partial_options
          expect(rendered).to match(l10n("plans.issuer.pay_now.processing", carrier_name: carrier_legal_name))
        end
      end

      context 'and the enrollment effective date is in the future' do
        before do
          hbx_enrollment.update(effective_on: Date.today + 1.month)

        end

        it 'should include the link info text' do
          render pay_now_partial_options
          expect(rendered).to match(l10n("plans.issuer.pay_now.link_info"))
        end

        it 'should not include the processing text' do
          render pay_now_partial_options
          expect(rendered).not_to match(l10n("plans.issuer.pay_now.processing", carrier_name: carrier_legal_name))
        end
      end
    end
  end

  context 'when called from the enrollment tile dropdown' do
    let(:pay_now_partial_options) do
      { template: "shared/_pay_now_modal.html.erb", locals: {hbx_enrollment: hbx_enrollment, source: 'Enrollment Tile'} }
    end

    context 'and the plan shopping setting is enabled' do
      context 'and the enrollment tile setting is disabled' do
        before do
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
              render pay_now_partial_options
              expect(rendered).to match(generic_redirect_url)
            end

            context 'and the enrollment effective date is in the past' do

              it 'should render three bullet points' do
                render pay_now_partial_options
                expect(rendered.scan(/<li>/).count).to eq(3)
              end

              it 'should not include the link info text' do
                render pay_now_partial_options
                expect(rendered).not_to match(l10n("plans.issuer.pay_now.link_info"))
              end

              it 'should include the processing text' do
                render pay_now_partial_options
                expect(rendered).to match(l10n("plans.issuer.pay_now.processing", carrier_name: carrier_legal_name))
              end
            end

            context 'and the enrollment effective date is in the future' do
              before do
                hbx_enrollment.update(effective_on: Date.today + 1.month)
              end

              it 'should only render two bullet points' do
                render pay_now_partial_options
                expect(rendered.scan(/<li>/).count).to eq(2)
              end

              it 'should not include the link info text' do
                render pay_now_partial_options
                expect(rendered).not_to match(l10n("plans.issuer.pay_now.link_info"))
              end

              it 'should not include the processing text' do
                render pay_now_partial_options
                expect(rendered).not_to match(l10n("plans.issuer.pay_now.processing", carrier_name: carrier_legal_name))
              end
            end
          end
        end
      end
    end
  end
end