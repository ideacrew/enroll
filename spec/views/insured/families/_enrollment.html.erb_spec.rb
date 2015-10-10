require 'rails_helper'

RSpec.describe "insured/families/_enrollment.html.erb" do
  context "without consumer_role" do
    let(:plan) {FactoryGirl.build(:plan)}
    let(:hbx_enrollment) {double(plan: plan, id: "12345", total_premium: 200, kind: 'individual',
                                 covered_members_first_names: ["name"], can_complete_shopping?: false,
                                 may_terminate_coverage?: true, effective_on: Date.new(2015,8,10), consumer_role: nil, employee_role: nil, status_step: 2)}

    before :each do
      render partial: "insured/families/enrollment", collection: [hbx_enrollment], as: :hbx_enrollment
    end

    it "should display the title" do
      expect(rendered).to match /#{plan.active_year} health Coverage/
      expect(rendered).to match /DCHL/
    end

    it "should display the link of view detail" do
      expect(rendered).to have_selector("a[href='/products/plans/summary?active_year=#{plan.active_year}&hbx_enrollment_id=#{hbx_enrollment.id}&standard_component_id=#{plan.hios_id}']", text: "View Details")
    end

    it "should display the effective date" do
      expect(rendered).to have_selector('label', text: 'Effective date:')
      expect(rendered).to have_selector('strong', text: '08/10/2015')
    end
  end

  context "with consumer_role" do
    let(:plan) {FactoryGirl.build(:plan)}
    let(:hbx_enrollment) {double(plan: plan, id: "12345", total_premium: 200, kind: 'individual',
                                 covered_members_first_names: ["name"], can_complete_shopping?: false,
                                 may_terminate_coverage?: true, effective_on: Date.new(2015,8,10), consumer_role: double, applied_aptc_amount: 100, employee_role: nil, status_step: 2)}

    before :each do
      render partial: "insured/families/enrollment", collection: [hbx_enrollment], as: :hbx_enrollment
    end

    it "should display the title" do
      expect(rendered).to match /#{plan.active_year} health Coverage/
      expect(rendered).to match /DCHL/
    end

    it "should display the aptc amount" do
      expect(rendered).to have_selector('label', text: 'APTC amount:')
      expect(rendered).to have_selector('strong', text: '$100')
    end
  end
end
