# frozen_string_literal: true

require 'rails_helper'
if ExchangeTestingConfigurationHelper.individual_market_is_enabled?
  RSpec.describe 'notices/ivl/final_catastrophic_plan_letter.html.erb' do
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
      render file: 'notices/ivl/final_catastrophic_plan_letter', locals: local_data
    end

    context 'for matching text' do
      it { expect(rendered).to have_selector('h3', text: 'TAX INFORMATION FOR YOUR CATASTROPHIC HEALTH PLAN') }
      it { expect(rendered).to match(/Federal law required most Americans to have a minimum level of health coverage or pay a tax penalty through 2018./) }
      it { expect(rendered).to match(/Dear #{person.first_name}:/) }
      it { expect(rendered).to match(/You are receiving this letter because you were enrolled in a catastrophic health plan through #{EnrollRegistry[:enroll_app].setting(:short_name).item} in #{previous_year}./) }
      it { expect(rendered).to match(/You may receive a tax form from your health insurance company./) }
      it { expect(rendered).to match(/If you have questions or concerns, we’re here to help./) }
      it { expect(rendered).to match(/The #{EnrollRegistry[:enroll_app].setting(:short_name).item} Team/) }
    end

    context 'for partials' do
      it { render partial: 'notices/shared/cover_page', locals: local_data }
      it { render partial: 'notices/shared/logo_and_address_shop', locals: local_data }
      it { render partial: 'notices/shared/date', locals: local_data }
      it { render partial: 'notices/shared/address', locals: local_data }
      it { render partial: 'notices/shared/paragraph', locals: {content: "The #{EnrollRegistry[:enroll_app].setting(:short_name).item} Team"} }
      it { render partial: 'notices/shared/reference_paragraph', locals: {contents: ['']} }
    end
  end
end
