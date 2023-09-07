# frozen_string_literal: true

require "rails_helper"

RSpec.describe HbxEnrollment, "created in the shopping mode, then transitioned with a reason", dbclean: :after_each do
  let(:product) do
    FactoryBot.create(:benefit_markets_products_health_products_health_product, benefit_market_kind: :aca_individual, kind: :health)
  end

  let(:family) do
    FactoryBot.create(:individual_market_family)
  end

  let(:enrollment) do
    hbx_enrollment = HbxEnrollment.new(
      :aasm_state => "shopping",
      :kind => "individual",
      :enrollment_kind => "open_enrollment",
      :coverage_kind => "health",
      :family => family,
      :household => family.households.first,
      :product => product
    )
    hbx_enrollment.save!
    hbx_enrollment
  end

  it "can be found using the reason when coverage is canceled" do
    enrollment.select_coverage!({:reason => "because"})
    found_enrollment = HbxEnrollment.where(
      "workflow_state_transitions.metadata.reason" => "because"
    ).first
    expect(found_enrollment.id).to eq(enrollment.id)
  end

  it "can be found using the reason when coverage is canceled" do
    enrollment.select_coverage!
    enrollment.cancel_coverage!(Date.today, {:reason => "because"})
    found_enrollment = HbxEnrollment.where(
      "workflow_state_transitions.metadata.reason" => "because"
    ).first
    expect(found_enrollment.id).to eq(enrollment.id)
  end
end