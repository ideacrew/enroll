require 'rails_helper'
RSpec.describe 'exchanges/hbx_profiles/_edit_force_publish', :dbclean => :after_each do
  let!(:organization)     { FactoryGirl.create(:organization) }
  let!(:employer_profile) { FactoryGirl.create(:employer_profile, organization: organization) }
  let!(:benefit_groups)   { [FactoryGirl.build(:benefit_group, effective_on_kind: 'first_of_month')] }
  let!(:draft_plan_year)  { FactoryGirl.create(:future_plan_year, aasm_state: 'draft', employer_profile: employer_profile, benefit_groups: benefit_groups) }
  let!(:draft_plan_year2) { FactoryGirl.create(:future_plan_year, aasm_state: 'draft', employer_profile: employer_profile) }
  let!(:draft_plan_year3) { FactoryGirl.create(:future_plan_year, aasm_state: 'publish_pending', employer_profile: employer_profile, benefit_groups: benefit_groups) }
  let!(:draft_plan_year4) { FactoryGirl.create(:future_plan_year, aasm_state: 'renewing_publish_pending', employer_profile: employer_profile, benefit_groups: benefit_groups) }
  let(:user) { FactoryGirl.create(:user, person: person) }
  let(:person) do
    FactoryGirl.create(:person, :with_hbx_staff_role).tap do |person|
      FactoryGirl.create(:permission, :super_admin).tap do |permission|
        person.hbx_staff_role.update_attributes(permission_id: permission.id)
      end
    end
  end
  let(:params) { {row_actions_id: "family_actions_#{organization.id}.to_s"} }

  context 'plan year force published sucessfully' do
    before :each do
      assign :organization, organization
      assign :plan_year, draft_plan_year
      render partial: 'exchanges/hbx_profiles/force_publish.html.erb', locals: {params: params}
    end

    it 'Should match header text Publish Application' do
      expect(rendered).to match(/Force Publish Successful/)
    end
  end

  context 'plan year did not force published due to errors' do
    before :each do
      assign :organization, organization
      assign :plan_year, draft_plan_year2
      render partial: 'exchanges/hbx_profiles/force_publish.html.erb', locals: {params: params}
    end

    it 'Should match text Application Force Publish Failed' do
      expect(rendered).to match(/Application Force Publish Failed/)
    end
  end

  context 'force published for plan year with publish_pending ' do
    before :each do
      assign :organization, organization
      assign :plan_year, draft_plan_year3
      render partial: 'exchanges/hbx_profiles/force_publish.html.erb', locals: {params: params}
    end

    it 'Should match text Force Published Application Under Review' do
      expect(rendered).to match(/Force Published Application Under Review/)
    end
  end

  context 'force published for plan year with renewing publish pending' do
    before :each do
      assign :organization, organization
      assign :plan_year, draft_plan_year4
      render partial: 'exchanges/hbx_profiles/force_publish.html.erb', locals: {params: params}
    end

    it 'Should match text Force Published Application Under Review' do
      expect(rendered).to match(/Force Published Application Under Review/)
    end
  end

end
