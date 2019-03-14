require 'rails_helper'

 RSpec.describe "_new_benefit_application.html.slim", :type => :view, dbclean: :after_each  do
  let!(:organization)        { FactoryGirl.create(:organization)}
  let!(:employer_profile)    { FactoryGirl.create(:employer_profile, organization: organization) }
  let!(:plan_year)           { FactoryGirl.create(:plan_year, employer_profile: employer_profile) }
  let!(:benefit_group)       { FactoryGirl.create(:benefit_group, plan_year: plan_year)}
  let!(:params)   {
    {
      id: organization.id.to_s
    }
  }
   before :each do
    form = ::Forms::AdminPlanYearForm.for_new(params)
    assign(:ba_form, form)
    render template: "exchanges/hbx_profiles/_new_plan_year.html.slim"
  end

   context 'for texts' do
    it { expect(rendered).to have_text(/Effective Start Date/) }
    it { expect(rendered).to have_text(/Effective End Date/) }
    it { expect(rendered).to have_text(/Full Time Employees/) }
    it { expect(rendered).to have_text(/Open Enrollment Start Date/) }
    it { expect(rendered).to have_text(/Open Enrollment End Date/) }
    it { expect(rendered).not_to have_text(/Binder Payment Due Date/) }
  end

   context 'for ids' do
    it { expect(rendered).to have_css('#baStartDate') }
    it { expect(rendered).to have_css('#end_on') }
    it { expect(rendered).to have_css('#fteCount') }
    it { expect(rendered).to have_css('#open_enrollment_start_on') }
    it { expect(rendered).to have_css('#open_enrollment_end_on') }
    it { expect(rendered).not_to have_css('#binder_due_date') }
  end
end
