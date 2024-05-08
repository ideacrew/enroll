# frozen_string_literal: true

require "rails_helper"
# rubocop:disable Style/MixinUsage
include ActionView::Context
# rubocop:enable Style/MixinUsage

RSpec.describe "notices/ivl/ivl_tax_notice.html.erb" do

  let(:true_or_false) { true }
  let!(:person) { FactoryBot.create(:person, :with_consumer_role, :with_mailing_address)}
  let!(:family) {FactoryBot.create(:family, :with_primary_family_member, person: person)}
  let(:application_event) do
    double("ApplicationEventKind", { name: '1095A Tax Cover Letter Notice',
                                     notice_template: 'notices/ivl/ivl_tax_notice',
                                     notice_builder: 'IvlNotices::IvlTaxNotice',
                                     event_name: 'ivl_tax_cover_letter_notice',
                                     options: { is_an_aqhp_hbx_enrollment: true},
                                     mpi_indicator: 'IVL_TAX',
                                     title: "Your 1095-A Health Coverage Tax Form"})
  end

  let(:valid_params) do
    {
      subject: application_event.title,
      mpi_indicator: application_event.mpi_indicator,
      event_name: application_event.event_name,
      options: { is_an_aqhp_hbx_enrollment: true_or_false},
      template: application_event.notice_template
    }
  end

  let!(:notice) { catastrophic_plan_notice.notice }
  let!(:catastrophic_plan_notice) { IvlNotices::IvlTaxNotice.new(person.consumer_role, valid_params) }

  before :each do
    catastrophic_plan_notice.append_hbe
    catastrophic_plan_notice.build
    render template: "notices/ivl/ivl_tax_notice", locals: {notice: notice}
  end

  context 'template text for both assisted and unassisted' do
    it { expect(rendered).to have_selector('h3', text: 'YOUR 1095-A HEALTH COVERAGE TAX FORM') }
    it { expect(rendered).not_to match(/Dear #{person.full_name}:/) }
    it { expect(rendered).to match(/This letter includes your tax Form 1095-A. You’re receiving this tax form because you or someone/) }
    it { expect(rendered).to match(/If you have questions or concerns, we’re here to help./) }
    it { expect(rendered).to match(/The #{EnrollRegistry[:enroll_app].setting(:short_name).item} Team/) }
    it { expect(rendered).to match(/#{EnrollRegistry[:enroll_app].setting(:ivl_responsibility_url).item}/) }
    it { expect(rendered).to match(/Federal law required most Americans to have a minimum level of health coverage or pay a tax penalty through 2018./) }
    it { expect(rendered).not_to match(/#{EnrollRegistry[:enroll_app].setting(:short_name).item} does not control the individual mandate/) }
  end

  context 'template text for assisted only' do
    it { expect(rendered).to match(/You must fill out Form 8962 because you received an advance premium tax credit for #{previous_year}./) }
    it { expect(rendered).to match(/Since you received an advance premium tax credit, your Form 1095-A also shows how much of your tax credit was applied to your premium each month./) }
    it {
      # rubocop:disable Layout/LineLength
      expect(rendered).to match("The IRS requires you to use Form 8962 to report the amount of advance premium tax credit you received in #{previous_year}. You can download Form 8962 directly from the IRS website at <a href=\"#{EnrollRegistry[:enroll_app].setting(:irs_url).item}\">IRS.gov</a>.")
      # rubocop:enable Layout/LineLength
    }
    it { expect(rendered).to match("The back of your Form 1095-A has instructions on how to fill out Form 8962. You must fill out Form 8962 because you received an advance premium tax credit for #{previous_year}.") }
  end

  context 'template text for unassisted only' do
    let(:true_or_false) { false }

    it {
      # rubocop:disable Layout/LineLength
      expect(rendered).to match(/includes information about the primary recipient. Your spouse’s information is not listed because you didn’t receive an advance premium tax credit, and the IRS tells us not to include their information here. Part I also lists when your health insurance started and ended./)
      # rubocop:enable Layout/LineLength
    }
    it {
      # rubocop:disable Layout/LineLength
      expect(rendered).to match("You’ll use the information on your Form 1095-A to show that you or someone in your household had health insurance in #{previous_year}. If you want to see if you qualify for a premium tax credit, you’ll need the information on your Form 1095-A to complete the IRS Premium Tax Credit Form 8962.  You can download Form 8962 directly from the IRS website at <a href=\"#{EnrollRegistry[:enroll_app].setting(:irs_url).item}\">IRS.gov</a>.")
      # rubocop:enable Layout/LineLength
    }
  end

  context 'for rendering partials' do
    it { render partial: 'notices/shared/cover_page', locals: {notice: notice} }
    it { render partial: 'notices/shared/logo_and_address_shop', locals: {notice: notice} }
    it { render partial: "notices/shared/date", locals: {notice: notice} }
    it { render partial: "notices/shared/address", locals: {notice: notice} }
    it { render partial: 'notices/shared/paragraph', locals: {content: "The #{EnrollRegistry[:enroll_app].setting(:short_name).item} Team"} }
    it { render partial: 'notices/shared/reference_paragraph', locals: {contents: ['']} }
    it { render partial: 'notices/shared/unordered_list', locals: { previous: "You may receive more than one Form 1095-A if you:", listings: ['Also had a plan from ', 'Changed from one plan', 'Had family members']} }
    it { render partial: 'notices/shared/paragraph_with_headers', locals: { contents: [''], heading: 'Understanding Form 1095-A', sub_heading: ''} }
    it { render partial: 'notices/shared/paragraph_with_headers_for_ivl', locals: { contents: ["The information on"], heading: 'If You Think We Made a Mistake', sub_heading: '', top_margin: '12px'} }
  end
end
