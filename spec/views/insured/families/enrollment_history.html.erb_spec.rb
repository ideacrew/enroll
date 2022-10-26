# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "insured/families/enrollment_history.html.erb" do
  let(:person) { FactoryBot.create(:person, :with_family) }
  let(:person_hbx) { FactoryBot.create(:person, :with_hbx_staff_role, :with_family) }
  let(:family) { FactoryBot.create(:family, :with_primary_family_member) }
  let(:user_with_hbx_staff_role) { FactoryBot.create(:user, :with_family, :with_hbx_staff_role) }
  let(:user_with_consumer_role) { FactoryBot.create(:user, :with_family, :with_consumer_role) }
  let(:hbx_enrollment) { FactoryBot.create(:hbx_enrollment, family: family) }
  let(:canceled_hbx_enrollment) { FactoryBot.create(:hbx_enrollment, family: family, aasm_state: 'coverage_canceled') }

  before :each do
    stub_template "insured/families/_enrollment.html.erb" => ''
    assign(:person, person)
  end

  context 'user is HBX admin' do
    before do
      allow(view).to receive(:current_user).and_return(user_with_hbx_staff_role)
      allow(view).to receive(:policy_helper).and_return(
        double("FamilyPolicy", can_view_entire_family_enrollment_history?: true)
      )
    end

    context 'user has enrollments' do
      before do
        assign(:all_hbx_enrollments_for_admin, [hbx_enrollment, canceled_hbx_enrollment])
      end

      it "should display select box to show all enrollments" do
        render
        expect(rendered).to match(/display-all-enrollments-qs/)
      end
    end

    context 'user DOES NOT have enrollments' do
      before do
        assign(:all_hbx_enrollments_for_admin, [])
      end

      it "should NOT display select box to show all enrollments" do
        render
        expect(rendered).to_not match(/display-all-enrollments-qs/)
      end
    end
  end

  context 'user is NOT HBX admin' do
    before do
      allow(view).to receive(:current_user).and_return(user_with_consumer_role)
      assign(:hbx_enrollments, [hbx_enrollment])
      allow(view).to receive(:policy_helper).and_return(
        double("FamilyPolicy", can_view_entire_family_enrollment_history?: nil)
      )
    end

    it "should NOT display select box to show all enrollments" do
      render
      expect(rendered).to_not match(/display-all-enrollments-qs/)
    end
  end
end
