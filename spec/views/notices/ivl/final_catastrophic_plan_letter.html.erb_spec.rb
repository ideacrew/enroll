# frozen_string_literal: true

require 'rails_helper'
if ExchangeTestingConfigurationHelper.individual_market_is_enabled?
  RSpec.describe 'notices/ivl/final_catastrophic_plan_letter.html.erb' do
    include Config::SiteHelper
    include Config::AcaHelper

    let!(:person) { FactoryBot.create(:person, :with_consumer_role, :with_mailing_address) }
    let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
    let(:application_event) do
      double('ApplicationEventKind', { name: 'Final Catastrophic Plan Notice',
                                       notice_template: 'notices/ivl/final_catastrophic_plan_letter',
                                       notice_builder: 'IvlNotices::FinalCatastrophicPlanNotice',
                                       event_name: 'final_catastrophic_plan',
                                       mpi_indicator: 'IVL_CAP',
                                       title: 'Important Tax Information about your Catastrophic Health Coverage' })
    end
    let(:valid_params) do
      { subject: application_event.title,
        mpi_indicator: application_event.mpi_indicator,
        event_name: application_event.event_name,
        template: application_event.notice_template }
    end
    let!(:notice) { catastrophic_plan_notice.notice }
    let!(:catastrophic_plan_notice) { IvlNotices::FinalCatastrophicPlanNotice.new(person.consumer_role, valid_params) }
    let(:previous_year) { TimeKeeper.date_of_record.year - 1 }
    let(:local_data) { {notice: notice} }

    before :each do
      catastrophic_plan_notice.append_hbe
      catastrophic_plan_notice.build
      render template: 'notices/ivl/final_catastrophic_plan_letter', locals: local_data
    end

    context 'for matching text' do
      it { expect(rendered).to have_selector('h3', text: l10n("notices.ivl_cap.title")) }
      it { expect(rendered).to match(/#{l10n("notices.shared.dear_person", first_name: notice.primary_firstname)}/) }
      it { expect(rendered).to match(/#{l10n("notices.ivl_cap.you_are_receiving_this_letter", site_short_name: site_short_name, previous_year: previous_year)}/) }
      it { expect(rendered).to match(/#{l10n("notices.ivl_cap.federal_law_required", aca_state_name: aca_state_name, ivl_responsibility_url: EnrollRegistry[:enroll_app].setting(:ivl_responsibility_url).item)}/) }
      it { expect(rendered).to match(/#{EnrollRegistry[:enroll_app].setting(:ivl_responsibility_url).item}/) }
      it { expect(rendered).to match(/(#{l10n("notices.ivl_cap.you_may_receive_a_tax_form")})*/) }
      it { expect(rendered).to match(/#{l10n("notices.shared.questions_or_concerns")}/) }
      it { expect(rendered).to match(/#{l10n("notices.shared.the_site_short_name_team", site_short_name: site_short_name)}/) }
    end

    context 'for partials' do
      it { render partial: 'notices/shared/cover_page', locals: local_data }
      it { render partial: 'notices/shared/logo_and_address_shop', locals: local_data }
      it { render partial: 'notices/shared/date', locals: local_data }
      it { render partial: 'notices/shared/address', locals: local_data }
      it { render partial: 'notices/shared/paragraph', locals: {content: "The #{site_short_name} Team"} }
      it { render partial: 'notices/shared/reference_paragraph', locals: {contents: ['']} }
    end
  end
end
