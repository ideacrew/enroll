# frozen_string_literal: true

require "rails_helper"

RSpec.describe 'insured/plan_shoppings/_individual_coverage_information.html.erb', dbclean: :after_each do
  context 'individual enrollment display_you_pay' do
    let!(:consumer_person) { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role) }
    let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: consumer_person) }
    let!(:health_pro) { FactoryBot.create(:benefit_markets_products_health_products_health_product, :silver, :with_issuer_profile) }
    let!(:enrollment) { FactoryBot.create(:hbx_enrollment, :individual_unassisted, family: family, household: family.active_household, product_id: health_pro.id) }
    let!(:enr_member) { FactoryBot.create(:hbx_enrollment_member, hbx_enrollment: enrollment, applicant_id: family.primary_applicant.id) }

    before do
      assign(:plan, UnassistedPlanCostDecorator.new(enrollment.product, enrollment))
      assign(:enrollment, enrollment)
      assign(:person, consumer_person)
      allow(view).to receive(:policy_helper).and_return(double('FamilyPolicy', updateable?: true))
      allow(view).to receive(:policy_helper).and_return(double("Policy", updateable?: true, can_access_progress?: true))
    end

    context 'display_you_pay feature disabled' do
      before { EnrollRegistry[:display_you_pay].feature.stub(:is_enabled).and_return(false) }

      it 'has data-cuke no_you_pay' do
        render :template => 'insured/plan_shoppings/thankyou.html.erb'
        expect(rendered).to match('no_you_pay')
      end
    end

    context 'display_you_pay feature enabled' do
      before { EnrollRegistry[:display_you_pay].feature.stub(:is_enabled).and_return(true) }

      it 'doesnot have data-cuke no_you_pay' do
        render :template => 'insured/plan_shoppings/thankyou.html.erb'
        expect(rendered).not_to match('no_you_pay')
      end
    end
  end
end
