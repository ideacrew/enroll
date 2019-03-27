require 'rails_helper'

RSpec.describe "_new_benefit_application.html.slim", :type => :view, dbclean: :after_each  do
  let!(:rating_area)                  { FactoryBot.create_default :benefit_markets_locations_rating_area }
  let!(:service_area)                 { FactoryBot.create_default :benefit_markets_locations_service_area }
  let!(:site)                          { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
  let!(:organization)                  { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
  let!(:employer_profile)              { organization.employer_profile }
  let(:benefit_sponsorship)           { bs = employer_profile.add_benefit_sponsorship
                                        bs.save!
                                        bs }
  let(:new_ba_params)                 { { "benefit_sponsorship_id"=>benefit_sponsorship.id.to_s, "admin_datatable_action"=>true } }

  before :each do
    form = ::BenefitSponsors::Forms::BenefitApplicationForm.for_new(new_ba_params)
    assign(:ba_form, form)
    render template: "exchanges/hbx_profiles/_new_benefit_application.html.slim"
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
